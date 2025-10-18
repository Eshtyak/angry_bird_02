import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'component/game.dart'; // 游戏逻辑

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bounce Party',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: Colors.black),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _bg = 'assets/images/HomePage.png';
  static const _btnStart = 'assets/images/Start.png';
  static const _btnLevel = 'assets/images/Level.png';
  static const _btnSetting = 'assets/images/Setting.png';
  static const _btnRank = 'assets/images/Rank.png';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      const alignY = 0.32;
      final horizontalPadding = w * 0.12;
      final maxWidthFraction = 0.55;
      const scale = 0.34;
      const stretchX = 1.15;
      const spacing = 92.0;

      return Stack(
        children: [
          Positioned.fill(
            child: Image.asset(_bg, fit: BoxFit.cover, filterQuality: FilterQuality.high),
          ),
          Align(
            alignment: const Alignment(0, alignY),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: w * maxWidthFraction),
                child: _ButtonsStack(
                  items: [
                    // ✅ 按钮 1：进入第 1 关
                    _BtnItem(_btnStart, onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => Scaffold(
                          body: GameWidget(game: MyPhysicsGame(selectedLevel: 1)),
                        ),
                      ));
                    }),
                    // ✅ 按钮 2：打开关卡选择界面
                    _BtnItem(_btnLevel, onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LevelSelectPage()),
                      );
                    }),
                    _BtnItem(_btnSetting),
                    _BtnItem(_btnRank),
                  ],
                  scale: scale,
                  stretchX: stretchX,
                  spacing: spacing,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

/* ------------------- 新增：关卡选择页 ------------------- */
class LevelSelectPage extends StatelessWidget {
  const LevelSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 背景
        Positioned.fill(
          child: Image.asset('assets/images/HomePage.png',
              fit: BoxFit.cover, filterQuality: FilterQuality.high),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'SELECT LEVEL',
                style: TextStyle(
                  color: Colors.yellow,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 3)],
                ),
              ),
              const SizedBox(height: 40),

              // 按钮：Level 1
              _menuButton(context, "Level 1", Colors.green, () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      body: GameWidget(game: MyPhysicsGame(selectedLevel: 1)),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 25),

              // 按钮：Level 2
              _menuButton(context, "Level 2", Colors.orange, () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      body: GameWidget(game: MyPhysicsGame(selectedLevel: 2)),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 60),

              // 返回主页
              _menuButton(context, "Back to Home", Colors.purple, () {
                Navigator.pop(context);
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _menuButton(BuildContext context, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black54, offset: Offset(3, 3), blurRadius: 4)
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

/* ---------------- 按钮组 ---------------- */
class _BtnItem {
  const _BtnItem(this.asset, {this.onTap});
  final String asset;
  final VoidCallback? onTap;
}

class _ButtonsStack extends StatelessWidget {
  const _ButtonsStack({
    super.key,
    required this.items,
    this.scale = 1.0,
    this.stretchX = 1.0,
    this.spacing = 80.0,
  });

  final List<_BtnItem> items;
  final double scale;
  final double stretchX;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final boxW = c.maxWidth;
      return SizedBox(
        width: boxW,
        height: (items.length - 1) * spacing + 120,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < items.length; i++)
              Positioned(
                top: i * spacing,
                left: 0,
                right: 0,
                child: Center(
                  child: _ImageButton(
                    asset: items[i].asset,
                    scale: scale,
                    stretchX: stretchX,
                    onTap: items[i].onTap,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

/* ---------------- 单个图片按钮 ---------------- */
class _ImageButton extends StatelessWidget {
  const _ImageButton({
    required this.asset,
    this.onTap,
    this.scale = 1.0,
    this.stretchX = 1.0,
    this.semantics,
  });

  final String asset;
  final VoidCallback? onTap;
  final double scale;
  final double stretchX;
  final String? semantics;

  @override
  Widget build(BuildContext context) {
    final img = ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.asset(asset, fit: BoxFit.contain, filterQuality: FilterQuality.high),
    );

    final transformed = Transform.scale(
      scale: scale,
      alignment: Alignment.center,
      child: Transform(
        alignment: Alignment.center,
        transform: vm.Matrix4.diagonal3Values(stretchX, 1.0, 1.0),
        child: img,
      ),
    );

    if (onTap == null) return transformed;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: transformed,
      ),
    );
  }
}
