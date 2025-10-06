import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

/// 简单的小鸟：动态圆形刚体 + 贴图
class Bird extends BodyComponent {
  Bird(this.sprite, {this.radius = 1.2, Vector2? start})
      : startPosition = start;

  final Sprite sprite;
  final double radius;               // 半径（世界单位：米）
  final Vector2? startPosition;      // 不传则在创建时用默认位置

  @override
  Body createBody() {
    final shape = CircleShape()..radius = radius;
    final pos = startPosition ?? Vector2(-25, -10); // 视口左下附近（按需改）
    final def = BodyDef()
      ..type = BodyType.dynamic
      ..bullet = true
      ..position = pos;
    final b = world.createBody(def);
    b.createFixtureFromShape(
      shape,
      density: 1.2,
      friction: 0.6,
      restitution: 0.35,
    );
    return b;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(SpriteComponent(
      sprite: sprite,
      size: Vector2.all(radius * 2),
      anchor: Anchor.center,
    ));
  }
}
