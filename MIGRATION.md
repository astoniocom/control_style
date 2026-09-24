# Migration guide

## 0.1.x → 0.2.0

### Requirements

The package requires Dart 3 (`sdk: ^3.0.0`) and Flutter 3.10 or newer.

### Gradient border is painted exactly `width` wide

Up to 0.1.x, `borderGradient` was painted as a stroke along both the outer and
the inner edge of the shape. The visible band was twice as wide as
`GradientBorderSide.width` and extended half a `width` outside the shape. With
`UnderlineInputBorder` it painted a rectangle around the whole field.

In 0.2.0 the gradient side fills the area between the outer edge of the shape
and the edge inset by `width`, like a `BorderSide` with
`strokeAlign: BorderSide.strokeAlignInside`. Nothing is painted outside the
shape.

If you tuned `width` to the old rendering, double it to keep the same visual
thickness:

```dart
// 0.1.x: painted about 4 px wide, 1 px of it outside the shape.
GradientBorderSide(gradient: gradient, width: 2)

// 0.2.0: paints 4 px wide, all of it inside the shape.
GradientBorderSide(gradient: gradient, width: 4)
```

Note that the child's side, and therefore `ShapeBorder.dimensions`, already
used `width` before, so the layout of the control does not change when you
double it; only the painted band gets thinner if you do not.

`GradientBorderSide.toPaint` now returns a `PaintingStyle.fill` paint; the
width is not represented in the paint. A `width` of 0 paints nothing instead
of a hairline.

### `DecorationPainter.borderGradient` is non-nullable

Only affects custom implementations of the `DecorationPainter` mixin.

```dart
// 0.1.x
GradientBorderSide? get borderGradient => null;

// 0.2.0
GradientBorderSide get borderGradient => GradientBorderSide.none;
```

Callers can drop `?.` and `!` when reading the property.

### `paintBorder2` is removed

Deprecated in 0.1.2. Replace with `paintGradientBorder`; the signature is
unchanged.

```dart
// 0.1.x
paintBorder2(canvas, rect, borderGradient, textDirection: textDirection);

// 0.2.0
paintGradientBorder(canvas, rect, borderGradient, textDirection: textDirection);
```
