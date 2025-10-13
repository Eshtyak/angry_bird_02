import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'component/game.dart'; // 导入物理游戏逻辑

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
                    // ✅ 按钮 1：进入第一关
                    _BtnItem(_btnStart, onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => Scaffold(
                          body: GameWidget(game: MyPhysicsGame(selectedLevel: 1)),
                        ),
                      ));
                    }),
                    // ✅ 按钮 2：进入第二关
                    _BtnItem(_btnLevel, onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => Scaffold(
                          body: GameWidget(game: MyPhysicsGame(selectedLevel: 2)),
                        ),
                      ));
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
