import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui show lerpDouble;

@immutable
class GradientBorderSide {
  const GradientBorderSide({
    this.width = 1.0,
    this.style = BorderStyle.solid,
    required this.gradient,
  });

  final double width;
  final BorderStyle style;
  final Gradient gradient;

  GradientBorderSide scale(double t) {
    return GradientBorderSide(
      gradient: gradient.scale(t),
      width: math.max(0.0, width * t),
      style: t <= 0.0 ? BorderStyle.none : style,
    );
  }

  static const GradientBorderSide none =
      GradientBorderSide(width: 0.0, style: BorderStyle.none, gradient: LinearGradient(colors: [Colors.transparent, Colors.transparent]));

  GradientBorderSide copyWith({
    Gradient? gradient,
    double? width,
    BorderStyle? style,
  }) {
    assert(width == null || width >= 0.0);
    return GradientBorderSide(
      gradient: gradient ?? this.gradient,
      width: width ?? this.width,
      style: style ?? this.style,
    );
  }

  Paint toPaint(Rect rect) {
    final similarBorderSide = BorderSide(width: width, color: Colors.black, style: style);
    final paint = similarBorderSide.toPaint();
    paint.shader = gradient.createShader(rect);
    return paint;
  }

  static GradientBorderSide lerp(GradientBorderSide a, GradientBorderSide b, double t) {
    if (t == 0.0) return a;
    if (t == 1.0) return b;
    final double width = ui.lerpDouble(a.width, b.width, t)!;
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is GradientBorderSide && other.width == width && other.style == style && other.gradient == gradient;
  }

  @override
  int get hashCode => hashValues(gradient, width, style);

  @override
  String toString() => '${objectRuntimeType(this, 'GradientBorderSide')}(${width.toStringAsFixed(1)}, $style, $gradient)';
}
