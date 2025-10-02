import 'dart:math' as math;
import 'package:flame_forge2d/flame_forge2d.dart' as f2d;
import 'package:flame/components.dart' as fc;

import 'constants.dart';   // 定义了 C.worldW / C.worldH / C.gravity / C.birdSpawn
import 'ground.dart';
import 'bird.dart';

class PhysicsTestGame extends f2d.Forge2DGame {
  PhysicsTestGame() : super(gravity: C.gravity);

  late Bird _bird;
  late fc.SpriteComponent _bg;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 1) 背景：以世界坐标原点为中心，大小=世界宽高
    //    注意：pubspec.yaml 里有 `assets/images/`，所以这里路径写 'images/xxx.png'
    final bgImage = await images.load('images/background.png');
    _bg = fc.SpriteComponent.fromImage(
      bgImage,
      size: fc.Vector2(C.worldW, C.worldH),
      position: fc.Vector2.zero(),
      anchor: fc.Anchor.center,
      priority: -10,   // 在最底层
    );
    add(_bg);

    // 2) 地面/小鸟
    await add(Ground());

    _bird = Bird(spawn: C.birdSpawn);
    await add(_bird);


    // 3) 摄像机：以中心为锚点，跟随小鸟
    camera.viewfinder.anchor = fc.Anchor.center;
    camera.follow(_bird);

    // 调试用：显示刚体轮廓
    debugMode = true;
  }

  /// 根据窗口大小动态计算 zoom，使整张背景图（也就是整个世界）刚好放得下
  @override
  void onGameResize(fc.Vector2 size) {
    super.onGameResize(size);
    final zoomX = size.x / C.worldW;
    final zoomY = size.y / C.worldH;
    camera.viewfinder.zoom = math.min(zoomX, zoomY);
  }
}
