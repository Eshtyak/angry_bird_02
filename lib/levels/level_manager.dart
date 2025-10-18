import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/collisions.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'level1.dart';
import 'level2.dart';

class LevelManager extends Component with HasGameRef<Forge2DGame> {
  int currentLevel = 1;
  Component? activeLevel;
  SummaryPanel? panel;

  //
  int level1Score = 0;
  int level2Score = 0;

  Future<void> loadLevel(int num) async {
    //
    if (activeLevel != null && activeLevel!.isMounted) {
      activeLevel!.removeFromParent();
    }

    currentLevel = num;
    if (num == 1) {
      activeLevel = Level1();
    } else if (num == 2) {
      activeLevel = Level2();
    }

    if (activeLevel != null) {
      await gameRef.world.add(activeLevel!);
    }
  }

  //
  void showLevelCompletedWithScore(int score, int bonus, int total) async {
    panel?.removeFromParent();

    //
    if (currentLevel == 1) {
      level1Score = total;
      panel = SummaryPanel(
        title: 'Level 1 Completed!',
        score: score,
        bonus: bonus,
        total: total,
        buttonLabel: 'NEXT LEVEL',
        onNext: () async {
          await loadLevel(2);
        },
      );
    }
    //
    else if (currentLevel == 2) {
      level2Score = total;
      final int combined = level1Score + level2Score;
      panel = SummaryPanel(
        title: 'CONGRATULATIONS!',
        score: level1Score,
        bonus: level2Score,
        total: combined,
        buttonLabel: 'RETURN HOME',
        onNext: () async {
          Navigator.of(gameRef.buildContext!).pop(); // 返回主界面
        },
      );
    }

    //
    if (panel != null) {
      gameRef.camera.viewport.add(panel!);
    }
  }

  //
  void showLevelFailed() {
    panel?.removeFromParent();
    panel = SummaryPanel(
      title: 'Level Failed!',
      score: 0,
      bonus: 0,
      total: 0,
      buttonLabel: 'RESTART',
      onNext: () async {
        await loadLevel(currentLevel); 
      },
    );
    gameRef.camera.viewport.add(panel!);
  }
}

//
class SummaryPanel extends PositionComponent with HasGameRef<Forge2DGame> {
  final String title;
  final int score;
  final int bonus;
  final int total;
  final String buttonLabel;
  final Future<void> Function() onNext;

  SummaryPanel({
    required this.title,
    required this.score,
    required this.bonus,
    required this.total,
    required this.buttonLabel,
    required this.onNext,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    size = Vector2(300, 200);
    anchor = Anchor.center;
    final cameraSize = gameRef.camera.viewport.virtualSize;
    position = Vector2(cameraSize.x / 2, cameraSize.y / 2);

    //
    final bgPaint = Paint()..color = const Color(0xCC333333);
    add(RectangleComponent(size: size, paint: bgPaint, anchor: Anchor.topLeft));

    //
    addAll([
      _buildText(title, Vector2(size.x / 2, 30), 18),
      _buildText('Level 1: $score', Vector2(size.x / 2, 70), 14),
      _buildText('Level 2: $bonus', Vector2(size.x / 2, 95), 14),
      _buildText('Total: $total', Vector2(size.x / 2, 120), 15),
    ]);

    //
    final button = NextButton(
      label: buttonLabel,
      position: Vector2(size.x / 2 - 60, 155),
      onTap: () async {
        await onNext();
        removeFromParent();
      },
    );
    add(button);
  }

  TextComponent _buildText(String text, Vector2 pos, double fontSize) {
    return TextComponent(
      text: text,
      position: pos,
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(
          color: const Color(0xFFFFFFFF),
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

//
class NextButton extends RectangleComponent with TapCallbacks {
  final String label;
  final Future<void> Function() onTap;

  NextButton({
    required this.label,
    required Vector2 position,
    required this.onTap,
  }) : super(
    size: Vector2(120, 28),
    position: position,
    anchor: Anchor.topLeft,
    paint: Paint()..color = const Color(0xFF66BB6A),
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(TextComponent(
      text: label,
      position: Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    ));
    add(RectangleHitbox());
  }

  @override
  void onTapDown(TapDownEvent event) {
    onTap();
  }
}
