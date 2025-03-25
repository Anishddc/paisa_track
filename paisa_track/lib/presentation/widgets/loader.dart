import 'package:flutter/material.dart';
import 'package:paisa_track/core/constants/color_constants.dart';

/// A reusable loader widget that displays a centered CircularProgressIndicator
/// with optional customization options.
class Loader extends StatelessWidget {
  /// Size of the loader
  final double size;
  
  /// Color of the loader, defaults to primary color
  final Color? color;
  
  /// Thickness of the loader, defaults to 4.0
  final double strokeWidth;
  
  /// Whether to show a background, defaults to true
  final bool showBackground;
  
  /// Background color, defaults to white with 90% opacity
  final Color backgroundColor;

  /// Creates a Loader widget
  const Loader({
    Key? key,
    this.size = 40.0,
    this.color,
    this.strokeWidth = 4.0,
    this.showBackground = true,
    this.backgroundColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: showBackground
          ? Container(
              width: size + 16,
              height: size + 16,
              decoration: BoxDecoration(
                color: backgroundColor.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: _buildProgressIndicator(),
              ),
            )
          : _buildProgressIndicator(),
    );
  }

  Widget _buildProgressIndicator() {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? ColorConstants.primaryColor,
        ),
        strokeWidth: strokeWidth,
      ),
    );
  }
}

/// A full screen loader with a darker overlay background
class FullScreenLoader extends StatelessWidget {
  const FullScreenLoader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: Loader(),
      ),
    );
  }
}

/// A loader that shows a shimmer effect for placeholder content
class ShimmerLoader extends StatelessWidget {
  final Widget child;
  
  const ShimmerLoader({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
} 