import 'package:flutter/material.dart';
import 'package:flame/game.dart' hide Vector2;
import 'world.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: GameWidget(game: PhysicsTestGame()),
      ),
    ),
  );
}
