import 'dart:math' as math;
import 'dart:ui' as ui show lerpDouble;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A side of a border of a box that is painted with a [gradient] instead of a
/// single color.
///
/// The counterpart of [BorderSide] for `DecorationPainter.borderGradient`.
/// Use [none] to switch the gradient side off.
@immutable
class GradientBorderSide {
  /// Creates the gradient side of a border.
  ///
  /// By default, the border is 1.0 logical pixels wide, solid and painted
  /// inside the shape.
  const GradientBorderSide({
    required this.gradient,
    this.width = 1.0,
    this.style = BorderStyle.solid,
    this.strokeAlign = strokeAlignInside,
  });

  /// Linearly interpolate between two gradient border sides.
  ///
  /// If the sides differ in [style], the side with [BorderStyle.none] is
  /// treated as a solid side with a fully transparent gradient, so the visible
  /// side fades in or out instead of switching abruptly. This mirrors
  /// [BorderSide.lerp].
  factory GradientBorderSide.lerp(
    GradientBorderSide a,
    GradientBorderSide b,
    double t,
  ) {
    if (identical(a, b)) {
      return a;
    }
    if (t == 0.0) return a;
    if (t == 1.0) return b;
    final width = ui.lerpDouble(a.width, b.width, t)!;
    if (width < 0.0) return GradientBorderSide.none;
    final strokeAlign = ui.lerpDouble(a.strokeAlign, b.strokeAlign, t)!;
    if (a.style == b.style) {
      return GradientBorderSide(
        gradient: Gradient.lerp(a.gradient, b.gradient, t)!,
        width: width,
        style: a.style, // == b.style
        strokeAlign: strokeAlign,
      );
    }
    final gradientA = a.isNone ? a.gradient.scale(0) : a.gradient;
    final gradientB = b.isNone ? b.gradient.scale(0) : b.gradient;
    return GradientBorderSide(
      gradient: Gradient.lerp(gradientA, gradientB, t)!,
      width: width,
      strokeAlign: strokeAlign,
    );
  }

  /// The width of this side of the border, in logical pixels.
  ///
  /// The side is painted as a band exactly this wide along the edge of the
  /// shape; [strokeAlign] controls how much of it lies inside the shape. The
  /// decorated shape's own side takes this width, so the width also affects
  /// the shape's [ShapeBorder.dimensions].
  ///
  /// Unlike [BorderSide.width], a width of 0.0 does not produce a hairline;
  /// nothing is painted. To omit the border entirely, set the [style] to
  /// [BorderStyle.none].
  final double width;

  /// The style of this side of the border.
  ///
  /// To omit a side, set [style] to [BorderStyle.none]. This skips painting
  /// the gradient and leaves the decorated shape's own side untouched.
  final BorderStyle style;

  /// A gradient to use when painting this side.
  final Gradient gradient;

  /// The relative position of the band of this side to the edge of the shape.
  ///
  /// Same semantics as [BorderSide.strokeAlign]: [strokeAlignInside] (-1.0,
  /// the default) keeps the whole [width] inside the shape,
  /// [strokeAlignCenter] (0.0) centers it on the edge, [strokeAlignOutside]
  /// (1.0) puts it entirely outside. Values in between are allowed.
  ///
  /// The decorated shape's own side takes this alignment together with the
  /// [width], so [ShapeBorder.dimensions] and [ShapeBorder.getInnerPath]
  /// follow it the same way they do for a plain [BorderSide]. The band is
  /// painted between [ShapeBorder.getInnerPath] of the shape's rect and
  /// [ShapeBorder.getOuterPath] of that rect inflated by [strokeOutset].
  ///
  /// Two limitations compared to a stroked [BorderSide]:
  ///
  /// * Shapes that ignore [BorderSide.strokeAlign], such as
  ///   [UnderlineInputBorder], also do not restrict where the outside part of
  ///   the band is painted. Keep the default for them.
  /// * For rounded shapes the outside part is not concentric with the edge
  ///   (the corner radius does not grow with [strokeOutset]), so the band is
  ///   slightly wider at the corners.
  final double strokeAlign;

  /// The border is drawn fully inside of the border path.
  ///
  /// This is the default and is the same as [BorderSide.strokeAlignInside].
  static const double strokeAlignInside = BorderSide.strokeAlignInside;

  /// The border is drawn on the center of the border path, with half of the
  /// [width] on the inside, and the other half on the outside of the path.
  ///
  /// Same as [BorderSide.strokeAlignCenter].
  static const double strokeAlignCenter = BorderSide.strokeAlignCenter;

  /// The border is drawn on the outside of the border path.
  ///
  /// Same as [BorderSide.strokeAlignOutside].
  static const double strokeAlignOutside = BorderSide.strokeAlignOutside;

  /// Get the amount of the stroke width that lies inside of the shape.
  ///
  /// For example, this will return the [width] for a [strokeAlign] of -1, half
  /// the [width] for a [strokeAlign] of 0, and 0 for a [strokeAlign] of 1.
  double get strokeInset => width * (1 - (1 + strokeAlign) / 2);

  /// Get the amount of the stroke width that lies outside of the shape.
  ///
  /// For example, this will return 0 for a [strokeAlign] of -1, half the
  /// [width] for a [strokeAlign] of 0, and the [width] for a [strokeAlign] of
  /// 1.
  double get strokeOutset => width * (1 + strokeAlign) / 2;

  /// Whether this side is not painted, i.e. its [style] is [BorderStyle.none].
  ///
  /// Unlike comparing against [none], this also covers sides that have a
  /// non-zero [width] or a custom [gradient] but are switched off via [style].
  bool get isNone => style == BorderStyle.none;

  /// Returns a new gradient side with its [width] and [gradient] scaled by the
  /// given factor.
  ///
  /// A factor of 0.0 or less switches the side off via [style]. The
  /// [strokeAlign] is kept.
  GradientBorderSide scale(double t) {
    return GradientBorderSide(
      gradient: gradient.scale(t),
      width: math.max(0, width * t),
      style: t <= 0.0 ? BorderStyle.none : style,
      strokeAlign: strokeAlign,
    );
  }

  /// A zero-width transparent side that is not painted.
  ///
  /// This is the default for `DecorationPainter.borderGradient`.
  static const GradientBorderSide none = GradientBorderSide(
    width: 0,
    style: BorderStyle.none,
    gradient: LinearGradient(
      colors: [
        Colors.transparent,
        Colors.transparent,
      ],
    ),
  );

  /// Creates a copy of this gradient side but with the given fields replaced
  /// with the new values.
  GradientBorderSide copyWith({
    Gradient? gradient,
    double? width,
    BorderStyle? style,
    double? strokeAlign,
  }) {
    return GradientBorderSide(
      gradient: gradient ?? this.gradient,
      width: width ?? this.width,
      style: style ?? this.style,
      strokeAlign: strokeAlign ?? this.strokeAlign,
    );
  }

  /// Creates a [Paint] object that fills the area of this side with the
  /// [gradient].
  ///
  /// Unlike [BorderSide.toPaint], the returned paint uses
  /// [PaintingStyle.fill]: the side is painted as the area between the outer
  /// and the inner path of the shape, not as a stroke along a path. The
  /// [width] is therefore not represented in the [Paint].
  ///
  /// The [rect] is the area the [gradient] is laid out in. The [textDirection]
  /// is required for gradients that use [AlignmentDirectional].
  ///
  /// If [style] is [BorderStyle.none], the paint is fully transparent.
  Paint toPaint(Rect rect, {TextDirection? textDirection}) {
    switch (style) {
      case BorderStyle.solid:
        return Paint()
          ..style = PaintingStyle.fill
          ..shader = gradient.createShader(rect, textDirection: textDirection);
      case BorderStyle.none:
        return Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(0x00000000);
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is GradientBorderSide &&
        other.width == width &&
        other.style == style &&
        other.gradient == gradient &&
        other.strokeAlign == strokeAlign;
  }

  @override
  int get hashCode => Object.hash(gradient, width, style, strokeAlign);

  @override
  String toString() => '${objectRuntimeType(this, 'GradientBorderSide')}('
      '${width.toStringAsFixed(1)}, $style, $gradient, '
      'strokeAlign: ${strokeAlign.toStringAsFixed(1)})';
}
