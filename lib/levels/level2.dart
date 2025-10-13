import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../component/ground.dart';
import '../component/bird.dart';
import '../component/pig.dart';
import '../component/obstacle.dart';
import '../component/slingshot.dart';
import '../component/trajectory_helper.dart';

class Level2 extends Component with HasGameRef<Forge2DGame> {
  static const bool DEBUG_LINE = true;
  static const double groundTopRatio = 0.28;

  late final Slingshot slingshot;
  TrajectoryLine? trajectory;
  Vector2? lastPull;
  late double groundY;

  final int maxShots = 3;
  int currentShot = 0;
  Bird? activeBird;
  bool birdInFlight = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final rect = gameRef.camera.visibleWorldRect;

    // 1. 背景
    final bg = await gameRef.images.load('background.jpg');
    add(SpriteComponent(
      sprite: Sprite(bg),
      size: Vector2(rect.width, rect.height),
      position: Vector2(rect.left, rect.top),
      anchor: Anchor.topLeft,
    ));

    // 2. 地面
    groundY = rect.bottom - rect.height * groundTopRatio;
    await gameRef.world.add(Ground(rect, y: groundY));

    if (DEBUG_LINE) {
      add(RectangleComponent()
        ..size = Vector2(rect.width, 0.06)
        ..position = Vector2(rect.left, groundY)
        ..anchor = Anchor.topLeft
        ..paint = (ui.Paint()..color = const ui.Color(0x80FF0000)));
    }

    // 3. 弹弓
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

    // 4. 第一只鸟
    await _loadNextBird();

    // ============================================================
    // 5. 多层猪阵（3只）
    // ============================================================
    final pigSprite = Sprite(await gameRef.images.load('JellyPig.png'));

    await gameRef.world.addAll([
      // 底层
      Pig(Vector2(rect.right - 20, groundY - 2.4), pigSprite, radius: 2.4),
      // 中层
      Pig(Vector2(rect.right - 15, groundY - 8.0), pigSprite, radius: 2.4),
      // 顶层
      Pig(Vector2(rect.right - 17, groundY - 14.0), pigSprite, radius: 2.4),
    ]);

    // ============================================================
    // 6. 障碍物塔结构
    // ============================================================
    final baseX = rect.right - 17;
    final baseY = groundY;

    await gameRef.world.addAll([
      // 第一层底部支撑
      Obstacle(
        initialPosition: Vector2(baseX - 4, baseY - 1.5),
        halfSize: Vector2(1.5, 1.5),
        kind: ObstacleKind.wood,
      ),
      Obstacle(
        initialPosition: Vector2(baseX + 4, baseY - 1.5),
        halfSize: Vector2(1.5, 1.5),
        kind: ObstacleKind.wood,
      ),

      // 第一层横梁
      Obstacle(
        initialPosition: Vector2(baseX, baseY - 3.0),
        halfSize: Vector2(5.0, 0.6),
        kind: ObstacleKind.wood,
      ),

      // 第二层立柱
      Obstacle(
        initialPosition: Vector2(baseX - 3, baseY - 5.5),
        halfSize: Vector2(1.2, 2.0),
        kind: ObstacleKind.barrel,
      ),
      Obstacle(
        initialPosition: Vector2(baseX + 3, baseY - 5.5),
        halfSize: Vector2(1.2, 2.0),
        kind: ObstacleKind.barrel,
      ),

      // 第二层横梁
      Obstacle(
        initialPosition: Vector2(baseX, baseY - 8.0),
        halfSize: Vector2(4.5, 0.6),
        kind: ObstacleKind.wood,
      ),

      // 第三层立柱
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

      // 顶层横梁
      Obstacle(
        initialPosition: Vector2(baseX, baseY - 13.0),
        halfSize: Vector2(3.5, 0.5),
        kind: ObstacleKind.wood,
      ),
    ]);

    // === Invisible Walls ===
    final wallRect = gameRef.camera.visibleWorldRect;
    final walls = [
      EdgeShape()
        ..set(Vector2(wallRect.left, wallRect.top), Vector2(wallRect.left, wallRect.bottom)),
      EdgeShape()
        ..set(Vector2(wallRect.right, wallRect.top), Vector2(wallRect.right, wallRect.bottom)),
    ];

    for (final shape in walls) {
      final wallBodyDef = BodyDef()..type = BodyType.static;
      final wallBody = gameRef.world.createBody(wallBodyDef);
      wallBody.createFixtureFromShape(shape);
    }
  }

  // =====================================================
  // ============ 发射与拖拽逻辑 ==========================
  // =====================================================

  void handlePointerDown(Vector2 p) {
    if (birdInFlight) return;
    slingshot.beginDrag(p);
  }

  void handleDragMove(Vector2 p) {
    if (birdInFlight) return;
    slingshot.dragMove(p);

    final pull = p - slingshot.pivot;
    lastPull = pull;

    final velocity = (-pull) * slingshot.powerK;

    trajectory?.removeFromParent();
    trajectory = TrajectoryLine(start: slingshot.pivot, velocity: velocity);
    add(trajectory!);
  }

  void handleDragEnd() {
    if (birdInFlight) return;
    slingshot.endDrag();
    trajectory?.removeFromParent();
    trajectory = null;
    lastPull = null;
    birdInFlight = true;
  }

  void handleTap(Vector2 p) {}

  // =====================================================
  // ============ 自动装填新小鸟 ==========================
  // =====================================================

  Future<void> _loadNextBird() async {
    if (currentShot >= maxShots) {
      print("All birds launched!");
      return;
    }

    final birdSprite = Sprite(await gameRef.images.load('Red.webp'));
    const double r = 2.4;
    final bird = Bird(
      birdSprite,
      radius: r,
      start: slingshot.pivot,
    );
    await gameRef.world.add(bird);

    await bird.loaded;
    slingshot.load(bird);

    activeBird = bird;
    birdInFlight = false;
    currentShot++;
  }

  @override
  void update(double dt) {
    super.update(dt);

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
