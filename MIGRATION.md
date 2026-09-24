# Migration guide

## 0.1.x → 0.2.0

### Requirements

The package requires Dart 3 (`sdk: ^3.0.0`) and Flutter 3.10 or newer.

### Gradient border width

Up to 0.1.x, `borderGradient` was stroked along both edges of the shape, so
the visible band was twice as wide as `GradientBorderSide.width` and extended
half a `width` outside the shape. With `UnderlineInputBorder` it painted a
rectangle around the whole field.

In 0.2.0 the band is exactly `width` wide and lies inside the shape, like a
`BorderSide` with the default `strokeAlign`. If you tuned `width` to the old
rendering, double it. The layout does not change: the child's side already
used `width` before.

```dart
// 0.1.x: about 4 px wide, 1 px of it outside the shape.
GradientBorderSide(gradient: gradient, width: 2)

// 0.2.0: 4 px wide, all of it inside the shape.
GradientBorderSide(gradient: gradient, width: 4)

// 0.2.0: the old geometry exactly, at the cost of a wider `dimensions`.
GradientBorderSide(gradient: gradient, width: 4, strokeAlign: -0.5)
```

`GradientBorderSide.toPaint` returns a `PaintingStyle.fill` paint and a
`width` of 0 paints nothing instead of a hairline.

The gradient border of an `OutlineInputBorder` now leaves the gap for a
floating label open. If you worked around the covered gap with
`floatingLabelBehavior: FloatingLabelBehavior.never`, the workaround can be
removed.

### Custom `DecorationPainter` implementations

`borderGradient` is non-nullable; return `GradientBorderSide.none` instead
of `null`. Callers can drop `?.` and `!`.

`paintBorder2`, deprecated in 0.1.2, is removed; call `paintGradientBorder`
with the same arguments. `InputBorder` implementations should also forward
`gapStart`, `gapExtent` and `gapPercentage` from `paint` to get the floating
label gap.
