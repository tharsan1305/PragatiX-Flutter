import os

base_dir = r"h:\Updating SPDMS\updating_Discipline_Monitor_Frontend\lib\features"

for root, dirs, files in os.walk(base_dir):
    for file in files:
        if file.endswith(".dart"):
            filepath = os.path.join(root, file)
            with open(filepath, "r", encoding="utf-8") as f:
                content = f.read()
            
            if '\ufeff' in content:
                content = content.replace('\ufeff', '')
                with open(filepath, "w", encoding="utf-8") as f:
                    f.write(content)
                print(f"Removed BOM from {filepath}")
