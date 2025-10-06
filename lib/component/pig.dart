import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import 'ground.dart';

/// 小猪：动态圆形刚体 + 贴图；首次接触地面时加分
class Pig extends BodyComponent with ContactCallbacks, HasGameRef<Forge2DGame> {
  Pig(this.position, this.sprite, {this.radius = 1.2})
      : super(renderBody: false);

  final Vector2 position;
  final Sprite sprite;
  final double radius;

  bool _touchedGround = false;

  @override
  Body createBody() {
    final shape = CircleShape()..radius = radius;
    final def = BodyDef()
      ..type = BodyType.dynamic
      ..position = position;
    final b = world.createBody(def);
    b.createFixtureFromShape(
      shape,
      density: 0.8,
      friction: 0.7,
      restitution: 0.2,
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

  @override
  void beginContact(Object other, Contact contact) {
    if (!_touchedGround && other is Ground) {
      _touchedGround = true;
      // 如需计分：可以在你的 MyGame 里提供方法，这里通过 gameRef 触发
      // (示例) print 或调用外部计分：
      // (gameRef as MyGame).updateScore((gameRef as MyGame).score + 100);
    }
  }
}
