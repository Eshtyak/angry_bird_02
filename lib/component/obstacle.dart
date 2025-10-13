import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

enum ObstacleKind { wood, barrel }

class Obstacle extends BodyComponent with ContactCallbacks {
  final Vector2 initialPosition;
  final Vector2 halfSize;
  final double initialAngle;
  final ObstacleKind kind;
  final BodyType bodyType;

  late Sprite _sprite;
  double baseDamage = 0;
  double velocityFactor = 5.0;

  Obstacle({
    required this.initialPosition,
    required this.halfSize,
    this.initialAngle = 0,
    this.kind = ObstacleKind.wood,
    this.bodyType = BodyType.dynamic,
  }) : super(renderBody: false);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    switch (kind) {
      case ObstacleKind.wood:
        _sprite = Sprite(await game.images.load('Wooden.png'));
        baseDamage = 50;
        velocityFactor = 5.0;
        break;
      case ObstacleKind.barrel:
        _sprite = Sprite(await game.images.load('Barrel.webp'));
        baseDamage = 55;
        velocityFactor = 6.0;
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

    final friction = (kind == ObstacleKind.wood) ? 0.5 : 0.4;
    final density = (kind == ObstacleKind.wood) ? 1.0 : 0.7;

    final fixture = FixtureDef(
      shape,
      friction: friction,
      density: density,
      restitution: 0.05,
    )..userData = this; // ✅ 必须绑定 userData

    final def = BodyDef(
      type: bodyType,
      position: initialPosition,
      angle: initialAngle,
      userData: this,
    );

    return world.createBody(def)..createFixture(fixture);
  }

  double computeImpactDamage() {
    final speed = body.linearVelocity.length;
    final impactDamage = baseDamage + speed * velocityFactor * 1.5;
    return impactDamage;
  }
}
