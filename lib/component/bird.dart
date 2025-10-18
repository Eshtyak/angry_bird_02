import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';


class Bird extends BodyComponent with ContactCallbacks {
  Bird(this.sprite, {this.radius = 1.2, this.damage = 60, Vector2? start})
      : startPosition = start;

  final Sprite sprite;
  final double radius;
  final Vector2? startPosition;
  final double damage;

  @override
  Body createBody() {
    final shape = CircleShape()..radius = radius;
    final pos = startPosition ?? Vector2(-25, -10);
    final def = BodyDef()
      ..type = BodyType.dynamic
      ..bullet = true
      ..position = pos;

    final b = world.createBody(def);

    // userData bonding
    final fixture = FixtureDef(
      shape,
      density: 1.8,
      friction: 0.9,
      restitution: 0.45,
    )..userData = this;

    b.createFixture(fixture);
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
