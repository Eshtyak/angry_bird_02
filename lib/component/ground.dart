import 'dart:ui' as ui;
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame/components.dart';

class Ground extends BodyComponent {
  final ui.Rect rect;
  final double y;

  Ground(this.rect, {required this.y});

  @override
  Body createBody() {
    final shape = PolygonShape()
      ..setAsBox(rect.width / 2, 0.3, Vector2(rect.center.dx, y + 0.15), 0);
    final def = BodyDef(type: BodyType.static);
    final body = world.createBody(def)
      ..createFixture(FixtureDef(
        shape,
        friction: 0.7,
        restitution: 0.0,
        density: 1.0,
      ));
    return body;
  }
}
