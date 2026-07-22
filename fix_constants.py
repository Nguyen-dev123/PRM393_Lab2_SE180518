import os
import re

files_to_fix = [
    'lib/screens/home_screen.dart',
    'lib/screens/keywords_screen.dart',
    'lib/screens/login_screen.dart',
    'lib/screens/main_shell.dart',
    'lib/screens/splash_screen.dart'
]

for path in files_to_fix:
    if not os.path.exists(path): continue
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if 'main_shell.dart' in path:
        content = content.replace('destinations: const [', 'destinations: [')
        content = content.replace('children: const [', 'children: [')
    
    # Generic regex to remove const before widget containing context.appTheme
    content = re.sub(r'const\s+([A-Z]\w*\([^)]*context\.appTheme[^)]*\))', r'\1', content)
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

print("Constants removed.")
