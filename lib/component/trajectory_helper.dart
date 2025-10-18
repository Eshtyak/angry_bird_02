import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'dart:ui';
import 'dart:math' as math;

class TrajectoryLine extends Component {
  final Paint _paint = Paint()
    ..color = const Color(0xAAFFFFFF)
    ..strokeWidth = 0.1;

  final List<Vector2> points = [];

  TrajectoryLine({Vector2? start, Vector2? velocity}) {
    if (start != null && velocity != null) {
      updatePoints(start, velocity, 25.0);
    }
  }

  void updatePoints(Vector2 start, Vector2 velocity, double gravityY) {
    points.clear();
    const gravityScale = 2.5;
    final g = gravityY * gravityScale;

    for (int i = 0; i < 30; i++) {
      final t = i * 0.1;
      final dx = velocity.x * t;
      final dy = velocity.y * t + 0.5 * g * t * t;
      points.add(Vector2(start.x + dx, start.y + dy));
    }
  }

  @override
  void render(Canvas canvas) {
    if (points.length < 2) return;
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i].toOffset(), points[i + 1].toOffset(), _paint);
    }
  }
}
