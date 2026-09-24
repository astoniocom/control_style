import 'package:control_style/src/decoration_painter.dart';
import 'package:control_style/src/gradient_border_side.dart';
import 'package:control_style/src/gradient_shadow.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Applies additional decoration to an [OutlinedBorder].
///
/// To decorate an [OutlinedBorder], wrap it into a [DecoratedOutlinedBorder].
/// For example, the code:
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     outlinedButtonTheme: OutlinedButtonThemeData(
///       style: OutlinedButton.styleFrom(
///         shape: RoundedRectangleBorder(
///           borderRadius: BorderRadius.circular(8),
///         ),
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
///   theme: ThemeData(
///     outlinedButtonTheme: OutlinedButtonThemeData(
///       style: OutlinedButton.styleFrom(
///         shape: DecoratedOutlinedBorder(
///           shadow: const [
///             BoxShadow(
///               color: Colors.blue,
///               blurRadius: 12,
///             ),
///           ],
///           child: RoundedRectangleBorder(
///             borderRadius: BorderRadius.circular(8),
///           ),
///         ),
///       ),
///     ),
///   ),
/// );
/// ```
///
/// Note that buttons, [Checkbox] and [Chip] resolve their side from their
/// style or theme and apply it via [copyWith], which overrides any side set on
/// the [child]. For example, for an [OutlinedButton] set the side through
/// [ButtonStyle.side] rather than on the [child].
///
/// See [DecorationPainter] for the description of the decoration parameters.
@immutable
class DecoratedOutlinedBorder extends OutlinedBorder with DecorationPainter {
  /// Creates a decorated [OutlinedBorder].
  ///
  /// The [child] is the [OutlinedBorder] to decorate. If [borderGradient] is
  /// set, the child's [OutlinedBorder.side] is replaced by a transparent side
  /// of the gradient's width, see [DecorationPainter.borderGradient].
  DecoratedOutlinedBorder({
    required OutlinedBorder child,
    this.shadow = const [],
    this.innerShadow = const [],
    this.backgroundGradient,
    this.borderGradient = GradientBorderSide.none,
    this.clipInner = true,
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
  final bool clipInner;

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
  /// A null [a] or [b] stands for the absence of decoration. The result takes
  /// [clipInner] from `this`.
  DecoratedOutlinedBorder? _lerp(
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
      clipInner: clipInner,
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
    bool? clipInner,
  }) {
    return DecoratedOutlinedBorder(
      child: (child ?? this.child).copyWith(side: side),
      shadow: shadow ?? this.shadow,
      innerShadow: innerShadow ?? this.innerShadow,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      borderGradient: borderGradient ?? this.borderGradient,
      clipInner: clipInner ?? this.clipInner,
    );
  }

  @override
  DecoratedOutlinedBorder scale(double t) {
    final scaledChild = child.scale(t);
    return DecoratedOutlinedBorder(
      child: scaledChild is OutlinedBorder ? scaledChild : child,
      shadow: GradientShadow.lerpList(null, shadow, t)!,
      innerShadow: GradientShadow.lerpList(null, innerShadow, t)!,
      backgroundGradient: backgroundGradient?.scale(t),
      borderGradient: borderGradient.scale(t),
      clipInner: clipInner,
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
        other.borderGradient == borderGradient &&
        other.clipInner == clipInner;
  }

  @override
  int get hashCode => Object.hash(
        side,
        child,
        Object.hashAll(shadow),
        Object.hashAll(innerShadow),
        backgroundGradient,
        borderGradient,
        clipInner,
      );

  @override
  String toString() {
    return '${objectRuntimeType(this, 'DecoratedOutlinedBorder')}($side, '
        '$shadow, $innerShadow, $child, $backgroundGradient, $borderGradient, '
        '$clipInner)';
  }
}
