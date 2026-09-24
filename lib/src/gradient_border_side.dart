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
  /// By default, the border is 1.0 logical pixels wide and solid.
  const GradientBorderSide({
    required this.gradient,
    this.width = 1.0,
    this.style = BorderStyle.solid,
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
    if (a.style == b.style) {
      return GradientBorderSide(
        gradient: Gradient.lerp(a.gradient, b.gradient, t)!,
        width: width,
        style: a.style, // == b.style
      );
    }
    final gradientA = a.isNone ? a.gradient.scale(0) : a.gradient;
    final gradientB = b.isNone ? b.gradient.scale(0) : b.gradient;
    return GradientBorderSide(
      gradient: Gradient.lerp(gradientA, gradientB, t)!,
      width: width,
    );
  }

  /// The width of this side of the border, in logical pixels.
  ///
  /// The side is painted inside the shape, between its outer edge and the
  /// edge inset by [width]. The decorated shape's own side takes this width,
  /// so the width also affects the shape's [ShapeBorder.dimensions].
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

  /// Whether this side is not painted, i.e. its [style] is [BorderStyle.none].
  ///
  /// Unlike comparing against [none], this also covers sides that have a
  /// non-zero [width] or a custom [gradient] but are switched off via [style].
  bool get isNone => style == BorderStyle.none;

  /// Returns a new gradient side with its [width] and [gradient] scaled by the
  /// given factor.
  ///
  /// A factor of 0.0 or less switches the side off via [style].
  GradientBorderSide scale(double t) {
    return GradientBorderSide(
      gradient: gradient.scale(t),
      width: math.max(0, width * t),
      style: t <= 0.0 ? BorderStyle.none : style,
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
  }) {
    return GradientBorderSide(
      gradient: gradient ?? this.gradient,
      width: width ?? this.width,
      style: style ?? this.style,
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
        other.gradient == gradient;
  }

  @override
  int get hashCode => Object.hash(gradient, width, style);

  @override
  String toString() => '${objectRuntimeType(this, 'GradientBorderSide')}('
      '${width.toStringAsFixed(1)}, $style, $gradient)';
}
