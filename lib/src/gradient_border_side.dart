import 'dart:math' as math;
import 'dart:ui' as ui show lerpDouble;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A gradient side of a border of a box.
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
  /// The arguments must not be null.
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
    return GradientBorderSide(
      gradient: Gradient.lerp(a.gradient, b.gradient, t)!,
      width: width,
    );
  }

  /// The width of this side of the border, in logical pixels.
  ///
  /// Setting width to 0.0 will result in a hairline border. This means that
  /// the border will have the width of one physical pixel. Hairline
  /// rendering takes shortcuts when the path overlaps a pixel more than once.
  /// This means that it will render faster than otherwise, but it might
  /// double-hit pixels, giving it a slightly darker/lighter result.
  ///
  /// To omit the border entirely, set the [style] to [BorderStyle.none].
  final double width;

  /// The style of this side of the border.
  ///
  /// To omit a side, set [style] to [BorderStyle.none]. This skips
  /// painting the border, but the border still has a [width].
  final BorderStyle style;

  /// A gradient to use when filling the shape.
  final Gradient gradient;

  /// Returns a new gradient border with its width and style scaled by the given
  /// factor.
  GradientBorderSide scale(double t) {
    return GradientBorderSide(
      gradient: gradient.scale(t),
      width: math.max(0, width * t),
      style: t <= 0.0 ? BorderStyle.none : style,
    );
  }

  /// A hairline transparent border that is not rendered.
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

  /// Creates a copy of this gradient border but with the given fields replaced
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

  /// Creates a [Paint] object that will draw the line in this border's style.
  Paint toPaint(Rect rect) {
    final similarBorderSide = BorderSide(width: width, style: style);
    final paint = similarBorderSide.toPaint()
      ..shader = gradient.createShader(rect);
    return paint;
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
