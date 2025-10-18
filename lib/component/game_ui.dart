import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart'; // for ScaleEffect, EffectController
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import '../levels/level1.dart';
import '../levels/level2.dart';
import '../levels/level_manager.dart';
import 'game.dart';

class GameUI extends Component with HasGameReference<MyPhysicsGame>, TapCallbacks {
  GameUI(this.game);
  final MyPhysicsGame game;

  late UIButton restartButton;
  late UIButton homeButton;
  late UIButton settingButton;

  late TextComponent timeText;
  late TextComponent shotText;
  late TextComponent scoreText;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    priority = 1000;

    final screenSize = game.size;

    // 调整整体布局：按钮位置稍微左移，避免贴边
    const double spacing = 55.0;
    const double size = 48.0;
    final Vector2 topRight = Vector2(screenSize.x - 180, screenSize.y * 0.1);

    // ====== Setting ======
    settingButton = await UIButton.create(
      game,
      'gamesetting.png',
      Vector2(topRight.x - spacing * 2.4, topRight.y),
      size,
      onTap: _onSettingPressed,
    );

    // ====== Home ======
    homeButton = await UIButton.create(
      game,
      'home.png',
      Vector2(topRight.x - spacing * 1.2, topRight.y),
      size,
      onTap: _onHomePressed,
    );

    // ====== Restart ======
    restartButton = await UIButton.create(
      game,
      'restart.png',
      Vector2(topRight.x, topRight.y),
      size,
      onTap: _onRestartPressed,
    );

    // add the ui button
    addAll([
      settingButton,
      homeButton,
      restartButton,
    ]);

    // ====== Text info ======
    const textStyle = TextStyle(
      fontSize: 20,
      color: Colors.white,
      shadows: [Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2)],
    );

    timeText = TextComponent(
      text: 'Time: 0.00 s',
      position: Vector2(20, topRight.y - 12),
      textRenderer: TextPaint(style: textStyle),
    );

    shotText = TextComponent(
      text: 'Shots: 0 / 0',
      position: Vector2(20, topRight.y + 24),
      textRenderer: TextPaint(style: textStyle),
    );

    scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(20, topRight.y + 60),
      textRenderer: TextPaint(style: textStyle),
    );

    addAll([timeText, shotText, scoreText]);
  }

  // restar
  void _onRestartPressed() async {
    await game.restartLevel();
  }

  void _onHomePressed() {
    FlameAudio.bgm.stop();
    Navigator.of(game.buildContext!).pop();
  }

  void _onSettingPressed() {
    debugPrint('Settings not implemented yet.');
  }

  @override
  void update(double dt) {
    super.update(dt);

    final manager = game.levelManager;
    if (manager?.activeLevel == null) return;

    final level = manager!.activeLevel;
    double timeLeft = 0;
    int maxShots = 0;
    int currentShot = 0;
    int score = 0;

    if (level is Level1) {
      timeLeft = level.timeLeft;
      maxShots = level.maxShots;
      currentShot = level.currentShot;
      score = level.score;
    } else if (level is Level2) {
      timeLeft = level.timeLeft;
      maxShots = level.maxShots;
      currentShot = level.currentShot;
      score = level.score;
    }

    timeText.text = 'Time: ${timeLeft.toStringAsFixed(2)} s';
    shotText.text = 'Shots: $currentShot / $maxShots';
    scoreText.text = 'Score: $score';
  }
}

// public ui button
class UIButton extends SpriteComponent with TapCallbacks {
  final VoidCallback? onTap;
  bool _active = true;

  bool get isActive => _active;
  set isActive(bool value) {
    _active = value;
    opacity = value ? 1.0 : 0.0;
  }

  UIButton({
    required Sprite sprite,
    required Vector2 position,
    required Vector2 size,
    this.onTap,
  }) : super(sprite: sprite, position: position, size: size, anchor: Anchor.center);

  static Future<UIButton> create(
      MyPhysicsGame game,
      String asset,
      Vector2 position,
      double size, {
        VoidCallback? onTap,
      }) async {
    final sprite = Sprite(await game.images.load(asset));
    return UIButton(
      sprite: sprite,
      position: position,
      size: Vector2.all(size),
      onTap: onTap,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    add(
      ScaleEffect.to(
        Vector2.all(0.9),
        EffectController(duration: 0.05),
        onComplete: () {
          add(ScaleEffect.to(Vector2.all(1.0), EffectController(duration: 0.05)));
        },
      ),
    );
    if (_active) {
      onTap?.call();
    }
  }
}
