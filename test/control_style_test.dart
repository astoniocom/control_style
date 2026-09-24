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

  group('DecoratedOutlinedBorder.copyWith(side:)', () {
    test('keeps the side color when there is no gradient border', () {
      final shape = DecoratedOutlinedBorder(
        child: const RoundedRectangleBorder(),
      );
      const side = BorderSide(color: _red, width: 4);

      final copy = shape.copyWith(side: side) as DecoratedOutlinedBorder;

      expect(copy.child.side, side);
    });

    test('applies BorderSide.none to the child', () {
      final shape = DecoratedOutlinedBorder(
        child: const RoundedRectangleBorder(
          side: BorderSide(color: _red, width: 4),
        ),
      );

      final copy =
          shape.copyWith(side: BorderSide.none) as DecoratedOutlinedBorder;

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
      ) as DecoratedOutlinedBorder;

      expect(copy.child.side.color, Colors.transparent);
      expect(copy.child.side.width, 3);
    });
  });
}
