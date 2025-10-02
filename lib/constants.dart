// constants.dart
import 'package:flame_forge2d/flame_forge2d.dart' as f2d;

class C {
  static final f2d.Vector2 gravity      = f2d.Vector2(0, 10);

  // 屏幕中心就是世界原点
  static final f2d.Vector2 groundCenter = f2d.Vector2(0, 0);
  static const double groundHalfW = 120.0;  // 地面半宽 120m（总宽 240m）
  static const double groundHalfH = 6.0;    // 厚度 12m

  static final f2d.Vector2 birdSpawn = f2d.Vector2(0, -15);
  static const double      birdRadius = 5.0;

  // 相机倍数（每米像素），先给大点保证可见
  static const double zoom = 140.0;         // 看不清就 160/180
}
