import 'package:flutter/widgets.dart';

class Breakpoints {
  static const double tablet = 700;
  static const double desktop = 1100;
}

/// Centers content with a readable maximum width on tablet/desktop.
class PageFrame extends StatelessWidget {
  const PageFrame({super.key, required this.child, this.maxWidth = 960});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
      );
}
