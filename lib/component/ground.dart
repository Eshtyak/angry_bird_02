import 'dart:ui' as ui;
import 'package:flame_forge2d/flame_forge2d.dart';

class Ground extends BodyComponent {
  Ground(this.rect, {this.y}) : super(renderBody: false);

  final ui.Rect rect;
  final double? y; // 可选：外部指定地面高度

  @override
  Body createBody() {
    final gy = y ?? rect.bottom; // 默认贴底
    final shape = EdgeShape()..set(Vector2(rect.left, gy), Vector2(rect.right, gy));
    final body = world.createBody(BodyDef(position: Vector2.zero()));
    body.createFixtureFromShape(shape, friction: 0.8);
    return body;
  }
}
