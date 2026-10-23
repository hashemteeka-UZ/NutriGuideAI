import 'package:flutter/widgets.dart';

bool animationsEnabled(BuildContext context) {
  return !MediaQuery.disableAnimationsOf(context);
}
