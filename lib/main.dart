import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'component/game.dart';

//截止到目前为版本1

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight]);
  runApp(const AngryApp());
}

class AngryApp extends StatelessWidget {
  const AngryApp({super.key});
  @override
  Widget build(BuildContext context) {
    final game = MyPhysicsGame();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: GameWidget(game: game)),
    );
  }
}
