import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'bird.dart';
import 'trajectory_helper.dart';

enum TriggerTarget { both, birdOnly, slingOnly }

class Slingshot extends BodyComponent {
  final Vector2 pivot;
  final TriggerTarget trigger;
  final double maxPull;
  final double minPullToFire;
  final double powerK;
  final double startDetectRadius;
  final double backSectorDeg;
  final double maxAngleDeg;

  Slingshot(
      this.pivot, {
        this.trigger = TriggerTarget.both,
        this.maxPull = 10.5,          // max pull distance
        this.minPullToFire = 1.5,
        this.powerK = 10.0,           // nax pull force
        this.startDetectRadius = 6.0,
        this.backSectorDeg = 130,
        this.maxAngleDeg = 75,       // max pull angle
      });

  late Vector2 _pivot;
  Bird? _loaded;
  bool _dragging = false;
  Vector2 _pull = Vector2.zero();
  double _detectR = 0;

  TrajectoryLine? _trajectory;
  _RubberBand? _rubber;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    renderBody = false;

    // add the slingshot
    final img = await game.images.load('slingshot.webp');
    add(SpriteComponent(
      sprite: Sprite(img),
      size: Vector2.all(6),
      anchor: Anchor.center,
    ));

    // 橡皮带
    _rubber = _RubberBand(pivot);
    game.add(_rubber!);
  }

  // load the bird
  void load(Bird bird) {
    _loaded = bird;
    final b = bird.body;
    b
      ..setTransform(_pivot, 0)
      ..linearVelocity = Vector2.zero()
      ..angularVelocity = 0
      ..setAwake(true);

    double r = startDetectRadius;
    try {
      r = math.max(r, bird.radius * 1.3);
    } catch (_) {}
    _detectR = r;
  }

  // check can drag start
  bool _canStartAt(Vector2 worldP) {
    final r = _detectR > 0 ? _detectR : startDetectRadius;
    final nearSling = (worldP - _pivot).length <= r;
    final nearBird =
        _loaded != null && (worldP - _loaded!.body.position).length <= r;

    switch (trigger) {
      case TriggerTarget.slingOnly:
        return nearSling;
      case TriggerTarget.birdOnly:
        return nearBird;
      case TriggerTarget.both:
        return nearSling || nearBird;
    }
  }

  // start dragging
  void beginDrag(Vector2 worldP) {
    if (_loaded == null) return;
    if (_canStartAt(worldP)) _dragging = true;
  }

  // display the trajectory help
  void dragMove(Vector2 worldP) {
    if (!_dragging || _loaded == null) return;

    Vector2 pull = worldP - _pivot;

    // 限制最大拉距
    if (pull.length > maxPull) {
      pull.normalize();
      pull *= maxPull;
    }

    // 限制仰角范围
    final angle = pull.angleTo(Vector2(-1, 0));
    final maxRad = math.pi * maxAngleDeg / 180;
    if (angle.abs() > maxRad) {
      final sign = angle.isNegative ? -1 : 1;
      final clampedAngle = sign * maxRad;
      final len = pull.length;
      pull = Vector2(
        -math.cos(clampedAngle) * len,
        math.sin(clampedAngle) * len,
      );
    }

    _pull = pull;
    _loaded!.body
      ..setTransform(_pivot + _pull, 0)
      ..linearVelocity = Vector2.zero()
      ..angularVelocity = 0;


    _rubber?.updateStretch(_pivot, _pivot + _pull);


    _trajectory ??= TrajectoryLine();
    if (!_trajectory!.isMounted) game.add(_trajectory!);

    final gravityY = world.gravity.y;
    final predictedVelocity = (-_pull) * powerK;
    _trajectory!.updatePoints(_pivot, predictedVelocity, gravityY);
  }

  void endDrag() {
    if (!_dragging || _loaded == null) return;

    _trajectory?.removeFromParent();
    _trajectory = null;
    _rubber?.updateStretch(_pivot, _pivot);

    final b = _loaded!.body;
    final L = _pull.length;

    if (L < minPullToFire) {
      b
        ..setTransform(_pivot, 0)
        ..linearVelocity = Vector2.zero()
        ..angularVelocity = 0
        ..setAwake(true);
    } else {
      final dir = _pull.normalized();
      final baseStart = _pivot + dir * (_loaded!.radius + 0.5);
      final safeStart = Vector2(baseStart.x, math.min(baseStart.y, _pivot.y - 0.8));
      final impulse = (-_pull) * powerK * b.mass * 1.8;
      b
        ..setTransform(safeStart, 0)
        ..setAwake(true)
        ..linearVelocity = Vector2.zero()
        ..angularVelocity = 0
        ..applyLinearImpulse(impulse);
    }
    _dragging = false;
    _pull.setZero();
    _loaded = null;
  }

  @override
  Body createBody() {
    final shape = CircleShape()..radius = 0.8;
    final def = BodyDef(type: BodyType.static, position: pivot);
    final body = world.createBody(def)
      ..createFixture(FixtureDef(
        shape,
        friction: 0.2,
        density: 1.0,
        isSensor: true,
      ));
    _pivot = body.position.clone();
    return body;
  }
}

class _RubberBand extends Component {
  Vector2 anchor;
  Vector2 end;
  final Paint _paint = Paint()
    ..color = const Color(0xFF7B3F00)
    ..strokeWidth = 0.15
    ..style = PaintingStyle.stroke;

  _RubberBand(this.anchor) : end = anchor.clone();

  void updateStretch(Vector2 pivot, Vector2 birdPos) {
    anchor = pivot;
    end = birdPos;
  }

  @override
  void render(Canvas canvas) {
    final leftAnchor = Vector2(anchor.x - 0.3, anchor.y);
    final rightAnchor = Vector2(anchor.x + 0.3, anchor.y);
    canvas.drawLine(leftAnchor.toOffset(), end.toOffset(), _paint);
    canvas.drawLine(rightAnchor.toOffset(), end.toOffset(), _paint);
  }
}
