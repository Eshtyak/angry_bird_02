import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_audio/flame_audio.dart';
import 'game_ui.dart';
import '../levels/level1.dart';
import '../levels/level2.dart';
import '../levels/level_manager.dart';

class MyPhysicsGame extends Forge2DGame with DragCallbacks, TapCallbacks {
  final int selectedLevel;
  MyPhysicsGame({this.selectedLevel = 1})
      : super(
    gravity: Vector2(0, 15),
    camera: CameraComponent.withFixedResolution(width: 800, height: 600),
  );

  LevelManager? levelManager;
  bool isGamePaused = false; // 全局暂停标志

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    images.prefix = 'assets/images/';
    FlameAudio.bgm.initialize();
    FlameAudio.bgm.play('background.mp3', volume: 0.5);

    // add the level manager
    levelManager = LevelManager();
    await add(levelManager!);
    await world.add(levelManager!);
    await levelManager!.loadLevel(selectedLevel);

    // add to ui layer
    camera.viewport.add(GameUI(this));
  }

  // restart
  Future<void> restartLevel() async {
    await levelManager?.loadLevel(levelManager!.currentLevel);
  }

  // next level
  Future<void> nextLevel() async {
    await levelManager?.loadLevel(levelManager!.currentLevel + 1);
  }


  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    final pos = screenToWorld(event.localPosition);
    final active = levelManager?.activeLevel;
    if (active is Level1) active.handlePointerDown(pos);
    if (active is Level2) active.handlePointerDown(pos);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    final pos = screenToWorld(event.localEndPosition);
    final active = levelManager?.activeLevel;
    if (active is Level1) active.handleDragMove(pos);
    if (active is Level2) active.handleDragMove(pos);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    final active = levelManager?.activeLevel;
    if (active is Level1) active.handleDragEnd();
    if (active is Level2) active.handleDragEnd();
  }
}
