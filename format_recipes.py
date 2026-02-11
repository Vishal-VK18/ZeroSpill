import json
import os

def format_recipe_json(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    
    print(f"Formatted: {file_path}")

recipes_dir = r"d:\Zerospill\ZeroSpill\assets\recipes"

for filename in os.listdir(recipes_dir):
    if filename.endswith('.json'):
        file_path = os.path.join(recipes_dir, filename)
        try:
            format_recipe_json(file_path)
        except Exception as e:
            print(f"Error formatting {filename}: {e}")

print("\nAll recipe files formatted!")
