import os
import re

def process_file(path, bg_var, surface_var, text_main_var, text_sub_var, border_var, is_home=False):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Define the colors extension
    extension_code = """
extension ThemeColorsExt on BuildContext {
  Color get bg => Theme.of(this).scaffoldBackgroundColor;
  Color get surface => Theme.of(this).colorScheme.surface;
  Color get subtext => Theme.of(this).textTheme.bodySmall?.color ?? Colors.grey;
  Color get textMain => Theme.of(this).textTheme.bodyLarge?.color ?? Colors.black;
  Color get border => Theme.of(this).dividerColor;
}
"""

    if is_home:
        # Replacement for home_screen.dart
        content = re.sub(r'const Color kBg\s*=\s*Color\(0xFF0F172A\);', extension_code, content)
        content = re.sub(r'const Color kSurface\s*=\s*Color\(0xFF1E293B\);\n', '', content)
        content = re.sub(r'const Color kSubtext\s*=\s*Color\(0xFF94A3B8\);\n', '', content)
        content = re.sub(r'const Color kTimestamp\s*=\s*Color\(0xFFCBD5E1\);\n', '', content)
    else:
        # Replacement for alerts_screen and history_screen
        content = re.sub(r'const Color _bg\s*=\s*Color\(0xFF0F172A\);', extension_code, content)
        content = re.sub(r'const Color _surface\s*=\s*Color\(0xFF1E293B\);\n', '', content)
        content = re.sub(r'const Color _border\s*=\s*Color\(0xFF334155\);\n', '', content)
        content = re.sub(r'const Color _textMain\s*=\s*Color\(0xFFF1F5F9\);\n', '', content)
        content = re.sub(r'const Color _textSub\s*=\s*Color\(0xFF94A3B8\);\n', '', content)


    # Safe substitutions for 'const '
    # We must remove const if the line contains context.bg, context.surface, etc.
    
    if is_home:
        content = content.replace(bg_var, "context.bg")
        content = content.replace(surface_var, "context.surface")
        content = content.replace(text_sub_var, "context.subtext")
        content = content.replace('kTimestamp', "context.subtext")
        # specifically for home_screen: Colors.white for normal text, replace with context.textMain
        content = re.sub(r'color:\s*Colors.white,\s*fontSize:\s*(\d+)', r'color: context.textMain, fontSize: \1', content)
        content = content.replace('color: Colors.white, fontWeight:', 'color: context.textMain, fontWeight:')
        content = content.replace('color: Colors.white.withValues', 'color: context.textMain.withValues')
    else:
        content = content.replace(bg_var, "context.bg")
        content = content.replace(surface_var, "context.surface")
        content = content.replace(border_var, "context.border")
        content = content.replace(text_main_var, "context.textMain")
        content = content.replace(text_sub_var, "context.subtext")

    # Replace all const widgets with just the widget name, effectively removing `const`
    content = content.replace('const TextStyle', 'TextStyle')
    content = content.replace('const BoxDecoration', 'BoxDecoration')
    content = content.replace('const Border', 'Border')
    content = content.replace('const Icon', 'Icon')
    content = content.replace('const SizedBox', 'SizedBox')
    content = content.replace('const Row', 'Row')
    content = content.replace('const Column', 'Column')
    content = content.replace('const Padding', 'Padding')
    content = content.replace('const Text(', 'Text(')
    content = content.replace('const EdgeInsets', 'EdgeInsets')
    content = content.replace('const Container', 'Container')
    content = content.replace('const Color', 'Color')
    
    # Restore specific variable definitions
    content = content.replace('Color _green    = Color', 'const Color _green    = Color')
    content = content.replace('Color _red      = Color', 'const Color _red      = Color')
    content = content.replace('Color _orange   = Color', 'const Color _orange   = Color')
    content = content.replace('Color _border   = Color', 'const Color _border   = Color')
    content = content.replace('Color _textMain = Color', 'const Color _textMain = Color')
    content = content.replace('Color _textSub  = Color', 'const Color _textSub  = Color')
    
    content = content.replace('Color kGreen   = Color', 'const Color kGreen   = Color')
    content = content.replace('Color kBlue    = Color', 'const Color kBlue    = Color')
    content = content.replace('Color kOrange  = Color', 'const Color kOrange  = Color')
    content = content.replace('Color kRed     = Color', 'const Color kRed     = Color')

    # Also restore color literals used elsewhere like Color(0xFF...) just in case they were replaced
    content = re.sub(r'Color\(0x([A-Fa-f0-9]+)\)', r'const Color(0x\1)', content)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)


if __name__ == '__main__':
    base = r'C:\Users\Anosha Roy\Desktop\ORG\infant-vitals-monitor\lib\screens'
    
    # Process home_screen.dart
    process_file(os.path.join(base, 'home_screen.dart'), 'kBg', 'kSurface', 'Colors.white', 'kSubtext', '', is_home=True)
    
    # Process alerts_screen.dart
    process_file(os.path.join(base, 'alerts_screen.dart'), '_bg', '_surface', '_textMain', '_textSub', '_border', is_home=False)
    
    # Process history_screen.dart
    process_file(os.path.join(base, 'history_screen.dart'), '_bg', '_surface', '_textMain', '_textSub', '_border', is_home=False)
    
    print("Refactoring complete.")
