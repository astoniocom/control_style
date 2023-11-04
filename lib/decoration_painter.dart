import 'dart:math';

import 'package:control_style/control_style.dart';
import 'package:flutter/material.dart';

/// Extends functionality of standard Flutter's [ShapeBorder] with additional
/// decoration.
mixin DecorationPainter on ShapeBorder {
  /// [ShapeBorder] to which additional styling should be applied.
  ShapeBorder get child;

  /// A list of shadows cast by this shape "behind" it.
  ///
  /// The shadows follow the shape of the [child].
  List<BoxShadow> get shadow;

  /// A list of shadows cast by the boundary of this figure into itself.
  ///
  /// The shadows follow the shape of the [child].
  List<BoxShadow> get innerShadow;

  /// A gradient to use when filling the shape.
  Gradient? get backgroundGradient;

  /// A gradient used when drawing the edge of this shape.
  GradientBorderSide? get borderGradient;

  /// Whether or not you should cut out the area inside the decorating shape
  /// to create the effect of placing a shadow behind the shape.
  ///
  /// The [DecorationPainter] applys stylization above the decorated shape.
  /// In case of an outer shadow, the shadow’s part above the control is clipped
  /// (if clipInner is true) to give the illusion that the shadow is behind
  /// the shape.
  ///
  /// ![Exapmle](https://github.com/astoniocom/control_style/raw/master/images/how_it_works.png)
  ///
  /// Usually it should be true.
  bool get clipInner;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      child.getInnerPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      child.getOuterPath(rect, textDirection: textDirection);

  @override
  EdgeInsetsGeometry get dimensions => child.dimensions;

  /// Paints the decoration on the given [Canvas].
  void paintDecoration(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
  }) {
    final innerPath = getInnerPath(rect, textDirection: textDirection);

    // Draw background
    if (backgroundGradient != null) {
      final backgroundPaint = Paint()
        ..shader = backgroundGradient!.createShader(rect);
      canvas.drawPath(innerPath, backgroundPaint);
    }

    // Draw inner shadow
    if (innerShadow.isNotEmpty) {
      canvas.save();
      final outerPath = getOuterPath(rect, textDirection: textDirection);
      canvas.clipPath(outerPath);

      for (final boxShadow in innerShadow) {
        final paint = boxShadow is GradientShadow
            ? boxShadow.toPaintRect(rect, textDirection: textDirection)
            : boxShadow.toPaint();
        final bounds =
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
        var maxSpreadDistance = .0;
        for (final boxShadow in shadow) {
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
      for (final boxShadow in shadow) {
        final paint = boxShadow is GradientShadow
            ? boxShadow.toPaintRect(rect, textDirection: textDirection)
            : boxShadow.toPaint();
        final bounds =
            rect.shift(boxShadow.offset).inflate(boxShadow.spreadRadius);
        canvas.drawPath(
          getOuterPath(bounds, textDirection: textDirection),
          paint,
        );
      }
    }
  }

  /// Paints an additional border on top of the existing one to add the ability
  /// to decorate this border.
  void paintBorder2(
    Canvas canvas,
    Rect rect,
    GradientBorderSide side, {
    TextDirection? textDirection,
  }) {
    final innerPath = getInnerPath(rect, textDirection: textDirection);
    final outerPath = getOuterPath(rect, textDirection: textDirection);

    final borderPath = outerPath..addPath(innerPath, Offset.zero);
    final paint = side.toPaint(rect);
    canvas.drawPath(borderPath, paint);
  }
}
