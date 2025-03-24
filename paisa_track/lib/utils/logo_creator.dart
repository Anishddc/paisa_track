import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

/// A utility class for creating placeholder logos for banks or wallets
class LogoCreator {
  /// Creates a simple placeholder logo for Rastriya Banijya Bank
  /// and saves it to assets/banks/rastriya.png
  static Future<void> createRastriyaBankLogo() async {
    // Ensure the directory exists
    final directory = Directory('assets/banks');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    // Create a picture recorder
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Logo dimensions (300x300 pixels)
    const size = Size(300, 300);
    
    // Draw a filled circle with a dark blue color
    final backgroundPaint = Paint()
      ..color = const Color(0xFF0A2463)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      backgroundPaint,
    );
    
    // Draw a border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2 - 5,
      borderPaint,
    );
    
    // Add text "RBB"
    const text = 'RBB';
    final textStyle = ui.TextStyle(
      color: Colors.white,
      fontSize: 100,
      fontWeight: FontWeight.bold,
    );
    
    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.center,
    ))
      ..pushStyle(textStyle)
      ..addText(text);
    
    final paragraph = paragraphBuilder.build();
    paragraph.layout(ui.ParagraphConstraints(width: size.width));
    
    final textOffset = Offset(
      (size.width - paragraph.minIntrinsicWidth) / 2,
      (size.height - paragraph.height) / 2,
    );
    
    canvas.drawParagraph(paragraph, textOffset);
    
    // End drawing
    final picture = recorder.endRecording();
    
    // Convert to image
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData != null) {
      // Save to file
      final file = File(path.join('assets/banks', 'rastriya.png'));
      await file.writeAsBytes(byteData.buffer.asUint8List());
      print('Created placeholder logo for Rastriya Banijya Bank');
    } else {
      print('Failed to create image data');
    }
  }
} 