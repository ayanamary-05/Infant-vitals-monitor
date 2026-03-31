import os
import re

def process_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Remove the extension definition
    extension_regex = r"extension ThemeColorsExt on BuildContext \{[\s\S]*?\}"
    content = re.sub(extension_regex, "", content)

    # Add the import if not already there
    if "import 'package:first_app/screens/theme_ext.dart';" not in content:
        content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:first_app/screens/theme_ext.dart';")

    # Fix _trendColor in home_screen.dart
    if "home_screen.dart" in path:
        content = content.replace("Color get _trendColor {", "Color _trendColor(BuildContext context) {")
        content = content.replace("color: _trendColor,", "color: _trendColor(context),")

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    base = r'C:\Users\Anosha Roy\Desktop\ORG\infant-vitals-monitor\lib\screens'
    process_file(os.path.join(base, 'home_screen.dart'))
    process_file(os.path.join(base, 'alerts_screen.dart'))
    process_file(os.path.join(base, 'history_screen.dart'))
    print("Fix script complete.")
