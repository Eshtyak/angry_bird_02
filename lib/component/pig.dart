// lib/component/pig.dart
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'ground.dart';
import 'bird.dart';
import 'obstacle.dart';
import '../levels/level1.dart';
import '../levels/level2.dart';
import '../levels/level_manager.dart';
import 'game.dart';

/// Pig — enemy target in the game.
/// Detects collisions, takes damage, dies, and notifies the current level.
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

    // 修复关键点：添加阻尼，防止猪滚动或自转
    final def = BodyDef()
      ..type = BodyType.dynamic
      ..position = position
      ..linearDamping = 4.0     // 减缓水平滑动
      ..angularDamping = 6.0    // 抑制旋转
      ..fixedRotation = false;  // 可被撞飞旋转

    final body = world.createBody(def);

    final fixture = FixtureDef(
      shape,
      density: 0.8,
      friction: 1.2,    // 提高摩擦力，减少滑动
      restitution: 0.1, // 降低弹性，防止乱弹
    )..userData = this;

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
      if (hp <= 0) {
        _die();
      }
    }

    // 自动清除越界猪
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

    final game = gameRef;
    if (game is MyPhysicsGame) {
      final manager = game.levelManager;
      final level = manager?.activeLevel;

      if (level is Level1) {
        level.addScore(100);
        level.onPigDied();
      } else if (level is Level2) {
        level.addScore(100);
        level.onPigDied();
      }
    }
  }
}
