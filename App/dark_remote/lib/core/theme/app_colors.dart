import 'package:flutter/material.dart';

Color surfaceColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color.fromARGB(255, 12, 12, 12)
      : const Color(0xFFF2F2F2);
}

Color seamDark(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF050505)
      : const Color(0xFFBDBDBD);
}

Color seamLight(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0x1FFFFFFF)
      : const Color(0xFFFFFFFF);
}

Color iconColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFFFFFFF)
      : const Color(0xFF000000);
}

Color redColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF880000)
      : const Color(0xFFFF0000);
}