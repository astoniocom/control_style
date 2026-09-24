import 'dart:math' as math;
import 'dart:ui' as ui show lerpDouble;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A shadow cast by a box that is filled with a [gradient] instead of a single
/// color.
///
/// Differs from [BoxShadow] only in that the shadow is painted with the
/// [gradient]; the inherited [color] is not used for painting and only takes
/// part in interpolation with plain [BoxShadow]s.
@immutable
class GradientShadow extends BoxShadow {
  /// Creates a gradient box shadow.
  ///
  /// By default, the shadow has zero [offset], zero [blurRadius], zero
  /// [spreadRadius] and [BlurStyle.normal], which paints the [gradient]
  /// exactly along the outline of the box.
  const GradientShadow({
    required this.gradient,
    Color color = Colors.transparent,
    Offset offset = Offset.zero,
    double blurRadius = 0.0,
    double spreadRadius = 0.0,
    BlurStyle blurStyle = BlurStyle.normal,
  }) : super(
          color: color,
          offset: offset,
          blurRadius: blurRadius,
          spreadRadius: spreadRadius,
          blurStyle: blurStyle,
        );

  /// Creates a gradient shadow that looks like the given plain [shadow], using
  /// a solid gradient of the shadow's color.
  ///
  /// If [shadow] already is a [GradientShadow], it is returned as is.
  factory GradientShadow.fromBoxShadow(BoxShadow shadow) {
    if (shadow is GradientShadow) return shadow;
    return GradientShadow(
      gradient: LinearGradient(colors: [shadow.color, shadow.color]),
      color: shadow.color,
      offset: shadow.offset,
      blurRadius: shadow.blurRadius,
      spreadRadius: shadow.spreadRadius,
      blurStyle: shadow.blurStyle,
    );
  }

  /// A gradient to use when drawing the shadow.
  final Gradient gradient;

  /// Creates the [Paint] object that corresponds to this shadow description.
  ///
  /// Unlike [toPaint], this needs the [rect] the [gradient] is laid out in and,
  /// for gradients that use [AlignmentDirectional], the [textDirection].
  ///
  /// As with [toPaint], the [offset] and [spreadRadius] are not represented in
  /// the [Paint]; the caller has to inflate and shift the shape accordingly.
  Paint toPaintRect(Rect rect, {TextDirection? textDirection}) {
    final result = Paint()
      ..color = const Color(0xFF000000)
      ..maskFilter = MaskFilter.blur(blurStyle, blurSigma)
      ..shader = gradient.createShader(rect, textDirection: textDirection);

    assert(
      () {
        if (debugDisableShadows) result.maskFilter = null;
        return true;
      }(),
      'For debugging purposes',
    );
    return result;
  }

  /// Returns a new gradient shadow with its offset, blurRadius, and
  /// spreadRadius scaled by the given factor.
  ///
  /// The [gradient] is preserved as is.
  @override
  GradientShadow scale(double factor) {
    return GradientShadow(
      gradient: gradient,
      color: color,
      offset: offset * factor,
      blurRadius: blurRadius * factor,
      spreadRadius: spreadRadius * factor,
      blurStyle: blurStyle,
    );
  }

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  @override
  GradientShadow copyWith({
    Gradient? gradient,
    Color? color,
    Offset? offset,
    double? blurRadius,
    double? spreadRadius,
    BlurStyle? blurStyle,
  }) {
    return GradientShadow(
      gradient: gradient ?? this.gradient,
      color: color ?? this.color,
      offset: offset ?? this.offset,
      blurRadius: blurRadius ?? this.blurRadius,
      spreadRadius: spreadRadius ?? this.spreadRadius,
      blurStyle: blurStyle ?? this.blurStyle,
    );
  }

  /// Linearly interpolate between two shadows.
  ///
  /// If both shadows are plain [BoxShadow]s, this is [BoxShadow.lerp]. If at
  /// least one of them is a [GradientShadow], the other one is treated as a
  /// [GradientShadow] with a solid gradient of its color, so that the gradient
  /// fades in or out instead of disappearing abruptly.
  ///
  /// If either shadow is null, the other one is scaled towards nothing.
  static BoxShadow? lerp(BoxShadow? a, BoxShadow? b, double t) {
    if (identical(a, b)) {
      return a;
    }
    if (a == null) return b!.scale(t);
    if (b == null) return a.scale(1.0 - t);

    if (a is! GradientShadow && b is! GradientShadow) {
      return BoxShadow.lerp(a, b, t);
    }

    final gradientA = GradientShadow.fromBoxShadow(a);
    final gradientB = GradientShadow.fromBoxShadow(b);
    return GradientShadow(
      color: Color.lerp(a.color, b.color, t)!,
      gradient: Gradient.lerp(gradientA.gradient, gradientB.gradient, t)!,
      offset: Offset.lerp(a.offset, b.offset, t)!,
      blurRadius: ui.lerpDouble(a.blurRadius, b.blurRadius, t)!,
      spreadRadius: ui.lerpDouble(a.spreadRadius, b.spreadRadius, t)!,
      blurStyle: a.blurStyle == BlurStyle.normal ? b.blurStyle : a.blurStyle,
    );
  }


  /// Linearly interpolate between two lists of box shadows.
  ///
  /// If the lists differ in length, excess items are lerped with null.
  static List<BoxShadow>? lerpList(
    List<BoxShadow>? a,
    List<BoxShadow>? b,
    double t,
  ) {
    if (identical(a, b)) {
      return a;
    }
    a ??= <BoxShadow>[]; // ignore: parameter_assignments
    b ??= <BoxShadow>[]; // ignore: parameter_assignments
    final int commonLength = math.min(a.length, b.length);
    return <BoxShadow>[
      for (int i = 0; i < commonLength; i += 1)
        GradientShadow.lerp(a[i], b[i], t)!,
      for (int i = commonLength; i < a.length; i += 1) a[i].scale(1.0 - t),
      for (int i = commonLength; i < b.length; i += 1) b[i].scale(t),
    ];
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is GradientShadow &&
        other.color == color &&
        other.gradient == gradient &&
        other.offset == offset &&
        other.blurRadius == blurRadius &&
        other.spreadRadius == spreadRadius &&
        other.blurStyle == blurStyle;
  }

  @override
  int get hashCode =>
      Object.hash(color, offset, blurRadius, spreadRadius, blurStyle, gradient);

  @override
  String toString() =>
      'GradientShadow($color, $offset, ${debugFormatDouble(blurRadius)}, '
      '${debugFormatDouble(spreadRadius)}, $blurStyle, $gradient)';
}
