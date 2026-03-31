import 'package:flutter/material.dart';

extension ThemeColorsExt on BuildContext {
  Color get bg => Theme.of(this).scaffoldBackgroundColor;
  Color get surface => Theme.of(this).colorScheme.surface;
  Color get subtext => Theme.of(this).textTheme.bodySmall?.color ?? Colors.grey;
  Color get textMain => Theme.of(this).textTheme.bodyLarge?.color ?? Colors.black;
  Color get border => Theme.of(this).dividerColor;
}
