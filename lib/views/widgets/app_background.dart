import 'package:flutter/material.dart';

import '../themes/colors.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.black,
        image: DecorationImage(
          image: AssetImage(MyColors.backgroundImage),
          fit: BoxFit.cover,
        ),
      ),
      child: ColoredBox(
        color: Colors.black26,
        child: child,
      ),
    );
  }
}
