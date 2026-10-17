import 'package:flutter/material.dart';

/// App-wide loading indicator. Colors come from the theme's
/// `progressIndicatorTheme`, so it adapts to light and dark mode.
class LoaderWidget extends StatelessWidget {
  final bool isBlurBackground;
  final Color? loaderColor;
  final double size;

  const LoaderWidget({super.key, this.loaderColor, this.isBlurBackground = false, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final indicator = Center(
      child: SizedBox.square(
        dimension: size,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          strokeCap: StrokeCap.round,
          color: loaderColor,
        ),
      ),
    );

    if (!isBlurBackground) return indicator;

    return AbsorbPointer(
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.6),
        child: indicator,
      ),
    );
  }
}
