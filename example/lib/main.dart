import 'package:control_style/control_style.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

enum BorderType { rounded, beveld, continuous, stadium }

const defaultGradient = LinearGradient(colors: []);

const List<Gradient> _gradientCollection = [
  LinearGradient(colors: [Colors.blue, Colors.blue]),
  LinearGradient(colors: [Colors.yellow, Colors.blue, Colors.red]),
  LinearGradient(colors: [Colors.red, Colors.green, Colors.blue]),
  LinearGradient(colors: [Color(0x602195F3), Color(0x332195F3)]),
  LinearGradient(colors: [Color(0x332195F3), Color(0x602195F3)]),
];

class Preset {
  const Preset({
    required this.name,
    this.borderRadius = 8,
    this.shadowGradient,
    this.shadowBlurRadius = 15,
    this.shadowSpreadRadius = 5,
    this.innerShadowGradient,
    this.innerShadowBlurRadius = 15,
    this.innerShadowSpreadRadius = 5,
    this.borderGradient,
    this.backgroundGradient,
    this.borderWidth = 2,
  });

  final String name;

  final double borderRadius;

  final Gradient? shadowGradient;
  final double shadowBlurRadius;
  final double shadowSpreadRadius;

  final Gradient? innerShadowGradient;
  final double innerShadowBlurRadius;
  final double innerShadowSpreadRadius;

  final Gradient? borderGradient;

  final Gradient? backgroundGradient;

  final double borderWidth;

  Preset copyWith({
    double? borderRadius,
    Gradient? shadowGradient = defaultGradient,
    double? shadowBlurRadius,
    double? shadowSpreadRadius,
    Gradient? innerShadowGradient = defaultGradient,
    double? innerShadowBlurRadius,
    double? innerShadowSpreadRadius,
    Gradient? borderGradient = defaultGradient,
    Gradient? backgroundGradient = defaultGradient,
    double? borderWidth,
  }) {
    return Preset(
      name: name,
      borderRadius: borderRadius ?? this.borderRadius,
      shadowGradient: shadowGradient != defaultGradient ? shadowGradient : this.shadowGradient,
      shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
      shadowSpreadRadius: shadowSpreadRadius ?? this.shadowSpreadRadius,
      innerShadowGradient: innerShadowGradient != defaultGradient ? innerShadowGradient : this.innerShadowGradient,
      innerShadowBlurRadius: innerShadowBlurRadius ?? this.innerShadowBlurRadius,
      innerShadowSpreadRadius: innerShadowSpreadRadius ?? this.innerShadowSpreadRadius,
      borderGradient: borderGradient != defaultGradient ? borderGradient : this.borderGradient,
      backgroundGradient: backgroundGradient != defaultGradient ? backgroundGradient : this.backgroundGradient,
      borderWidth: borderWidth ?? this.borderWidth,
    );
  }
}

final List<Preset> presets = [
  Preset(name: "Shadow", shadowGradient: _gradientCollection[0]),
  Preset(name: "Inner shadow", innerShadowGradient: _gradientCollection[0]),
  Preset(name: "Gradient border", borderGradient: _gradientCollection[1]),
  Preset(name: "Background gradient", backgroundGradient: _gradientCollection[3]),
  Preset(
      name: "All in one",
      shadowGradient: _gradientCollection[1],
      innerShadowGradient: _gradientCollection[0],
      borderGradient: _gradientCollection[1],
      backgroundGradient: _gradientCollection[3])
];

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  BorderType borderType = BorderType.rounded;
  Preset preset = presets[0];

  @override
  Widget build(BuildContext context) {
    final outlinedBorders = {
      BorderType.rounded: RoundedRectangleBorder(borderRadius: BorderRadius.circular(preset.borderRadius)),
      BorderType.beveld: BeveledRectangleBorder(borderRadius: BorderRadius.circular(preset.borderRadius)),
      BorderType.continuous: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(preset.borderRadius)),
      BorderType.stadium: const StadiumBorder(),
    };
    final outlinedBorder = outlinedBorders[borderType]!;

    final outlinedShape = DecoratedOutlinedBorder(
      shadow: [
        if (preset.shadowGradient != null)
          GradientShadow(gradient: preset.shadowGradient!, blurRadius: preset.shadowBlurRadius, spreadRadius: preset.shadowSpreadRadius)
      ],
      innerShadow: [
        if (preset.innerShadowGradient != null)
          GradientShadow(gradient: preset.innerShadowGradient!, blurRadius: preset.innerShadowBlurRadius, spreadRadius: preset.innerShadowSpreadRadius)
      ],
      backgroundGradient: preset.backgroundGradient,
      borderGradient: preset.borderGradient != null ? GradientBorderSide(gradient: preset.borderGradient!, width: preset.borderWidth) : GradientBorderSide.none,
      child: outlinedBorder,
    );

    final inputShape = DecoratedInputBorder(
      shadow: [
        if (preset.shadowGradient != null)
          GradientShadow(gradient: preset.shadowGradient!, blurRadius: preset.shadowBlurRadius, spreadRadius: preset.shadowSpreadRadius)
      ],
      innerShadow: [
        if (preset.innerShadowGradient != null)
          GradientShadow(gradient: preset.innerShadowGradient!, blurRadius: preset.innerShadowBlurRadius, spreadRadius: preset.innerShadowSpreadRadius)
      ],
      backgroundGradient: preset.backgroundGradient,
      borderGradient: preset.borderGradient != null ? GradientBorderSide(gradient: preset.borderGradient!, width: preset.borderWidth) : GradientBorderSide.none,
      clipInner: true,
      child: OutlineInputBorder(
        borderRadius: BorderRadius.circular(preset.borderRadius),
      ),
    );

    return MaterialApp(
      theme: ThemeData(
        textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(shape: outlinedShape)),
        inputDecorationTheme: InputDecorationTheme(
          floatingLabelBehavior: FloatingLabelBehavior.never,
          border: inputShape,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text("Control style demo")),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  TextButton(
                      onPressed: () => setState(() {
                            final curBorderIndex = outlinedBorders.keys.toList().indexOf(borderType);
                            borderType = outlinedBorders.keys.toList()[(curBorderIndex + 1) % outlinedBorders.length];
                          }),
                      child: Text("${describeEnum(borderType)} border exapmle")),
                  const SizedBox(height: 42),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: "Text Field example",
                      errorText: "Error text",
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    children: [
                      const Text("Preset"),
                      DropdownButton<Preset>(
                        value: presets.contains(preset) ? preset : null,
                        items: presets.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
                        onChanged: (value) => setState(() => preset = value!),
                      ),
                      const Divider(),
                      const Text("Shadow color"),
                      GradientPicker(
                          onChanged: (Gradient? value) => setState(() => preset = preset.copyWith(shadowGradient: value)), value: preset.shadowGradient),
                      if (preset.shadowGradient != null) ...[
                        const SizedBox(height: 16),
                        Text("Shadow blur radius ${preset.shadowBlurRadius.round()}"),
                        Slider(
                          max: 50,
                          value: preset.shadowBlurRadius,
                          onChanged: (value) => setState(() => preset = preset.copyWith(shadowBlurRadius: value)),
                        ),
                        const SizedBox(height: 16),
                        Text("Shadow spread radius ${preset.shadowSpreadRadius.round()}"),
                        Slider(
                          max: 30,
                          value: preset.shadowSpreadRadius,
                          onChanged: (value) => setState(() => preset = preset.copyWith(shadowSpreadRadius: value)),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Text("Inner shadow color"),
                      GradientPicker(
                          onChanged: (Gradient? value) => setState(() => preset = preset.copyWith(innerShadowGradient: value)),
                          value: preset.innerShadowGradient),
                      if (preset.innerShadowGradient != null) ...[
                        Text("Inner shadow blur radius ${preset.innerShadowBlurRadius.round()}"),
                        Slider(
                          max: 30,
                          value: preset.innerShadowBlurRadius,
                          onChanged: (value) => setState(() => preset = preset.copyWith(innerShadowBlurRadius: value)),
                        ),
                        const SizedBox(height: 16),
                        Text("Inner shadow spread radius ${preset.innerShadowSpreadRadius.round()}"),
                        Slider(
                          max: 10,
                          value: preset.innerShadowSpreadRadius,
                          onChanged: (value) => setState(() => preset = preset.copyWith(innerShadowSpreadRadius: value)),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Text("Border color"),
                      GradientPicker(
                          onChanged: (Gradient? value) => setState(() => preset = preset.copyWith(borderGradient: value)), value: preset.borderGradient),
                      if (borderType != BorderType.stadium) ...[
                        const SizedBox(height: 16),
                        Text("Border radius ${preset.borderRadius.round()}"),
                        Slider(
                          max: 50,
                          value: preset.borderRadius,
                          onChanged: (value) => setState(() => preset = preset.copyWith(borderRadius: value)),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Text("Inner gradient"),
                      GradientPicker(
                          onChanged: (Gradient? value) => setState(() => preset = preset.copyWith(backgroundGradient: value)),
                          value: preset.backgroundGradient),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GradientPicker extends StatelessWidget {
  const GradientPicker({
    required this.onChanged,
    required this.value,
    Key? key,
  }) : super(key: key);
  final Gradient? value;
  final Function(Gradient?) onChanged;

  Widget getDisplayWidget(Gradient gradient) => Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 64),
      decoration: BoxDecoration(gradient: gradient),
      child: Text("Color ${_gradientCollection.indexOf(gradient)}"));

  @override
  Widget build(BuildContext context) {
    return DropdownButton(
      value: value,
      items: [
        const DropdownMenuItem<Gradient>(value: null, child: Text("Not selected")),
        ..._gradientCollection.map((e) => DropdownMenuItem(value: e, child: getDisplayWidget(e)))
      ],
      onChanged: onChanged,
    );
  }
}
