import 'package:flutter/material.dart';

/// Component điều phối bố cục đáp ứng (Responsive Layout) theo điểm gãy 768px:
/// - `< 768px` (Mobile): Hiển thị giao diện di động (với BottomNavigationBar 4 tab).
/// - `>= 768px` (PC/Tablet): Hiển thị giao diện màn hình rộng (NavigationRail + 2 cột cố định 40% - 60%).
class ResponsiveLayout extends StatelessWidget {
  static const double breakpoint = 768.0;

  final Widget mobile;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.desktop,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < breakpoint;

  static bool isDesktopOrTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return mobile;
        }
        return desktop;
      },
    );
  }
}
