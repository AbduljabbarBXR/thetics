import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class AppMark extends StatelessWidget {
  const AppMark({super.key, this.size = 56, this.radius});

  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? size * 0.24),
      child: Image.asset(
        'assets/images/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.fontSize = 25, this.color, this.subtitle});

  final double fontSize;
  final Color? color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'THETICS',
          style: TextStyle(
            fontFamily: 'BarlowCondensed',
            fontWeight: FontWeight.w700,
            fontSize: fontSize,
            letterSpacing: fontSize * 0.045,
            height: 0.9,
            color: color ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w700,
              fontSize: fontSize * 0.28,
              letterSpacing: fontSize * 0.035,
              color: palette.accent,
            ),
          ),
        ],
      ],
    );
  }
}
