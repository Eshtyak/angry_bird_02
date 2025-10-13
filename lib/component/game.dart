import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_audio/flame_audio.dart';
import 'game_ui.dart';
import '../levels/level1.dart';
import '../levels/level2.dart';

class MyPhysicsGame extends Forge2DGame with DragCallbacks, TapCallbacks {
  final int selectedLevel;
  MyPhysicsGame({this.selectedLevel = 1})
      : super(
    gravity: Vector2(0, 15),
    camera: CameraComponent.withFixedResolution(width: 800, height: 600),
  );

  Component? level;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    images.prefix = 'assets/images/';
    FlameAudio.bgm.initialize();
    FlameAudio.bgm.play('background.mp3', volume: 0.5);

    await loadLevel(selectedLevel);
    add(GameUI(this));
  }

  /// 动态加载不同关卡
  Future<void> loadLevel(int num) async {
    if (level != null && level!.isMounted) {
      world.remove(level!);
    }

    switch (num) {
      case 2:
        level = Level2();
        break;
      case 1:
      default:
        level = Level1();
        break;
    }
    await world.add(level!);
  }

  /// 统一输入事件转发
  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    final pos = screenToWorld(event.localPosition);
    if (level is Level1) (level as Level1).handlePointerDown(pos);
    if (level is Level2) (level as Level2).handlePointerDown(pos);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    final pos = screenToWorld(event.localEndPosition);
    if (level is Level1) (level as Level1).handleDragMove(pos);
    if (level is Level2) (level as Level2).handleDragMove(pos);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (level is Level1) (level as Level1).handleDragEnd();
    if (level is Level2) (level as Level2).handleDragEnd();
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    final pos = screenToWorld(event.localPosition);
    if (level is Level1) (level as Level1).handleTap(pos);
    if (level is Level2) (level as Level2).handleTap(pos);
  }


}
