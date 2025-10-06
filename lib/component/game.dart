import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import '../levels/level1.dart';

class MyPhysicsGame extends Forge2DGame with DragCallbacks, TapCallbacks {
  MyPhysicsGame()
      : super(
    gravity: Vector2(0, 10),
    camera: CameraComponent.withFixedResolution(width: 800, height: 600),
  );

  late final Level1 level;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    images.prefix = 'assets/images/';
    level = Level1();
    await world.add(level);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    final p = screenToWorld(event.localPosition);      // 统一转 world(米)
    level.handlePointerDown(p);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    final p = screenToWorld(event.localEndPosition);   // DragUpdate 用 localEndPosition
    level.handleDragMove(p);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    level.handleDragEnd();
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    final p = screenToWorld(event.localPosition);
    level.handleTap(p);
  }
}
