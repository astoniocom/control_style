import 'dart:ui' as ui;

import 'package:control_style/control_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const Color _red = Color(0xFFFF0000);
const Color _white = Color(0xFFFFFFFF);
const LinearGradient _redGradient = LinearGradient(colors: [_red, _red]);

/// The rectangle the shape is painted into, surrounded by a 20px margin.
const Rect _shapeRect = Rect.fromLTWH(20, 20, 100, 100);
const int _canvasSize = 140;
const Rect _canvasRect = Rect.fromLTWH(0, 0, 140, 140);

/// Paints [shape] into [_shapeRect] on a white canvas and rasterizes it.
///
/// [afterPaint] is invoked with the same canvas after the shape has been
/// painted, which allows checking for canvas state leaking out of `paint`.
Future<ui.Image> _rasterize(
  ShapeBorder shape, {
  TextDirection textDirection = TextDirection.ltr,
  void Function(Canvas canvas)? afterPaint,
}) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..drawRect(_canvasRect, Paint()..color = _white);
  shape.paint(canvas, _shapeRect, textDirection: textDirection);
  afterPaint?.call(canvas);
  return recorder.endRecording().toImage(_canvasSize, _canvasSize);
}

Future<Color> _pixel(ui.Image image, int x, int y) async {
  final bytes = (await image.toByteData())!;
  final i = (y * image.width + x) * 4;
  return Color.fromARGB(
    bytes.getUint8(i + 3),
    bytes.getUint8(i),
    bytes.getUint8(i + 1),
    bytes.getUint8(i + 2),
  );
}

bool _isRed(Color c) => c.a > 0.99 && c.r > 0.9 && c.g < 0.1 && c.b < 0.1;
bool _isWhite(Color c) => c.a > 0.99 && c.r > 0.99 && c.g > 0.99 && c.b > 0.99;

void main() {
  group('outer shadow clip must not leak out of paint()', () {
    testWidgets('area inside the shape is paintable after paint()', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final shape = DecoratedOutlinedBorder(
          shadow: const [BoxShadow(color: Colors.blue, blurRadius: 10)],
          child: const RoundedRectangleBorder(),
        );
        final image = await _rasterize(
          shape,
          afterPaint: (canvas) =>
              canvas.drawRect(_canvasRect, Paint()..color = _red),
        );
        // If the clip leaked, the interior of the shape would still be white.
        expect(_isRed(await _pixel(image, 70, 70)), isTrue);
      });
    });

    testWidgets('DecoratedBox child is visible', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        Center(
          child: RepaintBoundary(
            key: key,
            child: SizedBox(
              width: 100,
              height: 100,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  shape: DecoratedOutlinedBorder(
                    shadow: const [
                      BoxShadow(color: Colors.blue, blurRadius: 10),
                    ],
                    child: const RoundedRectangleBorder(),
                  ),
                ),
                child: const ColoredBox(color: _red),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        expect(_isRed(await _pixel(image, 50, 50)), isTrue);
      });
    });
  });

  group('gradient border geometry', () {
    testWidgets('border is exactly `width` wide and inside the shape', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final shape = DecoratedOutlinedBorder(
          borderGradient: const GradientBorderSide(
            gradient: _redGradient,
            width: 4,
          ),
          child: const RoundedRectangleBorder(),
        );
        final image = await _rasterize(shape);
        const y = 70;
        // Outside the shape: nothing is painted.
        expect(_isWhite(await _pixel(image, 18, y)), isTrue);
        expect(_isWhite(await _pixel(image, 19, y)), isTrue);
        // Border band: rect.left .. rect.left + width.
        for (var x = 20; x < 24; x++) {
          expect(_isRed(await _pixel(image, x, y)), isTrue, reason: 'x=$x');
        }
        // Interior: nothing is painted.
        expect(_isWhite(await _pixel(image, 24, y)), isTrue);
        expect(_isWhite(await _pixel(image, 25, y)), isTrue);
      });
    });

    testWidgets('UnderlineInputBorder paints only the underline', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final shape = DecoratedInputBorder(
          borderGradient: const GradientBorderSide(
            gradient: _redGradient,
            width: 2,
          ),
          child: const UnderlineInputBorder(),
        );
        final image = await _rasterize(shape);
        expect(_isWhite(await _pixel(image, 70, 20)), isTrue, reason: 'top');
        expect(_isWhite(await _pixel(image, 20, 70)), isTrue, reason: 'left');
        expect(_isWhite(await _pixel(image, 119, 70)), isTrue, reason: 'right');
        expect(_isRed(await _pixel(image, 70, 119)), isTrue, reason: 'bottom');
        expect(_isRed(await _pixel(image, 70, 118)), isTrue, reason: 'bottom');
        expect(_isWhite(await _pixel(image, 70, 117)), isTrue, reason: 'above');
        // The rounded top corners of the outer path must not leave slivers.
        expect(_isWhite(await _pixel(image, 20, 20)), isTrue, reason: 'corner');
      });
    });

    testWidgets('strokeAlignCenter straddles the edge', (tester) async {
      await tester.runAsync(() async {
        final shape = DecoratedOutlinedBorder(
          borderGradient: const GradientBorderSide(
            gradient: _redGradient,
            width: 4,
            strokeAlign: GradientBorderSide.strokeAlignCenter,
          ),
          child: const RoundedRectangleBorder(),
        );
        final image = await _rasterize(shape);
        const y = 70;
        expect(_isWhite(await _pixel(image, 17, y)), isTrue);
        // rect.left - 2 .. rect.left + 2
        for (var x = 18; x < 22; x++) {
          expect(_isRed(await _pixel(image, x, y)), isTrue, reason: 'x=$x');
        }
        expect(_isWhite(await _pixel(image, 22, y)), isTrue);
      });
    });

    testWidgets('strokeAlignOutside lies entirely outside', (tester) async {
      await tester.runAsync(() async {
        final shape = DecoratedOutlinedBorder(
          borderGradient: const GradientBorderSide(
            gradient: _redGradient,
            width: 4,
            strokeAlign: GradientBorderSide.strokeAlignOutside,
          ),
          child: const RoundedRectangleBorder(),
        );
        final image = await _rasterize(shape);
        const y = 70;
        expect(_isWhite(await _pixel(image, 15, y)), isTrue);
        // rect.left - 4 .. rect.left
        for (var x = 16; x < 20; x++) {
          expect(_isRed(await _pixel(image, x, y)), isTrue, reason: 'x=$x');
        }
        expect(_isWhite(await _pixel(image, 20, y)), isTrue);
        expect(_isWhite(await _pixel(image, 21, y)), isTrue);
      });
    });

    test('strokeAlign is forwarded to the child side and dimensions', () {
      const side = GradientBorderSide(
        gradient: _redGradient,
        width: 4,
        strokeAlign: GradientBorderSide.strokeAlignCenter,
      );
      final outlined = DecoratedOutlinedBorder(
        borderGradient: side,
        child: const RoundedRectangleBorder(),
      );
      expect(outlined.child.side.strokeAlign, BorderSide.strokeAlignCenter);
      expect(outlined.dimensions, const EdgeInsets.all(2));
      expect(
        outlined.getInnerPath(_shapeRect).getBounds(),
        _shapeRect.deflate(2),
      );

      final input = DecoratedInputBorder(
        borderGradient: side,
        child: const OutlineInputBorder(),
      );
      expect(input.child.borderSide.strokeAlign, BorderSide.strokeAlignCenter);
      expect(input.dimensions, const EdgeInsets.all(2));
    });

    test('width 0 paints nothing', () {
      final canvas = TestRecordingCanvas();
      const side = GradientBorderSide(gradient: _redGradient, width: 0);
      DecoratedOutlinedBorder(
        borderGradient: side,
        child: const RoundedRectangleBorder(),
      ).paintGradientBorder(canvas, _shapeRect, side);

      final drawPath = canvas.invocations
          .singleWhere((i) => i.invocation.memberName == #drawPath);
      final path = drawPath.invocation.positionalArguments.first as Path;
      expect(path.getBounds().isEmpty, isTrue);
    });
  });

  group('DecoratedOutlinedBorder.copyWith(side:)', () {
    test('keeps the side color when there is no gradient border', () {
      final shape = DecoratedOutlinedBorder(
        child: const RoundedRectangleBorder(),
      );
      const side = BorderSide(color: _red, width: 4);

      final copy = shape.copyWith(side: side);

      expect(copy.child.side, side);
    });

    test('applies BorderSide.none to the child', () {
      final shape = DecoratedOutlinedBorder(
        child: const RoundedRectangleBorder(
          side: BorderSide(color: _red, width: 4),
        ),
      );

      final copy = shape.copyWith(side: BorderSide.none);

      expect(copy.child.side, BorderSide.none);
    });

    test('still hides the child side when a gradient border is set', () {
      final shape = DecoratedOutlinedBorder(
        borderGradient: const GradientBorderSide(
          gradient: _redGradient,
          width: 3,
        ),
        child: const RoundedRectangleBorder(),
      );

      final copy = shape.copyWith(
        side: const BorderSide(color: Colors.blue, width: 4),
      );

      expect(copy.child.side.color, Colors.transparent);
      expect(copy.child.side.width, 3);
    });
  });

  group('GradientShadow keeps its gradient', () {
    const shadow = GradientShadow(
      gradient: LinearGradient(colors: [Colors.red, Colors.blue]),
      blurRadius: 10,
      spreadRadius: 4,
      offset: Offset(2, 6),
    );

    test('scale()', () {
      final scaled = shadow.scale(0.5);

      expect(scaled, isA<GradientShadow>());
      expect(scaled.gradient, shadow.gradient);
      expect(scaled.blurRadius, 5);
      expect(scaled.spreadRadius, 2);
      expect(scaled.offset, const Offset(1, 3));
    });

    test('copyWith()', () {
      final copy = shadow.copyWith(blurRadius: 1);

      expect(copy, isA<GradientShadow>());
      expect(copy.gradient, shadow.gradient);
      expect(copy.blurRadius, 1);
    });

    test('lerp() from null', () {
      final result = GradientShadow.lerp(null, shadow, 0.5);

      expect(result, isA<GradientShadow>());
      expect(result!.blurRadius, 5);
    });

    test('lerpList() with lists of different lengths', () {
      final result = GradientShadow.lerpList(const [], const [shadow], 0.5)!;

      expect(result, hasLength(1));
      expect(result.first, isA<GradientShadow>());
    });

    test('lerp() between a GradientShadow and a plain BoxShadow', () {
      const plain = BoxShadow(color: Colors.green, blurRadius: 20);

      final fromGradient = GradientShadow.lerp(shadow, plain, 0.5);
      final toGradient = GradientShadow.lerp(plain, shadow, 0.5);

      expect(fromGradient, isA<GradientShadow>());
      expect(fromGradient!.blurRadius, 15);
      expect(toGradient, isA<GradientShadow>());
      expect(toGradient!.blurRadius, 15);
      expect((toGradient as GradientShadow).gradient, isA<LinearGradient>());
    });

    test('lerp() between two plain BoxShadows stays a BoxShadow', () {
      const a = BoxShadow(blurRadius: 10);
      const b = BoxShadow(blurRadius: 20);

      final result = GradientShadow.lerp(a, b, 0.5);

      expect(result, isNot(isA<GradientShadow>()));
      expect(result!.blurRadius, 15);
    });

    test('toString() is well-formed', () {
      final text = shadow.toString();

      expect(text, startsWith('GradientShadow('));
      expect(text, endsWith(')'));
      expect(text, contains('BlurStyle.normal'));
      expect(text, contains('LinearGradient('));
    });

    test('DecoratedOutlinedBorder.scale()', () {
      final shape = DecoratedOutlinedBorder(
        shadow: const [shadow],
        innerShadow: const [shadow],
        child: const RoundedRectangleBorder(),
      );

      final scaled = shape.scale(0.5);

      expect(scaled.shadow.single, isA<GradientShadow>());
      expect(scaled.innerShadow.single, isA<GradientShadow>());
    });
  });

  group('text direction is forwarded to gradient shaders', () {
    const directional = LinearGradient(
      begin: AlignmentDirectional.centerStart,
      end: AlignmentDirectional.centerEnd,
      colors: [Colors.red, Colors.blue],
    );

    void paint(ShapeBorder shape) {
      final recorder = ui.PictureRecorder();
      shape.paint(
        Canvas(recorder),
        _shapeRect,
        textDirection: TextDirection.rtl,
      );
    }

    test('backgroundGradient', () {
      final shape = DecoratedOutlinedBorder(
        backgroundGradient: directional,
        child: const RoundedRectangleBorder(),
      );

      expect(() => paint(shape), returnsNormally);
    });

    test('borderGradient', () {
      final shape = DecoratedOutlinedBorder(
        borderGradient: const GradientBorderSide(gradient: directional),
        child: const RoundedRectangleBorder(),
      );

      expect(() => paint(shape), returnsNormally);
    });

    test('GradientShadow in shadow and innerShadow', () {
      final shape = DecoratedOutlinedBorder(
        shadow: const [GradientShadow(gradient: directional, blurRadius: 4)],
        innerShadow: const [
          GradientShadow(gradient: directional, blurRadius: 4),
        ],
        child: const RoundedRectangleBorder(),
      );

      expect(() => paint(shape), returnsNormally);
    });

    test('GradientBorderSide.toPaint', () {
      const side = GradientBorderSide(gradient: directional);

      expect(
        () => side.toPaint(_shapeRect, textDirection: TextDirection.rtl),
        returnsNormally,
      );
    });
  });

  group('shadows with negative offsets', () {
    testWidgets('outer shadow shifted to the left is not clipped away', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final shape = DecoratedOutlinedBorder(
          shadow: const [BoxShadow(color: _red, offset: Offset(-30, 0))],
          child: const RoundedRectangleBorder(),
        );
        final image = await _rasterize(shape);
        // The shadow is the shape shifted 30px to the left, so the strip
        // between x = -10 and x = 20 (rect.left) must be red.
        expect(_isRed(await _pixel(image, 5, 70)), isTrue);
        expect(_isRed(await _pixel(image, 15, 70)), isTrue);
        // Interior stays clear because of `clipInner`.
        expect(_isWhite(await _pixel(image, 70, 70)), isTrue);
      });
    });

    testWidgets('inner shadow shifted to the left is not clipped away', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final shape = DecoratedOutlinedBorder(
          innerShadow: const [BoxShadow(color: _red, offset: Offset(-30, 0))],
          child: const RoundedRectangleBorder(),
        );
        final image = await _rasterize(shape);
        // The inner shadow is the area of the shape not covered by the shape
        // shifted 30px to the left: the strip rect.right - 30 .. rect.right.
        expect(_isRed(await _pixel(image, 95, 70)), isTrue);
        expect(_isRed(await _pixel(image, 115, 70)), isTrue);
        expect(_isWhite(await _pixel(image, 85, 70)), isTrue);
        // Nothing is painted outside the shape.
        expect(_isWhite(await _pixel(image, 125, 70)), isTrue);
      });
    });
  });

  group('child side is kept when the gradient border is switched off', () {
    const childSide = BorderSide(color: _red, width: 4);
    const offGradient = GradientBorderSide(
      gradient: _redGradient,
      width: 2,
      style: BorderStyle.none,
    );

    test('GradientBorderSide.isNone', () {
      expect(GradientBorderSide.none.isNone, isTrue);
      expect(offGradient.isNone, isTrue);
      expect(const GradientBorderSide(gradient: _redGradient).isNone, isFalse);
    });

    test('DecoratedOutlinedBorder', () {
      final shape = DecoratedOutlinedBorder(
        borderGradient: offGradient,
        child: const RoundedRectangleBorder(side: childSide),
      );

      expect(shape.child.side, childSide);
    });

    test('DecoratedInputBorder', () {
      final shape = DecoratedInputBorder(
        borderGradient: offGradient,
        child: const OutlineInputBorder(borderSide: childSide),
      );

      expect(shape.child.borderSide, childSide);
    });
  });

  group('decorations interpolate regardless of the child borders', () {
    const shadow10 = BoxShadow(color: _red, blurRadius: 10);

    test('children that cannot lerp into each other', () {
      final a = DecoratedOutlinedBorder(
        child: const RoundedRectangleBorder(),
      );
      final b = DecoratedOutlinedBorder(
        shadow: const [shadow10],
        child: const BeveledRectangleBorder(),
      );

      final result = ShapeBorder.lerp(a, b, 0.5)! as DecoratedOutlinedBorder;

      expect(result.shadow.single.blurRadius, 5);
    });

    test('from a plain OutlinedBorder', () {
      final b = DecoratedOutlinedBorder(
        shadow: const [shadow10],
        child: const RoundedRectangleBorder(),
      );

      final result = ShapeBorder.lerp(const RoundedRectangleBorder(), b, 0.5)!
          as DecoratedOutlinedBorder;

      expect(result.shadow.single.blurRadius, 5);
    });

    test('to a plain OutlinedBorder', () {
      final a = DecoratedOutlinedBorder(
        shadow: const [shadow10],
        child: const RoundedRectangleBorder(),
      );

      final result = ShapeBorder.lerp(a, const RoundedRectangleBorder(), 0.25)!
          as DecoratedOutlinedBorder;

      expect(result.shadow.single.blurRadius, 7.5);
    });

    test('from a plain InputBorder', () {
      final b = DecoratedInputBorder(
        shadow: const [shadow10],
        child: const OutlineInputBorder(),
      );

      final result = ShapeBorder.lerp(const OutlineInputBorder(), b, 0.5)!
          as DecoratedInputBorder;

      expect(result.shadow.single.blurRadius, 5);
    });

    test('to a plain InputBorder', () {
      final a = DecoratedInputBorder(
        shadow: const [shadow10],
        child: const OutlineInputBorder(),
      );

      final result = ShapeBorder.lerp(a, const OutlineInputBorder(), 0.25)!
          as DecoratedInputBorder;

      expect(result.shadow.single.blurRadius, 7.5);
    });
  });

  group('GradientBorderSide.lerp with different styles', () {
    const visible = GradientBorderSide(
      gradient: LinearGradient(colors: [_red, _red]),
      width: 4,
    );
    const hidden = GradientBorderSide(
      gradient: LinearGradient(colors: [Colors.blue, Colors.blue]),
      width: 4,
      style: BorderStyle.none,
    );

    Color colorAt(GradientBorderSide side) =>
        (side.gradient as LinearGradient).colors.first;

    test('fades in from a hidden side', () {
      final result = GradientBorderSide.lerp(hidden, visible, 0.5);

      expect(result.style, BorderStyle.solid);
      expect(colorAt(result).a, closeTo(0.5, 0.01));
    });

    test('fades out to a hidden side', () {
      final result = GradientBorderSide.lerp(visible, hidden, 0.5);

      expect(result.style, BorderStyle.solid);
      expect(colorAt(result).a, closeTo(0.5, 0.01));
    });
  });

  group('GradientBorderSide.strokeAlign', () {
    const inside = GradientBorderSide(gradient: _redGradient, width: 4);
    const outside = GradientBorderSide(
      gradient: _redGradient,
      width: 4,
      strokeAlign: GradientBorderSide.strokeAlignOutside,
    );

    test('defaults to inside and matches BorderSide constants', () {
      expect(inside.strokeAlign, BorderSide.strokeAlignInside);
      expect(GradientBorderSide.none.strokeAlign, BorderSide.strokeAlignInside);
      expect(
        GradientBorderSide.strokeAlignCenter,
        BorderSide.strokeAlignCenter,
      );
      expect(
        GradientBorderSide.strokeAlignOutside,
        BorderSide.strokeAlignOutside,
      );
    });

    test('strokeInset and strokeOutset', () {
      expect(inside.strokeInset, 4);
      expect(inside.strokeOutset, 0);
      expect(outside.strokeInset, 0);
      expect(outside.strokeOutset, 4);
      final center = inside.copyWith(
        strokeAlign: GradientBorderSide.strokeAlignCenter,
      );
      expect(center.strokeInset, 2);
      expect(center.strokeOutset, 2);
    });

    test('is interpolated, scaled, copied and compared', () {
      expect(GradientBorderSide.lerp(inside, outside, 0.5).strokeAlign, 0);
      expect(outside.scale(0.5).strokeAlign, outside.strokeAlign);
      expect(
        inside.copyWith(strokeAlign: GradientBorderSide.strokeAlignOutside),
        outside,
      );
      expect(inside, isNot(outside));
      expect(inside.hashCode, isNot(outside.hashCode));
      expect(outside.toString(), contains('strokeAlign: 1.0'));
    });
  });

  group('paintGradientBorder', () {
    int drawPathCalls(GradientBorderSide side) {
      final canvas = TestRecordingCanvas();
      DecoratedOutlinedBorder(
        borderGradient: side,
        child: const RoundedRectangleBorder(),
      ).paintGradientBorder(canvas, _shapeRect, side);
      return canvas.invocations
          .where((i) => i.invocation.memberName == #drawPath)
          .length;
    }

    test('draws nothing for a side that is switched off', () {
      expect(drawPathCalls(GradientBorderSide.none), 0);
      expect(
        drawPathCalls(
          const GradientBorderSide(
            gradient: _redGradient,
            width: 2,
            style: BorderStyle.none,
          ),
        ),
        0,
      );
    });

    test('draws a visible side', () {
      expect(
        drawPathCalls(const GradientBorderSide(gradient: _redGradient)),
        1,
      );
    });
  });

  group('borders listed as supported in README', () {
    const gradient = LinearGradient(colors: [Colors.red, Colors.blue]);
    const shadow = GradientShadow(gradient: gradient, blurRadius: 8);
    const border = GradientBorderSide(gradient: gradient, width: 2);

    const outlinedBorders = <OutlinedBorder>[
      BeveledRectangleBorder(),
      CircleBorder(),
      ContinuousRectangleBorder(),
      RoundedRectangleBorder(),
      StadiumBorder(),
    ];
    const inputBorders = <InputBorder>[
      UnderlineInputBorder(),
      OutlineInputBorder(),
    ];

    void paint(ShapeBorder shape) {
      shape.paint(Canvas(ui.PictureRecorder()), _shapeRect);
    }

    for (final child in outlinedBorders) {
      test('${child.runtimeType} paints with every decoration', () {
        final shape = DecoratedOutlinedBorder(
          shadow: const [shadow],
          innerShadow: const [shadow],
          backgroundGradient: gradient,
          borderGradient: border,
          child: child,
        );

        expect(() => paint(shape), returnsNormally);
        expect(() => paint(shape.scale(0.5)), returnsNormally);
      });
    }

    for (final child in inputBorders) {
      test('${child.runtimeType} paints with every decoration', () {
        final shape = DecoratedInputBorder(
          shadow: const [shadow],
          innerShadow: const [shadow],
          backgroundGradient: gradient,
          borderGradient: border,
          child: child,
        );

        expect(() => paint(shape), returnsNormally);
        expect(() => paint(shape.scale(0.5)), returnsNormally);
      });
    }
  });

  group('equality', () {
    const gradient = LinearGradient(colors: [Colors.red, Colors.blue]);

    test('GradientShadow', () {
      const a = GradientShadow(gradient: gradient, blurRadius: 4);
      const b = GradientShadow(gradient: gradient, blurRadius: 4);
      const c = GradientShadow(gradient: gradient, blurRadius: 5);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('GradientBorderSide', () {
      const a = GradientBorderSide(gradient: gradient, width: 2);
      const b = GradientBorderSide(gradient: gradient, width: 2);
      const c = GradientBorderSide(gradient: gradient, width: 3);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('DecoratedOutlinedBorder', () {
      DecoratedOutlinedBorder build({double blur = 4}) {
        return DecoratedOutlinedBorder(
          shadow: [GradientShadow(gradient: gradient, blurRadius: blur)],
          backgroundGradient: gradient,
          child: const RoundedRectangleBorder(),
        );
      }

      expect(build(), build());
      expect(build().hashCode, build().hashCode);
      expect(build(), isNot(build(blur: 5)));
    });

    test('DecoratedInputBorder', () {
      DecoratedInputBorder build({bool clipInner = true}) {
        return DecoratedInputBorder(
          shadow: const [GradientShadow(gradient: gradient, blurRadius: 4)],
          clipInner: clipInner,
          child: const OutlineInputBorder(),
        );
      }

      expect(build(), build());
      expect(build().hashCode, build().hashCode);
      expect(build(), isNot(build(clipInner: false)));
    });
  });

  group('DecoratedOutlinedBorder.clipInner', () {
    DecoratedOutlinedBorder build({required bool clipInner}) {
      return DecoratedOutlinedBorder(
        shadow: const [BoxShadow(color: _red, offset: Offset(-30, 0))],
        clipInner: clipInner,
        child: const RoundedRectangleBorder(),
      );
    }

    testWidgets('false paints the shadow over the interior', (tester) async {
      await tester.runAsync(() async {
        final image = await _rasterize(build(clipInner: false));

        expect(_isRed(await _pixel(image, 70, 70)), isTrue);
      });
    });

    test('survives copyWith, scale and lerp', () {
      final shape = build(clipInner: false);

      expect(shape.copyWith(shadow: const []).clipInner, isFalse);
      expect(shape.scale(0.5).clipInner, isFalse);
      expect(
        (ShapeBorder.lerp(shape, build(clipInner: false), 0.5)!
                as DecoratedOutlinedBorder)
            .clipInner,
        isFalse,
      );
    });

    test('is part of equality', () {
      expect(build(clipInner: true), isNot(build(clipInner: false)));
    });
  });

  group('DecoratedInputBorder keeps isOutline while interpolating', () {
    // `UnderlineInputBorder.isOutline` is false; override it to true.
    final a = DecoratedInputBorder(
      isOutline: true,
      child: const UnderlineInputBorder(),
    );
    final b = DecoratedInputBorder(
      isOutline: true,
      shadow: const [BoxShadow(blurRadius: 8)],
      child: const UnderlineInputBorder(),
    );

    test('lerpFrom', () {
      final result = b.lerpFrom(a, 0.5)! as DecoratedInputBorder;

      expect(result.isOutline, isTrue);
    });

    test('lerpTo', () {
      final result = a.lerpTo(b, 0.5)! as DecoratedInputBorder;

      expect(result.isOutline, isTrue);
    });

    test('ShapeBorder.lerp', () {
      final result = ShapeBorder.lerp(a, b, 0.5)! as DecoratedInputBorder;

      expect(result.isOutline, isTrue);
    });
  });
}
