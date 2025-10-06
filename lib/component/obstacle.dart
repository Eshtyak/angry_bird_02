// lib/component/obstacle.dart
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

enum ObstacleKind { wood, barrel }

/// 可复用的矩形障碍物（米为单位）
class Obstacle extends BodyComponent {
  // 用“initial*”避免与父类成员名冲突
  final Vector2 initialPosition; // 世界坐标（米）
  final Vector2 halfSize;        // 半宽半高（米）
  final double initialAngle;     // 弧度
  final ObstacleKind kind;
  final BodyType bodyType;

  Obstacle({
    required this.initialPosition,
    required this.halfSize,
    this.initialAngle = 0,
    this.kind = ObstacleKind.wood,
    this.bodyType = BodyType.dynamic,
  }) : super() {
    // 不能放在初始化列表里设置实例成员
    renderBody = false;
  }

  late Sprite _sprite;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // BodyComponent 本身就有 gameRef，不要再混入 HasGameReference
    switch (kind) {
      case ObstacleKind.wood:
        _sprite = Sprite(await game.images.load('Wooden.png'));
        break;
      case ObstacleKind.barrel:
        _sprite = Sprite(await game.images.load('Barrel.webp'));
        break;
    }

    add(SpriteComponent(
      sprite: _sprite,
      size: Vector2(halfSize.x * 2, halfSize.y * 2),
      anchor: Anchor.center,
    ));
  }

  @override
  Body createBody() {
    final shape = PolygonShape()..setAsBoxXY(halfSize.x, halfSize.y);

    final friction = (kind == ObstacleKind.wood) ? 0.5 : 0.3;
    final density  = (kind == ObstacleKind.wood) ? 1.0 : 0.6;

    final fixture = FixtureDef(
      shape,
      friction: friction,
      density: density,
      restitution: 0.05,
    );

    final def = BodyDef(
      type: bodyType,
      position: initialPosition,
      angle: initialAngle,
      userData: this,
    );

    return world.createBody(def)..createFixture(fixture);
  }
}
