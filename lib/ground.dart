import 'package:flame_forge2d/flame_forge2d.dart' as f2d;

class Ground extends f2d.BodyComponent {
  final f2d.Vector2 center;
  final f2d.Vector2 halfSize; // 盒子的半宽/半高，单位米

  Ground({required this.center, required this.halfSize});

  @override
  f2d.Body createBody() {
    // 静态刚体（地面）
    final bodyDef = f2d.BodyDef(
      type: f2d.BodyType.static,
      position: center,
    );
    final body = world.createBody(bodyDef);

    // 盒子形状：setAsBox(halfWidth, halfHeight, centerLocal, angle)
    final shape = f2d.PolygonShape()
      ..setAsBox(halfSize.x, halfSize.y, f2d.Vector2.zero(), 0);

    final fixtureDef = f2d.FixtureDef(
      shape,
      friction: 0.8,
      restitution: 0.0,
    );

    body.createFixture(fixtureDef);
    return body;
  }
}
