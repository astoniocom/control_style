import 'package:control_style/control_style.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@immutable
class DecoratedOutlinedBorder extends OutlinedBorder with DecorationPainter {
  DecoratedOutlinedBorder({
    required OutlinedBorder child,
    this.shadow = const [],
    this.innerShadow = const [],
    this.backgroundGradient,
    this.borderGradient = GradientBorderSide.none,
  })  : child = child.copyWith(side: borderGradient == GradientBorderSide.none ? null : BorderSide(width: borderGradient.width, color: Colors.transparent)),
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
      final result = child.lerpFrom(a.child, t);
      if (result is OutlinedBorder) {
        return DecoratedOutlinedBorder(
          child: result,
          shadow: GradientShadow.lerpList(a.shadow, shadow, t)!,
          innerShadow: GradientShadow.lerpList(a.innerShadow, innerShadow, t)!,
          backgroundGradient: Gradient.lerp(a.backgroundGradient, backgroundGradient, t),
          borderGradient: GradientBorderSide.lerp(a.borderGradient, borderGradient, t),
        );
      }
    }

    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is DecoratedOutlinedBorder) {
      final result = child.lerpTo(b.child, t);
      if (result is OutlinedBorder) {
        return DecoratedOutlinedBorder(
          child: result,
          shadow: GradientShadow.lerpList(shadow, b.shadow, t)!,
          innerShadow: GradientShadow.lerpList(innerShadow, b.innerShadow, t)!,
          backgroundGradient: Gradient.lerp(backgroundGradient, b.backgroundGradient, t),
          borderGradient: GradientBorderSide.lerp(borderGradient, b.borderGradient, t),
        );
      }
    }

    return super.lerpTo(b, t);
  }

  @override
  OutlinedBorder copyWith({
    BorderSide? side,
    OutlinedBorder? child,
    List<BoxShadow>? shadow,
    List<BoxShadow>? innerShadow,
    Gradient? backgroundGradient,
    GradientBorderSide? borderGradient,
  }) {
    OutlinedBorder resolvedChild = child ?? this.child;
    if (side != null) {
      resolvedChild = (side != BorderSide.none) ? resolvedChild.copyWith(side: BorderSide(width: side.width, color: Colors.transparent)) : resolvedChild;
    }

    return DecoratedOutlinedBorder(
      child: resolvedChild,
      shadow: shadow ?? this.shadow,
      innerShadow: innerShadow ?? this.innerShadow,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      borderGradient: borderGradient ?? this.borderGradient,
    );
  }

  @override
  ShapeBorder scale(double t) {
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
  int get hashCode => hashValues(side, child, hashList(shadow), hashList(innerShadow), backgroundGradient, borderGradient);

  @override
  String toString() {
    return '${objectRuntimeType(this, 'DecoratedOutlinedBorder')}($side, $shadow, $innerShadow, $child, $backgroundGradient, $borderGradient)';
  }
}
