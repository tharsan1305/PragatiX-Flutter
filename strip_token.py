import os
import re

base_dir = r"h:\Updating SPDMS\updating_Discipline_Monitor_Frontend\lib\features"
files_modified = 0

for root, dirs, files in os.walk(base_dir):
    for file in files:
        if file.endswith(".dart"):
            filepath = os.path.join(root, file)
            with open(filepath, "r", encoding="utf-8") as f:
                content = f.read()
            
            original_content = content
            
            # Remove field definition
            content = re.sub(r"^\s*final\s+String\s+token;\s*\n", "", content, flags=re.MULTILINE)
            
            # Remove constructor parameters
            content = re.sub(r"required\s+this\.token\s*,?", "", content)
            content = re.sub(r"this\.token\s*,?", "", content)
            
            # Remove widget instantiations (token: widget.token, token: token, token: provider.token)
            content = re.sub(r"token\s*:\s*[a-zA-Z0-9_\.]+\s*,?", "", content)

            if content != original_content:
                with open(filepath, "w", encoding="utf-8") as f:
                    f.write(content)
                files_modified += 1

print(f"Removed token from {files_modified} files.")
