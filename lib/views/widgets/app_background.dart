import 'package:flutter/material.dart';

import '../themes/colors.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: MyColors.background),
      child: child,
    );
  }
}
