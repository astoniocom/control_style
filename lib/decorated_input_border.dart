import 'package:control_style/control_style.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@immutable
class DecoratedInputBorder extends InputBorder with DecorationPainter {
  DecoratedInputBorder({
    required InputBorder child,
    this.shadow = const [],
    this.innerShadow = const [],
    this.backgroundGradient,
    this.borderGradient = GradientBorderSide.none,
    bool? isOutline,
    this.clipInner = true,
  })  : isOutline = isOutline ?? child.isOutline,
        child =
            child.copyWith(borderSide: borderGradient == GradientBorderSide.none ? null : BorderSide(width: borderGradient.width, color: Colors.transparent)),
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
      final result = child.lerpFrom(a.child, t);
      if (result is InputBorder) {
        return DecoratedInputBorder(
          child: result,
          shadow: GradientShadow.lerpList(a.shadow, shadow, t)!,
          innerShadow: GradientShadow.lerpList(a.innerShadow, innerShadow, t)!,
          backgroundGradient: Gradient.lerp(a.backgroundGradient, backgroundGradient, t),
          borderGradient: GradientBorderSide.lerp(a.borderGradient, borderGradient, t),
          clipInner: clipInner,
        );
      }
    }

    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is DecoratedInputBorder) {
      final result = child.lerpTo(b.child, t);
      if (result is InputBorder) {
        return DecoratedInputBorder(
          child: result,
          shadow: GradientShadow.lerpList(shadow, b.shadow, t)!,
          innerShadow: GradientShadow.lerpList(innerShadow, b.innerShadow, t)!,
          backgroundGradient: Gradient.lerp(backgroundGradient, b.backgroundGradient, t),
          borderGradient: GradientBorderSide.lerp(borderGradient, b.borderGradient, t),
          clipInner: clipInner,
        );
      }
    }

    return super.lerpTo(b, t);
  }

  @override
  InputBorder copyWith({
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
  ShapeBorder scale(double t) {
    final scalledChild = child.scale(t);

    return DecoratedInputBorder(
        child: scalledChild is InputBorder ? scalledChild : child,
        shadow: GradientShadow.lerpList(null, shadow, t)!,
        innerShadow: GradientShadow.lerpList(null, innerShadow, t)!,
        isOutline: isOutline,
        backgroundGradient: backgroundGradient?.scale(t),
        borderGradient: borderGradient.scale(t),
        clipInner: clipInner);
  }

  @override
  void paint(Canvas canvas, Rect rect, {double? gapStart, double gapExtent = 0.0, double gapPercentage = 0.0, TextDirection? textDirection}) {
    paintDecoration(canvas, rect, textDirection: textDirection);

    child.paint(canvas, rect, textDirection: textDirection, gapStart: gapStart, gapExtent: gapExtent, gapPercentage: gapPercentage);

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
  int get hashCode =>
      Object.hash(borderSide, child, Object.hashAll(shadow), Object.hashAll(innerShadow), isOutline, backgroundGradient, borderGradient, clipInner);

  @override
  String toString() {
    return '${objectRuntimeType(this, 'DecoratedInputBorder')}($borderSide, $shadow, $innerShadow, $child, $isOutline, $backgroundGradient, $borderGradient, $clipInner)';
  }
}
