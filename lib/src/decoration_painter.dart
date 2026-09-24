import 'dart:math';

import 'package:control_style/src/gradient_border_side.dart';
import 'package:control_style/src/gradient_shadow.dart';
import 'package:flutter/material.dart';

/// Extends functionality of standard Flutter's [ShapeBorder] with additional
/// decoration.
mixin DecorationPainter on ShapeBorder {
  /// [ShapeBorder] to which additional styling should be applied.
  ShapeBorder get child;

  /// A list of shadows cast by this shape behind itself.
  ///
  /// The shadows follow the outline of the [child]. Use [GradientShadow] for
  /// a gradient shadow and plain [BoxShadow] for a single-color one.
  List<BoxShadow> get shadow;

  /// A list of shadows cast by the edge of this shape into its interior.
  ///
  /// The shadows follow the outline of the [child]. Use [GradientShadow] for
  /// a gradient shadow and plain [BoxShadow] for a single-color one.
  List<BoxShadow> get innerShadow;

  /// A gradient to use when filling the interior of the shape.
  Gradient? get backgroundGradient;

  /// A gradient side used when drawing the edge of this shape.
  ///
  /// Use [GradientBorderSide.none] for no gradient side; the value is never
  /// null.
  ///
  /// When set to anything other than [GradientBorderSide.none], it replaces
  /// the side of the [child]: the child's own side is made transparent and
  /// its width is set to the width of the gradient side, so the child's
  /// color, width and stroke alignment are ignored. Use a solid gradient
  /// (two identical colors) to draw a single-color side through the same
  /// mechanism.
  GradientBorderSide get borderGradient;

  /// Whether to cut out the area inside the shape when painting the outer
  /// [shadow], creating the effect of the shadow being cast behind the shape.
  ///
  /// The [DecorationPainter] applies its decoration on top of the layer that
  /// contains the decorated shape. Without clipping, an outer shadow would
  /// also cover the interior of the control.
  ///
  /// ![Example](https://github.com/astoniocom/control_style/raw/master/images/how_it_works.png)
  ///
  /// Usually this should be true.
  bool get clipInner;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      child.getInnerPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      child.getOuterPath(rect, textDirection: textDirection);

  @override
  EdgeInsetsGeometry get dimensions => child.dimensions;

  /// Paints the [backgroundGradient], [innerShadow] and [shadow] on the given
  /// [Canvas].
  ///
  /// This is meant to be called before painting the [child] itself, so the
  /// decoration ends up behind the child's outline.
  void paintDecoration(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
  }) {
    final innerPath = getInnerPath(rect, textDirection: textDirection);

    // Draw background
    if (backgroundGradient != null) {
      final backgroundPaint = Paint()
        ..shader = backgroundGradient!.createShader(
          rect,
          textDirection: textDirection,
        );
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
          ..addRect(bounds.inflate(_shadowExtent(boxShadow)))
          ..fillType = PathFillType.evenOdd;
        canvas.drawPath(outerPath, paint);
      }
      canvas.restore();
    }

    if (shadow.isNotEmpty) {
      canvas.save();

      // Clip inner
      if (clipInner) {
        var maxSpreadDistance = .0;
        for (final boxShadow in shadow) {
          maxSpreadDistance =
              max(maxSpreadDistance, _shadowExtent(boxShadow) * 2);
        }

        final clipPath = Path()
          ..addRect(rect.inflate(maxSpreadDistance))
          ..addPath(innerPath, Offset.zero)
          ..fillType = PathFillType.evenOdd;
        canvas.clipPath(clipPath);
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

      canvas.restore();
    }
  }

  /// The distance the [boxShadow] may reach beyond the edge of the shape it is
  /// cast by, in any direction.
  static double _shadowExtent(BoxShadow boxShadow) {
    return boxShadow.blurRadius +
        boxShadow.spreadRadius +
        max(boxShadow.offset.dx.abs(), boxShadow.offset.dy.abs());
  }

  /// Paints the gradient [side] along the edge of the shape, between the paths
  /// returned by [getOuterPath] and [getInnerPath].
  ///
  /// This is meant to be called after painting the [child], so the gradient
  /// covers the child's (transparent) side. Does nothing if [side] is
  /// switched off, see [GradientBorderSide.isNone].
  void paintGradientBorder(
    Canvas canvas,
    Rect rect,
    GradientBorderSide side, {
    TextDirection? textDirection,
  }) {
    if (side.isNone) return;

    final innerPath = getInnerPath(rect, textDirection: textDirection);
    final outerPath = getOuterPath(rect, textDirection: textDirection);

    final borderPath = outerPath..addPath(innerPath, Offset.zero);
    final paint = side.toPaint(rect, textDirection: textDirection);
    canvas.drawPath(borderPath, paint);
  }
}
