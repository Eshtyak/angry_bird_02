import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../component/ground.dart';
import '../component/bird.dart';
import '../component/pig.dart';
import '../component/obstacle.dart';
import '../component/slingshot.dart';
import '../component/trajectory_helper.dart';
import 'level_manager.dart';
import '../component/game.dart';

class Level2 extends Component with HasGameRef<MyPhysicsGame> {
  static const bool DEBUG_LINE = true;
  static const double groundTopRatio = 0.28;

  late final Slingshot slingshot;
  TrajectoryLine? trajectory;
  Vector2? lastPull;
  late double groundY;

  // Gameplay state
  final int maxShots = 3;
  int currentShot = 0;
  int pigsAlive = 0;
  int score = 0;

  Bird? activeBird;
  bool birdInFlight = false;
  bool levelCompleted = false;
  double timeLeft = 60.0;

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

    // Pigs (raised slightly above the ground)
    final pigSprite = Sprite(await gameRef.images.load('JellyPig.png'));
    final pigs = [
      Pig(Vector2(rect.right - 20, groundY - 3.5), pigSprite, radius: 2.4),
      Pig(Vector2(rect.right - 15, groundY - 9.5), pigSprite, radius: 2.4),
      Pig(Vector2(rect.right - 17, groundY - 15.5), pigSprite, radius: 2.4),
    ];
    pigsAlive = pigs.length;
    await gameRef.world.addAll(pigs);

    // ✅ Delay to let the ground settle
    await Future.delayed(const Duration(milliseconds: 200));

    // Tower structure (non-overlapping, stable layout)
    final baseX = rect.right - 17;
    final baseY = groundY;
    await gameRef.world.addAll([
      // Bottom blocks
      Obstacle(
        initialPosition: Vector2(baseX - 4, baseY - 2.0),
        halfSize: Vector2(1.5, 1.5),
        kind: ObstacleKind.wood,
      ),
      Obstacle(
        initialPosition: Vector2(baseX + 4, baseY - 2.0),
        halfSize: Vector2(1.5, 1.5),
        kind: ObstacleKind.wood,
      ),
      // First platform
      Obstacle(
        initialPosition: Vector2(baseX, baseY - 3.8),
        halfSize: Vector2(5.0, 0.6),
        kind: ObstacleKind.wood,
      ),
      // Middle barrels
      Obstacle(
        initialPosition: Vector2(baseX - 3, baseY - 6.0),
        halfSize: Vector2(1.2, 2.0),
        kind: ObstacleKind.barrel,
      ),
      Obstacle(
        initialPosition: Vector2(baseX + 3, baseY - 6.0),
        halfSize: Vector2(1.2, 2.0),
        kind: ObstacleKind.barrel,
      ),
      // Second platform
      Obstacle(
        initialPosition: Vector2(baseX, baseY - 8.3),
        halfSize: Vector2(4.5, 0.6),
        kind: ObstacleKind.wood,
      ),
      // Top supports
      Obstacle(
        initialPosition: Vector2(baseX - 2, baseY - 10.5),
        halfSize: Vector2(1.2, 2.0),
        kind: ObstacleKind.wood,
      ),
      Obstacle(
        initialPosition: Vector2(baseX + 2, baseY - 10.5),
        halfSize: Vector2(1.2, 2.0),
        kind: ObstacleKind.wood,
      ),
      // Top beam
      Obstacle(
        initialPosition: Vector2(baseX, baseY - 13.0),
        halfSize: Vector2(3.5, 0.5),
        kind: ObstacleKind.wood,
      ),
    ]);

    // Invisible Walls
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

  // ====== Bird Control ======
  void handlePointerDown(Vector2 p) {
    if (birdInFlight || levelCompleted) return;
    slingshot.beginDrag(p);
  }

  void handleDragMove(Vector2 p) {
    if (birdInFlight || levelCompleted) return;
    slingshot.dragMove(p);

    final pull = p - slingshot.pivot;
    lastPull = pull;
    final velocity = (-pull) * slingshot.powerK;

    trajectory?.removeFromParent();
    trajectory = TrajectoryLine(start: slingshot.pivot, velocity: velocity);
    add(trajectory!);
  }

  void handleDragEnd() {
    if (birdInFlight || levelCompleted) return;
    slingshot.endDrag();
    trajectory?.removeFromParent();
    trajectory = null;
    lastPull = null;
    birdInFlight = true;
  }

  // ====== Bird Loader ======
  Future<void> _loadNextBird() async {
    if (currentShot >= maxShots) {
      _checkFailCondition();
      return;
    }

    final birdSprite = Sprite(await gameRef.images.load('Red.webp'));
    const double r = 2.4;
    final bird = Bird(birdSprite, radius: r, start: slingshot.pivot);
    await gameRef.world.add(bird);
    await bird.loaded;
    slingshot.load(bird);

    activeBird = bird;
    birdInFlight = false;
    currentShot++;
  }

  // ====== Scoring & Status ======
  void onPigDied() {
    pigsAlive--;
    if (pigsAlive <= 0 && !levelCompleted) {
      levelCompleted = true;
      final bonus = (timeLeft * 10).round();
      final total = score + bonus;
      final manager = gameRef.levelManager;
      manager?.showLevelCompletedWithScore(score, bonus, total);
    }
  }

  void _checkFailCondition() {
    if (pigsAlive > 0 && !levelCompleted) {
      gameRef.levelManager?.showLevelFailed();
    }
  }

  void addScore(int value) => score += value;

  // ====== Update Loop ======
  @override
  void update(double dt) {
    super.update(dt);

    if (levelCompleted) return;

    timeLeft -= dt;
    if (timeLeft <= 0) {
      timeLeft = 0;
      _checkFailCondition();
      return;
    }

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
      }
    }
  }
}
