import 'dart:math';

import 'package:control_style/control_style.dart';
import 'package:flutter/material.dart';

mixin DecorationPainter on ShapeBorder {
  ShapeBorder get child;
  List<BoxShadow> get shadow;
  List<BoxShadow> get innerShadow;
  Gradient? get backgroundGradient;
  GradientBorderSide? get borderGradient;
  bool get clipInner;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      child.getInnerPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      child.getOuterPath(rect, textDirection: textDirection);

  @override
  EdgeInsetsGeometry get dimensions => child.dimensions;

  void paintDecoration(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
  }) {
    final innerPath = getInnerPath(rect, textDirection: textDirection);

    // Draw background
    if (backgroundGradient != null) {
      final Paint backgroundPaint = Paint()
        ..shader = backgroundGradient!.createShader(rect);
      canvas.drawPath(innerPath, backgroundPaint);
    }

    // Draw inner shadow
    if (innerShadow.isNotEmpty) {
      canvas.save();
      final outerPath = getOuterPath(rect, textDirection: textDirection);
      canvas.clipPath(outerPath);

      for (final BoxShadow boxShadow in innerShadow) {
        final Paint paint = boxShadow is GradientShadow
            ? boxShadow.toPaintRect(rect, textDirection: textDirection)
            : boxShadow.toPaint();
        final Rect bounds =
            rect.shift(boxShadow.offset).deflate(boxShadow.spreadRadius);
        final outerPath = getOuterPath(bounds, textDirection: textDirection)
          ..addRect(
            bounds.inflate(
              boxShadow.blurRadius +
                  boxShadow.spreadRadius +
                  max(boxShadow.offset.dx, boxShadow.offset.dy),
            ),
          )
          ..fillType = PathFillType.evenOdd;
        canvas.drawPath(outerPath, paint);
      }
      canvas.restore();
    }

    if (shadow.isNotEmpty) {
      // Clip inner
      if (clipInner) {
        double maxSpreadDistance = 0;
        for (final BoxShadow boxShadow in shadow) {
          final curSpreadDistane = (boxShadow.blurRadius +
                  boxShadow.spreadRadius +
                  max(boxShadow.offset.dx, boxShadow.offset.dy)) *
              2;
          maxSpreadDistance = max(maxSpreadDistance, curSpreadDistane);
        }

        if (maxSpreadDistance > 0) {
          final clipPath = Path()
            // ..addRect(const Rect.fromLTWH(-1000, -1000, 2000, 2000))
            ..addRect(rect.inflate(maxSpreadDistance))
            ..addPath(innerPath, Offset.zero)
            ..fillType = PathFillType.evenOdd;
          canvas.clipPath(clipPath);
        }
      }

      // Draw shadow
      for (final BoxShadow boxShadow in shadow) {
        final Paint paint = boxShadow is GradientShadow
            ? boxShadow.toPaintRect(rect, textDirection: textDirection)
            : boxShadow.toPaint();
        final Rect bounds =
            rect.shift(boxShadow.offset).inflate(boxShadow.spreadRadius);
        canvas.drawPath(
          getOuterPath(bounds, textDirection: textDirection),
          paint,
        );
      }
    }
  }

  void paintBorder2(
    Canvas canvas,
    Rect rect,
    GradientBorderSide side, {
    TextDirection? textDirection,
  }) {
    final innerPath = getInnerPath(rect, textDirection: textDirection);
    final outerPath = getOuterPath(rect, textDirection: textDirection);

    final Path borderPath = outerPath..addPath(innerPath, Offset.zero);
    final Paint paint = side.toPaint(rect);
    canvas.drawPath(borderPath, paint);
  }
}
