// lib/component/slingshot.dart
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'bird.dart';

enum TriggerTarget { both, birdOnly, slingOnly }

/// 弹弓：静态“支点”刚体 + 外部驱动的拖拽/发射逻辑
/// 已移除所有拖拽保护（无最大拉距、无角度扇形限制）。
class Slingshot extends BodyComponent {
  final Vector2 pivot;                   // 世界坐标中的支点
  final TriggerTarget trigger;           // 允许从哪里开始拖：both / birdOnly / slingOnly

  // 保留这些参数以兼容外部调用，但已不再参与限制
  final double maxPull;                  // （已忽略）
  final double backSectorDeg;            // （已忽略）

  // 仍然生效的手感参数
  final double minPullToFire;            // 最小发射拉距（米）
  final double powerK;                   // 发射力度系数
  final double startDetectRadius;        // 允许开始拖拽的半径（米）

  Slingshot(
      this.pivot, {
        this.trigger = TriggerTarget.both,
        this.maxPull = 7.0,                  // 保留但不使用
        this.minPullToFire = 0.6,
        this.powerK = 2.2,
        this.startDetectRadius = 4.0,
        this.backSectorDeg = 130,            // 保留但不使用
      });

  late Vector2 _pivot;                   // 刚体真实位置
  Bird? _loaded;                         // 当前装填的鸟
  bool _dragging = false;
  Vector2 _pull = Vector2.zero();        // 从支点指向手指（世界坐标）
  double _detectR = 0;                   // 实际检测半径（随鸟半径自适应）

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    renderBody = false;

    // 贴图
    final img = await game.images.load('slingshot.webp');
    add(SpriteComponent(
      sprite: Sprite(img),
      size: Vector2.all(6),              // 世界单位（米）
      anchor: Anchor.center,
    ));
  }

  /// 关卡调用：把鸟“装填”到弹弓
  void load(Bird bird) {
    _loaded = bird;
    final b = bird.body;
    b
      ..setTransform(_pivot, 0)
      ..linearVelocity = Vector2.zero()
      ..angularVelocity = 0
      ..setAwake(true);

    // 自适应拖拽检测范围：取基础半径与 1.3×鸟半径 的较大值
    double r = startDetectRadius;
    try {
      r = math.max(r, bird.radius * 1.3);
    } catch (_) {}
    _detectR = r;
  }

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

  // ===== 给 Level1/Game 调用的三个方法（传入世界坐标） =====

  void beginDrag(Vector2 worldP) {
    if (_loaded == null) return;
    if (_canStartAt(worldP)) _dragging = true;
  }

  void dragMove(Vector2 worldP) {
    if (!_dragging || _loaded == null) return;

    // 直接使用手指相对支点的向量（不做任何长度/角度限制）
    _pull = worldP - _pivot;

    _loaded!.body
      ..setTransform(_pivot + _pull, 0)
      ..linearVelocity = Vector2.zero()
      ..angularVelocity = 0;
  }

  void endDrag() {
    if (!_dragging || _loaded == null) return;

    final b = _loaded!.body;
    final L = _pull.length;

    if (L < minPullToFire) {
      // 回位，不发射
      b
        ..setTransform(_pivot, 0)
        ..linearVelocity = Vector2.zero()
        ..angularVelocity = 0
        ..setAwake(true);
    } else {
      // 发射前把鸟从支点沿拉伸方向移出一个很小的“安全间隙”
      final dir = _pull.normalized();
      final start = _pivot + dir * (_loaded!.radius + 0.1); // 0.1m 安全间隙
      b
        ..setTransform(start, 0)
        ..setAwake(true)
        ..linearVelocity = Vector2.zero()
        ..angularVelocity = 0;

      // 与拉向相反的冲量
      b.applyLinearImpulse((-_pull) * powerK * b.mass);
    }

    _dragging = false;
    _pull.setZero();
    _loaded = null;
  }

  // ===== 支点刚体：做成 sensor，避免与小鸟发生物理碰撞 =====
  @override
  Body createBody() {
    final shape = CircleShape()..radius = 0.8;
    final def = BodyDef(type: BodyType.static, position: pivot);
    final body = world.createBody(def)
      ..createFixture(FixtureDef(
        shape,
        friction: 0.2,
        density: 1.0,
        isSensor: true,                 // 不参与碰撞，只用于检测
      ));
    _pivot = body.position.clone();
    return body;
  }
}
