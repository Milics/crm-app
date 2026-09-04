import 'package:flutter/material.dart';
import 'clue_list_page.dart';
import 'materials_page.dart';
import 'statistic_page.dart';
import 'mine_page.dart';
import 'add_clue_page.dart';

/// 主底部导航页（标准闲鱼风格底栏：一体化白色平滑拱形底座 + 醒目微凸暖黄发布按钮）
class MainTabPage extends StatefulWidget {
  final int initialIndex;
  const MainTabPage({super.key, this.initialIndex = 0});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _pages = const [
    ClueListPage(),
    MaterialsPage(isTab: true),
    StatisticPage(),
    MinePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1976D2),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _FishStyleBottomBar(
        currentIndex: _currentIndex,
        onTabChanged: (index) {
          setState(() => _currentIndex = index);
        },
        onPublishPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCluePage()),
          );
        },
      ),
    );
  }
}

/// 仿闲鱼风格的底部导航栏（带平滑拱形小山包底座）
class _FishStyleBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onPublishPressed;

  const _FishStyleBottomBar({
    required this.currentIndex,
    required this.onTabChanged,
    required this.onPublishPressed,
  });

  @override
  Widget build(BuildContext context) {
    const barHeight = 56.0;
    // 获取设备底部安全区域高度，全面屏 iPhone 通常为 34dp，Web 兜底至少留出 20dp
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final safeBottom = bottomInset > 0 ? bottomInset : 20.0;
    final totalHeight = barHeight + safeBottom;

    return Container(
      color: Colors.transparent,
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // 1. 闲鱼经典平滑拱顶白色底栏背景（铺满底部安全区）
          Positioned.fill(
            child: CustomPaint(
              painter: _FishBarPainter(totalHeight: totalHeight),
            ),
          ),

          // 2. 导航 Tab 项（保留在 barHeight 区域内，底部留出 safeBottom 防遮挡）
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: barHeight,
            child: Row(
              children: [
                // 左侧两个 Tab
                Expanded(
                  child: _TabItem(
                    icon: Icons.groups_outlined,
                    activeIcon: Icons.groups_rounded,
                    label: '线索',
                    index: 0,
                    currentIndex: currentIndex,
                    onTap: onTabChanged,
                  ),
                ),
                Expanded(
                  child: _TabItem(
                    icon: Icons.photo_library_outlined,
                    activeIcon: Icons.photo_library_rounded,
                    label: '物料',
                    index: 1,
                    currentIndex: currentIndex,
                    onTap: onTabChanged,
                  ),
                ),

                // 中间占位给拱形黄色按钮
                const SizedBox(width: 80),

                // 右侧两个 Tab
                Expanded(
                  child: _TabItem(
                    icon: Icons.bar_chart_outlined,
                    activeIcon: Icons.bar_chart_rounded,
                    label: '统计',
                    index: 2,
                    currentIndex: currentIndex,
                    onTap: onTabChanged,
                  ),
                ),
                Expanded(
                  child: _TabItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: '我的',
                    index: 3,
                    currentIndex: currentIndex,
                    onTap: onTabChanged,
                  ),
                ),
              ],
            ),
          ),

          // 3. 中间闲鱼亮黄色正圆微凸发布按钮
          Positioned(
            top: -12,
            child: _FishPublishButton(onTap: onPublishPressed),
          ),
        ],
      ),
    );
  }
}

/// 绘制闲鱼经典的平滑拱形底栏背景 Path
class _FishBarPainter extends CustomPainter {
  final double? totalHeight;
  const _FishBarPainter({this.totalHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = totalHeight ?? size.height;
    final cx = w / 2;

    // 闲鱼舒展拱形小山包参数：宽 100dp，高 20dp
    const moundWidth = 50.0; // 拱形单侧宽度
    const moundHeight = 20.0; // 拱形凸起高度

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(cx - moundWidth, 0);

    // 三阶贝塞尔曲线平滑拱起
    path.cubicTo(
      cx - 28, 0,
      cx - 24, -moundHeight,
      cx, -moundHeight,
    );
    // 对称平滑降回
    path.cubicTo(
      cx + 24, -moundHeight,
      cx + 28, 0,
      cx + moundWidth, 0,
    );

    path.lineTo(w, 0);
    path.lineTo(w, h + 50); // 延伸铺满整个屏幕底部边缘
    path.lineTo(0, h + 50);
    path.close();

    // 1. 绘制柔和向上投影
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.08), 8, false);

    // 2. 填充纯白背景
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 3. 绘制顶部极其淡雅精致的边缘分割线
    final borderPaint = Paint()
      ..color = const Color(0xFFE5E5E5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final borderPath = Path();
    borderPath.moveTo(0, 0);
    borderPath.lineTo(cx - moundWidth, 0);
    borderPath.cubicTo(
      cx - 28, 0,
      cx - 24, -moundHeight,
      cx, -moundHeight,
    );
    borderPath.cubicTo(
      cx + 24, -moundHeight,
      cx + 28, 0,
      cx + moundWidth, 0,
    );
    borderPath.lineTo(w, 0);
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 闲鱼风格暖黄发布按钮（正圆形，58x58）
class _FishPublishButton extends StatefulWidget {
  final VoidCallback onTap;

  const _FishPublishButton({required this.onTap});

  @override
  State<_FishPublishButton> createState() => _FishPublishButtonState();
}

class _FishPublishButtonState extends State<_FishPublishButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animController.forward(),
      onTapUp: (_) {
        _animController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _animController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // 闲鱼标志性明亮饱满金黄渐变
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFEA00), // 明亮柠檬黄
                Color(0xFFFFCC00), // 饱满金黄
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB300).withValues(alpha: 0.40),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_rounded,
                size: 25,
                color: Color(0xFF1E1E1E), // 闲鱼黑
              ),
              Text(
                '录线索',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E1E1E),
                  height: 0.95,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 底部普通 Tab 项
class _TabItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    final color = isActive ? const Color(0xFF1976D2) : const Color(0xFF888888);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            color: color,
            size: 23,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
