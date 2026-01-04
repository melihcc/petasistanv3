import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class BubbleMarker {
  static final Map<String, BitmapDescriptor> _cache = {};

  static Future<BitmapDescriptor> build({
    required int size,
    required Color color,
    required String text,
  }) async {
    final key = '${color.value}_$size$text';
    final cached = _cache[key];
    if (cached != null) return cached;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final radius = size / 2.0;

    final paint = Paint()..color = color.withOpacity(0.85);
    canvas.drawCircle(Offset(radius, radius), radius, paint);

    final border = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.06;
    canvas.drawCircle(Offset(radius, radius), radius * 0.92, border);

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.35,
          fontWeight: FontWeight.w800,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(radius - tp.width / 2, radius - tp.height / 2));

    final image = await recorder.endRecording().toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final icon = BitmapDescriptor.fromBytes(bytes);
    _cache[key] = icon;
    return icon;
  }
}
