import 'package:flame_forge2d/flame_forge2d.dart' as f2d;

class C {
  static const double worldW = 30;   // 举例：世界宽 30m
  static const double worldH = 17;   // 举例：世界高 17m

  static f2d.Vector2 get gravity => f2d.Vector2(0, 10);
  static f2d.Vector2 get birdSpawn => f2d.Vector2(0, 0); // 世界原点
}
