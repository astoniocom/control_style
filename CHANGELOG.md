## 0.2.0

Breaking changes:

- `DecorationPainter.borderGradient` is declared as non-nullable
  `GradientBorderSide`. Both bundled implementations already returned a
  non-null value. Custom implementations of the mixin must return
  `GradientBorderSide.none` instead of `null`; callers can drop `?.` and `!`.
- `DecorationPainter.paintBorder2`, deprecated in 0.1.2, is removed. Use
  `paintGradientBorder`; the signature is unchanged.

## 0.1.2

Bug fixes:

- Restore the canvas state after clipping the outer shadow. The leaked clip
  hid the child of a `DecoratedBox`/`Container` using `ShapeDecoration` with a
  decorated shape.
- `DecoratedOutlinedBorder.copyWith(side:)` now forwards the side to the child
  instead of making it transparent. `OutlinedButton`, `Checkbox` and `Chip`
  with a decorated shape and no `borderGradient` show their outline again.
- `GradientShadow` keeps its gradient in `scale` and `copyWith`, and therefore
  when animated in or out via `lerp`/`lerpList` and `ShapeBorder.scale`.
- `GradientShadow.lerp` between a `GradientShadow` and a plain `BoxShadow`
  interpolates the gradient instead of dropping it.
- `GradientBorderSide.lerp` fades a side with `BorderStyle.none` in and out
  instead of switching it at full opacity.
- Forward `TextDirection` to the background and border gradient shaders;
  gradients with `AlignmentDirectional` no longer throw.
- Shadows with negative offsets are clipped and painted correctly.
- `DecoratedInputBorder` keeps its `isOutline` while interpolating.
- The child's side is preserved when `borderGradient` has
  `style: BorderStyle.none` but is not identical to `GradientBorderSide.none`.
- Decorations interpolate smoothly even when the child borders cannot
  interpolate into each other, and when interpolating between a decorated and
  a plain `InputBorder`/`OutlinedBorder`.
- `GradientShadow.toString()` is well-formed.

Behaviour changes caused by the fixes above:

- Controls that previously lost their outline or content will show them again.
- Shadows with negative `offset` will become visible where they used to be
  clipped away or painted over the interior.
- Animations that used to jump will animate.

Additions:

- `DecoratedOutlinedBorder.clipInner` constructor parameter (default `true`).
- `GradientBorderSide.isNone` and `GradientBorderSide.toPaint(textDirection:)`.
- `GradientShadow.fromBoxShadow`, `GradientShadow.scale` and
  `GradientShadow.copyWith` returning `GradientShadow`.
- `copyWith` and `scale` of the decorated borders return the concrete type.
- `DecorationPainter.paintGradientBorder`; `paintBorder2` is deprecated and will
  be removed in the next breaking release.

Other:

- Skip painting the gradient border when it is switched off.
- Documentation: fixed doc comments and README, described how `borderGradient`
  replaces the child's side and how buttons, `Checkbox` and `Chip` resolve
  their side from the style.
- Tests added.

## 0.1.1

- lint rules updated

## 0.1.0

- document public members
- place the code in `src` folder
- fix SDK version

## 0.0.3

- Replaced deprecated functions.
- Updated lint rules.

## 0.0.2

- Fixed bugs in `lerp` functions.

## 0.0.1

- Initial release.
