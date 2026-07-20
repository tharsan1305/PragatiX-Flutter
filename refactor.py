import os
import re

features = ['admin', 'student', 'teacher', 'captain']
base_dir = r"h:\Updating SPDMS\updating_Discipline_Monitor_Frontend\lib\features"

for feature in features:
    directory = os.path.join(base_dir, feature)
    ProxyClass = f"{feature.capitalize()}ProxyService"
    proxy_import = f"import 'package:spdms_app/features/{feature}/services/{feature}_proxy_service.dart';"

    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(".dart") and "services" not in root:
                filepath = os.path.join(root, file)
                with open(filepath, "r", encoding="utf-8") as f:
                    content = f.read()
                
                # Check for direct http calls
                if "http.get(" in content or "http.post(" in content or "http.put(" in content or "http.delete(" in content:
                    print(f"Refactoring {filepath}")
                    
                    # Replace import
                    content = re.sub(
                        r"import 'package:http/http\.dart' as http;",
                        proxy_import,
                        content
                    )

                    # Replace methods
                    content = content.replace("http.get(", f"{ProxyClass}.get(")
                    content = content.replace("http.post(", f"{ProxyClass}.post(")
                    content = content.replace("http.put(", f"{ProxyClass}.put(")
                    content = content.replace("http.delete(", f"{ProxyClass}.delete(")

                    with open(filepath, "w", encoding="utf-8") as f:
                        f.write(content)
                    
                    print("Done")
