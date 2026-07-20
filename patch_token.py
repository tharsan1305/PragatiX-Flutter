import os
import re

log_path = r"C:\Users\ADMIN\.gemini\antigravity-ide\brain\d5aaff1e-bf4e-417e-b69b-5c45a391f59d\.system_generated\tasks\task-1540.log"
workspace = r"h:\Updating SPDMS\updating_Discipline_Monitor_Frontend"

with open(log_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

file_edits = {}

for line in lines:
    if "undefined_getter" in line or "undefined_identifier" in line:
        # e.g.: error - The getter 'token' isn't defined for the type 'TeacherDashboard' - lib\features\teacher\pages\teacher_dashboard.dart:33:16 - undefined_getter
        # Try to extract the file path, line, and column
        match = re.search(r"-\s+(lib[\\/].+\.dart):(\d+):(\d+)\s+-", line)
        if match:
            rel_path = match.group(1)
            line_num = int(match.group(2)) - 1 # 0-indexed
            col_num = int(match.group(3))
            
            abs_path = os.path.join(workspace, rel_path)
            
            if abs_path not in file_edits:
                file_edits[abs_path] = []
            
            file_edits[abs_path].append(line_num)

for filepath, lines_to_edit in file_edits.items():
    with open(filepath, "r", encoding="utf-8") as f:
        file_lines = f.readlines()
    
    modified = False
    
    # Process unique lines to avoid double replacement per line if possible
    for ln in set(lines_to_edit):
        if ln < len(file_lines):
            original = file_lines[ln]
            # Priority: replace widget.token, then token
            if "widget.token" in original:
                file_lines[ln] = original.replace("widget.token", "context.read<AuthProvider>().token!")
                modified = True
            elif "token" in original:
                # careful with matching exactly word `token`
                file_lines[ln] = re.sub(r"\btoken\b", "context.read<AuthProvider>().token!", original)
                modified = True
    
    if modified:
        # Reconstruct file content
        content = "".join(file_lines)
        
        # Inject imports if missing
        if "package:provider/provider.dart" not in content:
            content = "import 'package:provider/provider.dart';\n" + content
        if "auth_provider.dart" not in content:
            content = "import 'package:spdms_app/features/auth/providers/auth_provider.dart';\n" + content
            
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(content)
        
        print(f"Patched {filepath}")
