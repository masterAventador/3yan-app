import 'package:flutter/material.dart';

/// 控制 [SlideDrawerScaffold] 的开关状态。
///
/// 由页面持有（在 State 的 initState 创建、dispose 释放），
/// 设置按钮的 onPressed 调用 [toggle]，露出的主页面遮罩点击调用 [close]。
///
/// 状态守卫：已处于目标状态时不重复 notify，避免无意义的动画重启。
class SlideDrawerController extends ChangeNotifier {
  bool _isOpen = false;
  bool get isOpen => _isOpen;

  void open() {
    if (_isOpen) return;
    _isOpen = true;
    notifyListeners();
  }

  void close() {
    if (!_isOpen) return;
    _isOpen = false;
    notifyListeners();
  }

  void toggle() => _isOpen ? close() : open();
}

/// 侧滑抽屉容器：触发后**主页面整体向右平移**，露出底层的左侧抽屉。
///
/// 区别于 Flutter 标准 [Drawer]（抽屉滑出覆盖在页面上）——这里是主页面被
/// "推开"，纯位移不缩放。底层放 [drawer]，上层放 [body]，[body] 用
/// [AnimatedPositioned] 在 `left: 0`（关）↔ `left: 抽屉宽`（开）之间补间，
/// 宽度恒为屏宽保证不变形。打开时主页面盖一层透明遮罩，点击即关闭。
///
/// ```dart
/// SlideDrawerScaffold(
///   controller: _drawerController,            // 页面持有，设置按钮调 toggle()
///   drawer: const MySettingsDrawer(),
///   body: Scaffold(appBar: AppBar(actions: [
///     IconButton(icon: const Icon(Icons.settings),
///       onPressed: _drawerController.toggle),
///   ]), body: ...),
/// )
/// ```
class SlideDrawerScaffold extends StatefulWidget {
  final SlideDrawerController controller;
  final Widget drawer;
  final Widget body;

  /// 抽屉宽度占屏比例，默认 0.78（露出抽屉、右侧留一截主页面方便点击关闭）。
  final double drawerWidthFraction;

  /// 平移动画时长。
  final Duration duration;

  const SlideDrawerScaffold({
    super.key,
    required this.controller,
    required this.drawer,
    required this.body,
    this.drawerWidthFraction = 0.78,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<SlideDrawerScaffold> createState() => _SlideDrawerScaffoldState();
}

class _SlideDrawerScaffoldState extends State<SlideDrawerScaffold> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(SlideDrawerScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth * widget.drawerWidthFraction;
    final open = widget.controller.isOpen;

    return Material(
      child: Stack(
        children: [
          // 底层：左侧抽屉（固定宽度，贴左）
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: drawerWidth,
            child: widget.drawer,
          ),
          // 上层：主页面，整体平移（纯位移），宽度恒为屏宽 → 不变形
          AnimatedPositioned(
            duration: widget.duration,
            curve: Curves.easeOutCubic,
            left: open ? drawerWidth : 0,
            top: 0,
            bottom: 0,
            width: screenWidth,
            child: Stack(
              children: [
                widget.body,
                // 打开时盖一层透明遮罩：拦截主页面交互 + 点击关闭抽屉
                if (open)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.controller.close,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
