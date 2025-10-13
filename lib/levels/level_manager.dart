import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import '../levels/level1.dart';
import '../levels/level2.dart';

class LevelManager extends Component with HasGameRef<Forge2DGame> {
  int currentLevel = 1;
  Component? activeLevel;
  TextComponent? infoText;

  /// Load a specific level by number
  Future<void> loadLevel(int num) async {
    // Remove the previous level if it exists
    if (activeLevel != null && activeLevel!.isMounted) {
      activeLevel!.removeFromParent();
    }

    // Choose which level to load
    switch (num) {
      case 1:
        activeLevel = Level1();
        break;
      case 2:
        activeLevel = Level2();
        break;
      default:
        showFinalMessage();
        return;
    }

    await gameRef.world.add(activeLevel!);
    currentLevel = num;
    print("Loaded Level $num");
  }

  /// Display a message when the player completes a level
  void showLevelCompleted() {
    infoText?.removeFromParent();

    infoText = TextComponent(
      text: 'Level $currentLevel Completed!',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.yellow,
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.center,
      position: gameRef.size / 2,
    );

    add(infoText!);

    // Load the next level after 2 seconds
    Future.delayed(const Duration(seconds: 2), () async {
      infoText?.removeFromParent();
      await loadLevel(currentLevel + 1);
    });
  }

  /// Display final congratulations message when all levels are completed
  void showFinalMessage() {
    infoText?.removeFromParent();

    infoText = TextComponent(
      text: 'Congratulations! You finished all levels!',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.lightGreenAccent,
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.center,
      position: gameRef.size / 2,
    );

    add(infoText!);
    print("All levels completed!");
  }
}
