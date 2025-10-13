import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import '../levels/level1.dart';

class GameUI extends PositionComponent with TapCallbacks {
  final Forge2DGame game;
  GameUI(this.game);

  late SpriteComponent pauseButton;
  late SpriteComponent resumeButton;
  late SpriteComponent restartButton;
  late SpriteComponent homeButton;
  late SpriteComponent settingButton;

  bool isPaused = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // ✅ 屏幕尺寸（像素坐标）
    final screenSize = game.camera.viewport.virtualSize ?? game.size;

    // ✅ 屏幕右上角位置
    final Vector2 topRight = Vector2(screenSize.x - 60, 60);
    const double spacing = 60.0; // 按钮间距
    const double size = 48.0; // 按钮大小（像素）

    // Pause
    pauseButton = await _buildButton('pause.png', topRight, size);

    // Resume
    resumeButton = await _buildButton('keepplay.png', topRight, size);
    resumeButton.opacity = 0;

    // Restart
    restartButton = await _buildButton(
      'Start.png',
      Vector2(topRight.x - spacing * 1.2, topRight.y),
      size,
    );

    // Home
    homeButton = await _buildButton(
      'home.png',
      Vector2(topRight.x - spacing * 2.4, topRight.y),
      size,
    );

    // Setting
    settingButton = await _buildButton(
      'gamesetting.png',
      Vector2(topRight.x - spacing * 3.6, topRight.y),
      size,
    );

    addAll([pauseButton, resumeButton, restartButton, homeButton, settingButton]);
  }

  Future<SpriteComponent> _buildButton(
      String imageName, Vector2 pos, double size) async {
    final sprite = await game.loadSprite(imageName);
    final button = SpriteComponent(
      sprite: sprite,
      size: Vector2.all(size),
      position: pos,
      anchor: Anchor.center,
      priority: 1000, // ✅ 确保覆盖游戏场景
    );
    return button;
  }

  @override
  void onTapDown(TapDownEvent event) {
    final p = event.localPosition;

    if (pauseButton.containsPoint(p) && !isPaused) {
      _onPausePressed();
    } else if (resumeButton.containsPoint(p) && isPaused) {
      _onResumePressed();
    } else if (restartButton.containsPoint(p)) {
      _onRestartPressed();
    } else if (homeButton.containsPoint(p)) {
      _onHomePressed();
    } else if (settingButton.containsPoint(p)) {
      _onSettingPressed();
    }
  }

  // ================= 按钮逻辑 =================
  void _onPausePressed() {
    if (!isPaused) {
      game.pauseEngine();
      isPaused = true;
      pauseButton.opacity = 0;
      resumeButton.opacity = 1;
      print("Game paused");
    }
  }

  void _onResumePressed() {
    if (isPaused) {
      game.resumeEngine();
      isPaused = false;
      resumeButton.opacity = 0;
      pauseButton.opacity = 1;
      print("Game resumed");
    }
  }

  void _onRestartPressed() async {
    print("Restarting...");
    game.world.removeAll(game.world.children);
    final newLevel = Level1();
    await game.world.add(newLevel);
    isPaused = false;
    pauseButton.opacity = 1;
    resumeButton.opacity = 0;
  }

  void _onHomePressed() {
    print("Back to main menu (not implemented)");
  }

  void _onSettingPressed() {
    print("Open settings (not implemented)");
  }
}
