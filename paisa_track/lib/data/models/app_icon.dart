import 'package:flutter/material.dart';

/// Custom app icon painter
class AppIconPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  
  AppIconPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width * 0.4;
    
    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), size.width / 2, backgroundPaint);
    
    // Draw outer circle border
    final outerCirclePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.05;
    canvas.drawCircle(Offset(centerX, centerY), radius, outerCirclePaint);
    
    // Draw rupee symbol (₹)
    final rupeePaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;
      
    // Draw the horizontal top line
    canvas.drawLine(
      Offset(centerX - radius * 0.5, centerY - radius * 0.4),
      Offset(centerX + radius * 0.5, centerY - radius * 0.4),
      rupeePaint,
    );
    
    // Draw the vertical line
    canvas.drawLine(
      Offset(centerX, centerY - radius * 0.4),
      Offset(centerX, centerY + radius * 0.5),
      rupeePaint,
    );
    
    // Draw the middle horizontal line
    canvas.drawLine(
      Offset(centerX - radius * 0.5, centerY - radius * 0.05),
      Offset(centerX + radius * 0.3, centerY - radius * 0.05),
      rupeePaint,
    );
    
    // Draw the diagonal stroke
    canvas.drawLine(
      Offset(centerX - radius * 0.15, centerY + radius * 0.5),
      Offset(centerX + radius * 0.5, centerY - radius * 0.4),
      rupeePaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! AppIconPainter ||
           oldDelegate.primaryColor != primaryColor ||
           oldDelegate.secondaryColor != secondaryColor ||
           oldDelegate.backgroundColor != backgroundColor;
  }
}

/// Widget to display the app icon with customizable properties
class AppIcon extends StatelessWidget {
  final double size;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final bool useForegroundOnly;

  const AppIcon({
    Key? key,
    this.size = 100,
    this.primaryColor = const Color(0xFF2554C7), // Blue
    this.secondaryColor = const Color(0xFFFFC107), // Gold
    this.backgroundColor = Colors.white,
    this.useForegroundOnly = false, // By default use the full icon with background
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        // Use foreground-only version or full icon based on parameter
        useForegroundOnly 
            ? 'assets/images/foreground.png'
            : 'assets/images/solid.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}

/// Helper to export the icon to a specific size PNG
class AppIconExporter {
  static Future<void> exportToPng(String path, double size) async {
    // This would require rendering the widget to an image
    // and saving it to the file system
    // Implementation depends on the platform and would use packages like
    // 'screenshot' or 'image' to generate PNG files
  }
} 