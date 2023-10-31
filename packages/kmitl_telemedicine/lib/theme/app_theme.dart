import 'dart:math' as math;

import 'package:flutter/painting.dart';

const kAppColors = [
  Color.fromARGB(255, 218, 78, 55),
  Color.fromARGB(255, 244, 129, 54),
];
const kAppPrimaryColor = Color.fromARGB(255, 232, 133, 33);
const kAppGradient = LinearGradient(
  begin: Alignment(-1.0, 0.0),
  end: Alignment(1.0, 0.0),
  colors: kAppColors,
  transform: GradientRotation(math.pi / 4),
);
