import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'ground.dart';
import 'bird.dart';
import 'obstacle.dart';

class Pig extends BodyComponent with ContactCallbacks, HasGameRef<Forge2DGame> {
  Pig(this.position, this.sprite, {this.radius = 1.2, this.maxHp = 35})
      : super(renderBody: false) {
    hp = maxHp;
  }

  final Vector2 position;
  final Sprite sprite;
  final double radius;
  final double maxHp;

  late double hp;
  bool isDead = false;
  bool _touchedGround = false;

  @override
  Body createBody() {
    final shape = CircleShape()..radius = radius;
    final def = BodyDef()
      ..type = BodyType.dynamic
      ..position = position;
    final body = world.createBody(def);

    final fixture = FixtureDef(
      shape,
      density: 0.8,
      friction: 0.6,
      restitution: 0.2,
    )..userData = this; // ✅ 必须绑定 userData

    body.createFixture(fixture);
    return body;
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
    if (isDead) return;

    double damage = 0;

    // ✅ 确认是否触发
    print("Pig contact with: ${other.runtimeType}");

    if (other is Bird) {
      final v = other.body.linearVelocity.length;
      damage = v * v * 2.2;
    } else if (other is Obstacle) {
      final v = other.body.linearVelocity.length;
      damage = v * v * 1.8;
    } else if (other is Ground && !_touchedGround) {
      damage = 20;
      _touchedGround = true;
    }

    if (damage > 0) {
      hp -= damage;
      print('Pig hit! damage=$damage, hp=$hp');
      if (hp <= 0) _die();
    }

    final pos = body.position;
    final bounds = gameRef.camera.visibleWorldRect;
    if (pos.y > bounds.bottom + 10 || pos.x > bounds.right + 20) {
      _die();
    }
  }

  void _die() {
    if (isDead) return;
    isDead = true;
    removeFromParent();
    print("Pig eliminated!");
  }
}
