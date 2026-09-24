import 'package:control_style/src/decoration_painter.dart';
import 'package:control_style/src/gradient_border_side.dart';
import 'package:control_style/src/gradient_shadow.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Applies additional decoration to the [InputBorder].
///
/// To decorate [InputBorder], the code:
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     inputDecorationTheme: InputDecorationTheme(
///       border: OutlineInputBorder(
///         borderRadius: BorderRadius.circular(8),
///       ),
///     ),
///   ),
/// );
/// ```
///
/// should be updated to:
///
/// ```dart
/// MaterialApp(
///    theme: ThemeData(
///      inputDecorationTheme: InputDecorationTheme(
///        border: DecoratedInputBorder(
///          shadow: const [
///            BoxShadow(
///              color: Colors.blue,
///              blurRadius: 12,
///            )
///          ],
///          child: OutlineInputBorder(
///            borderRadius: BorderRadius.circular(8),
///          ),
///        ),
///      ),
///    ),
/// ```
@immutable
class DecoratedInputBorder extends InputBorder with DecorationPainter {
  /// Creates a border for an [InputDecorator] by extending the functionality of
  /// [InputBorder].
  ///
  /// The [child] parameter is [InputBorder] for the extension.
  DecoratedInputBorder({
    required InputBorder child,
    this.shadow = const [],
    this.innerShadow = const [],
    this.backgroundGradient,
    this.borderGradient = GradientBorderSide.none,
    bool? isOutline,
    this.clipInner = true,
  })  : isOutline = isOutline ?? child.isOutline,
        child = child.copyWith(
          borderSide: borderGradient.isNone
              ? null
              : BorderSide(
                  width: borderGradient.width,
                  color: Colors.transparent,
                ),
        ),
        super(borderSide: child.borderSide);

  @override
  final InputBorder child;

  @override
  final List<BoxShadow> shadow;

  @override
  final List<BoxShadow> innerShadow;

  @override
  final Gradient? backgroundGradient;

  @override
  final GradientBorderSide borderGradient;

  @override
  final bool isOutline;

  @override
  final bool clipInner;

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is DecoratedInputBorder) {
      return _lerp(a.child, a, child, this, t);
    }
    if (a is InputBorder) {
      // Interpolate from a plain border as if it had no decoration.
      return _lerp(a, null, child, this, t);
    }

    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is DecoratedInputBorder) {
      return _lerp(child, this, b.child, b, t);
    }
    if (b is InputBorder) {
      // Interpolate to a plain border as if it had no decoration.
      return _lerp(child, this, b, null, t);
    }

    return super.lerpTo(b, t);
  }

  /// Interpolates between the borders [childA] and [childB] together with the
  /// decorations of [a] and [b].
  ///
  /// A null [a] or [b] stands for the absence of decoration. The result takes
  /// [isOutline] and [clipInner] from `this`.
  DecoratedInputBorder? _lerp(
    InputBorder childA,
    DecoratedInputBorder? a,
    InputBorder childB,
    DecoratedInputBorder? b,
    double t,
  ) {
    final result = ShapeBorder.lerp(childA, childB, t);
    if (result is! InputBorder) return null;

    return DecoratedInputBorder(
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
      isOutline: isOutline,
      clipInner: clipInner,
    );
  }

  @override
  DecoratedInputBorder copyWith({
    BorderSide? borderSide,
    InputBorder? child,
    List<BoxShadow>? shadow,
    List<BoxShadow>? innerShadow,
    bool? isOutline,
    Gradient? backgroundGradient,
    GradientBorderSide? borderGradient,
    bool? clipInner,
  }) {
    return DecoratedInputBorder(
      child: (child ?? this.child).copyWith(borderSide: borderSide),
      shadow: shadow ?? this.shadow,
      innerShadow: innerShadow ?? this.innerShadow,
      isOutline: isOutline ?? this.isOutline,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      borderGradient: borderGradient ?? this.borderGradient,
      clipInner: clipInner ?? this.clipInner,
    );
  }

  @override
  DecoratedInputBorder scale(double t) {
    final scalledChild = child.scale(t);

    return DecoratedInputBorder(
      child: scalledChild is InputBorder ? scalledChild : child,
      shadow: GradientShadow.lerpList(null, shadow, t)!,
      innerShadow: GradientShadow.lerpList(null, innerShadow, t)!,
      isOutline: isOutline,
      backgroundGradient: backgroundGradient?.scale(t),
      borderGradient: borderGradient.scale(t),
      clipInner: clipInner,
    );
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    paintDecoration(canvas, rect, textDirection: textDirection);

    child.paint(
      canvas,
      rect,
      textDirection: textDirection,
      gapStart: gapStart,
      gapExtent: gapExtent,
      gapPercentage: gapPercentage,
    );

    paintBorder2(canvas, rect, borderGradient, textDirection: textDirection);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is DecoratedInputBorder &&
        other.borderSide == borderSide &&
        other.child == child &&
        listEquals<BoxShadow>(other.shadow, shadow) &&
        listEquals<BoxShadow>(other.innerShadow, innerShadow) &&
        other.isOutline == isOutline &&
        other.backgroundGradient == backgroundGradient &&
        other.borderGradient == borderGradient &&
        other.clipInner == clipInner;
  }

  @override
  int get hashCode => Object.hash(
        borderSide,
        child,
        Object.hashAll(shadow),
        Object.hashAll(innerShadow),
        isOutline,
        backgroundGradient,
        borderGradient,
        clipInner,
      );

  @override
  String toString() {
    return '${objectRuntimeType(this, 'DecoratedInputBorder')}($borderSide, '
        '$shadow, $innerShadow, $child, $isOutline, $backgroundGradient, '
        '$borderGradient, $clipInner)';
  }
}
