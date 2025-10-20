// lib/levels/level1.dart
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame/collisions.dart';
import '../component/ground.dart';
import '../component/bird.dart';
import '../component/pig.dart';
import '../component/obstacle.dart';
import '../component/slingshot.dart';
import '../component/trajectory_helper.dart';
import 'level_manager.dart';
import '../component/game.dart';

class Level1 extends Component with HasGameRef<MyPhysicsGame> {
  static const bool DEBUG_LINE = true;
  static const double groundTopRatio = 0.28;

  late final Slingshot slingshot;
  TrajectoryLine? trajectory;
  Vector2? lastPull;
  late double groundY;

  // Gameplay state
  final int maxShots = 3;
  int currentShot = 0;
  Bird? activeBird;
  bool birdInFlight = false;
  int score = 0;
  int remainingPigs = 1;
  double timeLeft = 60.0; // 60-second timer

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final rect = gameRef.camera.visibleWorldRect;

    // Background
    final bg = await gameRef.images.load('background.jpg');
    add(SpriteComponent(
      sprite: Sprite(bg),
      size: Vector2(rect.width, rect.height),
      position: Vector2(rect.left, rect.top),
      anchor: Anchor.topLeft,
    ));

    // Ground
    groundY = rect.bottom - rect.height * groundTopRatio;
    await gameRef.world.add(Ground(rect, y: groundY));

    if (DEBUG_LINE) {
      add(RectangleComponent()
        ..size = Vector2(rect.width, 0.06)
        ..position = Vector2(rect.left, groundY)
        ..anchor = Anchor.topLeft
        ..paint = (ui.Paint()..color = const ui.Color(0x80FF0000)));
    }

    // Slingshot
    final Vector2 slingPivot = Vector2(rect.left + 12, groundY - 3.5);
    slingshot = Slingshot(
      slingPivot,
      startDetectRadius: 6.0,
      trigger: TriggerTarget.both,
      powerK: 2.8,
      maxPull: 6.0,
      maxAngleDeg: 75,
    );
    await gameRef.world.add(slingshot);

    // Bird
    await _loadNextBird();

    // Pig
    final pigSprite = Sprite(await gameRef.images.load('target-small.png'));
    await gameRef.world.add(
      Pig(Vector2(rect.right - 12, groundY - 2.4), pigSprite, radius: 2.4),
    );

    // Obstacles
    final baseX = rect.right - 18;
    final baseY = groundY;
    await gameRef.world.addAll([
      Obstacle(
        initialPosition: Vector2(baseX - 2.5, baseY - 1.5),
        halfSize: Vector2(1.5, 1.5),
        kind: ObstacleKind.wood,
      ),
      Obstacle(
        initialPosition: Vector2(baseX + 2.5, baseY - 1.5),
        halfSize: Vector2(1.5, 1.5),
        kind: ObstacleKind.wood,
      ),
      Obstacle(
        initialPosition: Vector2(baseX, baseY - 4.0),
        halfSize: Vector2(4.0, 0.6),
        initialAngle: 0.04,
        kind: ObstacleKind.wood,
      ),
    ]);

    // Invisible walls
    final wallRect = gameRef.camera.visibleWorldRect;
    final walls = [
      EdgeShape()
        ..set(Vector2(wallRect.left, wallRect.top),
            Vector2(wallRect.left, wallRect.bottom)),
      EdgeShape()
        ..set(Vector2(wallRect.right, wallRect.top),
            Vector2(wallRect.right, wallRect.bottom)),
    ];

    for (final shape in walls) {
      final wallBodyDef = BodyDef()..type = BodyType.static;
      final wallBody = gameRef.world.createBody(wallBodyDef);
      wallBody.createFixtureFromShape(shape);
    }
  }

  // ===============================
  //      Player input (Slingshot)
  // ===============================

  void handlePointerDown(Vector2 p) {
    if (birdInFlight || gameRef.isGamePaused) return; //
    slingshot.beginDrag(p);
  }

  void handleDragMove(Vector2 p) {
    if (birdInFlight || gameRef.isGamePaused) return; //
    slingshot.dragMove(p);

    final pull = p - slingshot.pivot;
    lastPull = pull;

    final velocity = (-pull) * slingshot.powerK;

    trajectory?.removeFromParent();
    trajectory = TrajectoryLine(start: slingshot.pivot, velocity: velocity);
    add(trajectory!);
  }

  void handleDragEnd() {
    if (birdInFlight || gameRef.isGamePaused) return; //
    slingshot.endDrag();
    trajectory?.removeFromParent();
    trajectory = null;
    lastPull = null;
    birdInFlight = true;
  }

  // ===============================
  //      Bird management
  // ===============================

  Future<void> _loadNextBird() async {
    if (currentShot >= maxShots) return;

    final birdSprite = Sprite(await gameRef.images.load('ball_red_small.png'));
    const double r = 2.4;
    final bird = Bird(birdSprite, radius: r, start: slingshot.pivot);
    await gameRef.world.add(bird);
    await bird.loaded;

    slingshot.load(bird);
    activeBird = bird;
    birdInFlight = false;
    currentShot++;
  }

  // ===============================
  //      Update loop
  // ===============================

  @override
  void update(double dt) {
    super.update(dt);
    if (gameRef.isGamePaused) return;

    // Countdown timer
    if (timeLeft > 0) {
      timeLeft -= dt;
    } else {
      timeLeft = 0;
      _checkFailCondition();
    }

    // Bird tracking
    if (activeBird == null) return;
    final pos = activeBird!.body.position;

    if (birdInFlight) {
      final outOfBounds = pos.x > gameRef.camera.visibleWorldRect.right + 10 ||
          pos.y > gameRef.camera.visibleWorldRect.bottom + 10;
      final stopped = activeBird!.body.linearVelocity.length < 0.2;

      if (outOfBounds || stopped) {
        activeBird!.removeFromParent();
        activeBird = null;
        birdInFlight = false;
        _loadNextBird();
        _checkFailCondition();
      }
    }
  }

  // ===============================
  //      Scoring system
  // ===============================

  void addScore(int value) {
    score += value;
  }

  void onPigDied() {
    remainingPigs--;
    if (remainingPigs <= 0) {
      final manager = gameRef.levelManager;
      if (manager != null) {
        final bonus = (timeLeft * 10).round();
        final total = score + bonus;
        manager.showLevelCompletedWithScore(score, bonus, total);
      }
    }
  }

  // ===============================
  //      Fail condition
  // ===============================

  void _checkFailCondition() {
    if (remainingPigs > 0 &&
        (timeLeft <= 0 ||
            (currentShot >= maxShots &&
                birdInFlight == false &&
                remainingPigs > 0))) {
      gameRef.levelManager?.showLevelFailed();
    }
  }
}
