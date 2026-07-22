import os

screens_dir = 'lib/screens'

for root, _, files in os.walk(screens_dir):
    for file in files:
        if file.endswith('.dart'):
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            if 'Colors.indigo' in content:
                # Replace Colors.indigo with context.appTheme
                new_content = content.replace('Colors.indigo', 'context.appTheme')
                
                # Check if we need to add imports
                imports = []
                if "import 'package:provider/provider.dart';" not in new_content:
                    imports.append("import 'package:provider/provider.dart';")
                
                config_import = "import '../state/config_provider.dart';"
                if config_import not in new_content:
                    imports.append(config_import)
                
                if imports:
                    # find the last import line
                    lines = new_content.split('\n')
                    last_import_idx = 0
                    for i, line in enumerate(lines):
                        if line.startswith('import '):
                            last_import_idx = i
                    
                    # insert after last import
                    for imp in reversed(imports):
                        lines.insert(last_import_idx + 1, imp)
                    
                    new_content = '\n'.join(lines)
                
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f"Updated {path}")
