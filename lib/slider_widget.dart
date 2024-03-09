import 'package:flutter/material.dart';

class SliderExample extends StatefulWidget {
  final ValueChanged<double> finalVal;

  const SliderExample({super.key, required this.finalVal});

  @override
  State<SliderExample> createState() => _SliderExampleState();
}

class _SliderExampleState extends State<SliderExample> {
  double _currentSliderValue = 0;

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: _currentSliderValue,
      max: 100,
      divisions: 100,
      label: _currentSliderValue.round().toString(),
      onChanged: (double value) {
        setState(() {
          _currentSliderValue = value;
          widget.finalVal(_currentSliderValue);
        });
      },
    );
  }
}
