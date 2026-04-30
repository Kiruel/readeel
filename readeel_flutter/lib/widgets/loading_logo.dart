import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoadingLogo extends StatelessWidget {
  const LoadingLogo({
    super.key,
    this.size = 50,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
          'assets/logo.svg',
          width: size,
          height: size,
        )
        .animate(
          onPlay: (controller) => controller.repeat(reverse: true), // loop
        )
        .fade(
          duration: const Duration(seconds: 1),
          curve: Curves.easeInOut,
        );
  }
}
