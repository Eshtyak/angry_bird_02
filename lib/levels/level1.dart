// lib/levels/level1.dart
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../component/ground.dart';
import '../component/bird.dart';
import '../component/pig.dart';
import '../component/obstacle.dart';
import '../component/slingshot.dart';

class Level1 extends Component with HasGameRef<Forge2DGame> {
  static const bool DEBUG_LINE = true;
  static const double groundTopRatio = 0.28;

  // 提升为字段，便于从 Game 层转发拖拽事件
  late final Slingshot slingshot;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final rect = gameRef.camera.visibleWorldRect;

    // 1) 背景
    final bg = await gameRef.images.load('background.jpg');
    add(SpriteComponent(
      sprite: Sprite(bg),
      size: Vector2(rect.width, rect.height),
      position: Vector2(rect.left, rect.top),
      anchor: Anchor.topLeft,
    ));

    // 2) 地面（不可见 Edge）
    final double groundY = rect.bottom - rect.height * groundTopRatio;
    await gameRef.world.add(Ground(rect, y: groundY));

    if (DEBUG_LINE) {
      add(RectangleComponent()
        ..size = Vector2(rect.width, 0.06)
        ..position = Vector2(rect.left, groundY)
        ..anchor = Anchor.topLeft
        ..paint = (ui.Paint()..color = const ui.Color(0x80FF0000)));
    }

    // 3) 弹弓
    final Vector2 slingPivot = Vector2(rect.left + 12, groundY - 1.2);
    slingshot = Slingshot(
      slingPivot,
      startDetectRadius: 8.0,          // 更容易选中
      trigger: TriggerTarget.both,
      powerK: 2.0,                     // 发射力度
      maxPull: 7.5,                    // 最大拉距
    );
    await gameRef.world.add(slingshot);

    // 鸟
    final birdSprite = Sprite(await gameRef.images.load('Red.webp'));
    const double r = 2.4;
    final bird = Bird(
      birdSprite,
      radius: r,
      start: slingPivot, // 初始放在弹弓位置
    );
    await gameRef.world.add(bird);

    // 等两者 loaded 再“装填”到弹弓上
    await slingshot.loaded;
    await bird.loaded;
    slingshot.load(bird);

    // 4) 猪
    final pigSprite = Sprite(await gameRef.images.load('pig.webp'));
    await gameRef.world.add(
      Pig(Vector2(rect.right - 12, groundY - r), pigSprite, radius: r),
    );

    // 5) 障碍物
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
      Obstacle(
        initialPosition: Vector2(baseX, baseY - 6.0),
        halfSize: Vector2(1.2, 1.6),
        kind: ObstacleKind.barrel,
      ),
    ]);
  }

  // ===== 从 Game 接收统一事件（世界坐标）并转发给 slingshot =====
  void handlePointerDown(Vector2 p) => slingshot.beginDrag(p);
  void handleDragMove(Vector2 p)     => slingshot.dragMove(p);
  void handleDragEnd()               => slingshot.endDrag();
  void handleTap(Vector2 p) {
    // 需要点击逻辑的话写在这里（比如重置等）
  }
}
