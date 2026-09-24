import 'package:control_style/src/decoration_painter.dart';
import 'package:control_style/src/gradient_border_side.dart';
import 'package:control_style/src/gradient_shadow.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Applies additional decoration to the [OutlinedBorder].
///
/// To decorate [OutlinedBorder], the code:
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     primarySwatch: Colors.blue,
///     outlinedButtonTheme: OutlinedButtonThemeData(
///         style: ElevatedButton.styleFrom(
///       shape: RoundedRectangleBorder(
///         borderRadius: BorderRadius.circular(8),
///       ),
///     )),
///   ),
/// );
/// ```
///
/// should be updated to:
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     primarySwatch: Colors.blue,
///     outlinedButtonTheme: OutlinedButtonThemeData(
///         style: ElevatedButton.styleFrom(
///       shape: DecoratedOutlinedBorder(
///         shadow: const [
///           BoxShadow(
///             color: Colors.blue,
///             blurRadius: 12,
///           )
///         ],
///         child: RoundedRectangleBorder(
///           borderRadius: BorderRadius.circular(8),
///         ),
///       ),
///     )),
///   ),
/// );
/// ```
@immutable
class DecoratedOutlinedBorder extends OutlinedBorder with DecorationPainter {
  /// Creates [OutlinedBorder] with additional decoration.
  ///
  /// The [child] parameter is the [OutlinedBorder] for the extension.
  DecoratedOutlinedBorder({
    required OutlinedBorder child,
    this.shadow = const [],
    this.innerShadow = const [],
    this.backgroundGradient,
    this.borderGradient = GradientBorderSide.none,
  })  : child = child.copyWith(
          side: borderGradient.isNone
              ? null
              : BorderSide(
                  width: borderGradient.width,
                  color: Colors.transparent,
                ),
        ),
        super(side: child.side);

  @override
  final OutlinedBorder child;

  @override
  final List<BoxShadow> shadow;

  @override
  final List<BoxShadow> innerShadow;

  @override
  final Gradient? backgroundGradient;

  @override
  final GradientBorderSide borderGradient;

  @override
  final bool clipInner = true;

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is DecoratedOutlinedBorder) {
      return _lerp(a.child, a, child, this, t);
    }
    if (a is OutlinedBorder) {
      // Interpolate from a plain border as if it had no decoration.
      return _lerp(a, null, child, this, t);
    }

    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is DecoratedOutlinedBorder) {
      return _lerp(child, this, b.child, b, t);
    }
    if (b is OutlinedBorder) {
      // Interpolate to a plain border as if it had no decoration.
      return _lerp(child, this, b, null, t);
    }

    return super.lerpTo(b, t);
  }

  /// Interpolates between the borders [childA] and [childB] together with the
  /// decorations of [a] and [b].
  ///
  /// A null [a] or [b] stands for the absence of decoration.
  static DecoratedOutlinedBorder? _lerp(
    OutlinedBorder childA,
    DecoratedOutlinedBorder? a,
    OutlinedBorder childB,
    DecoratedOutlinedBorder? b,
    double t,
  ) {
    final result = OutlinedBorder.lerp(childA, childB, t);
    if (result == null) return null;

    return DecoratedOutlinedBorder(
      child: result,
      shadow: GradientShadow.lerpList(a?.shadow, b?.shadow, t)!,
      innerShadow: GradientShadow.lerpList(a?.innerShadow, b?.innerShadow, t)!,
      backgroundGradient:
          Gradient.lerp(a?.backgroundGradient, b?.backgroundGradient, t),
      borderGradient: GradientBorderSide.lerp(
        a?.borderGradient ?? GradientBorderSide.none,
        b?.borderGradient ?? GradientBorderSide.none,
        t,
      ),
    );
  }

  @override
  DecoratedOutlinedBorder copyWith({
    BorderSide? side,
    OutlinedBorder? child,
    List<BoxShadow>? shadow,
    List<BoxShadow>? innerShadow,
    Gradient? backgroundGradient,
    GradientBorderSide? borderGradient,
  }) {
    return DecoratedOutlinedBorder(
      child: (child ?? this.child).copyWith(side: side),
      shadow: shadow ?? this.shadow,
      innerShadow: innerShadow ?? this.innerShadow,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      borderGradient: borderGradient ?? this.borderGradient,
    );
  }

  @override
  DecoratedOutlinedBorder scale(double t) {
    final scalledChild = child.scale(t);
    return DecoratedOutlinedBorder(
      child: scalledChild is OutlinedBorder ? scalledChild : child,
      shadow: GradientShadow.lerpList(null, shadow, t)!,
      innerShadow: GradientShadow.lerpList(null, innerShadow, t)!,
      backgroundGradient: backgroundGradient?.scale(t),
      borderGradient: borderGradient.scale(t),
    );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    paintDecoration(canvas, rect, textDirection: textDirection);

    child.paint(canvas, rect, textDirection: textDirection);

    paintBorder2(canvas, rect, borderGradient, textDirection: textDirection);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is DecoratedOutlinedBorder &&
        other.side == side &&
        other.child == child &&
        listEquals<BoxShadow>(other.shadow, shadow) &&
        listEquals<BoxShadow>(other.innerShadow, innerShadow) &&
        other.backgroundGradient == backgroundGradient &&
        other.borderGradient == borderGradient;
  }

  @override
  int get hashCode => Object.hash(
        side,
        child,
        Object.hashAll(shadow),
        Object.hashAll(innerShadow),
        backgroundGradient,
        borderGradient,
      );

  @override
  String toString() {
    return '${objectRuntimeType(this, 'DecoratedOutlinedBorder')}($side, '
        '$shadow, $innerShadow, $child, $backgroundGradient, $borderGradient)';
  }
}
