#!/usr/bin/env python3
import subprocess
import json

def get_clipboard_history():
    try:
        # Run cliphist list to retrieve all items
        result = subprocess.run(['cliphist', 'list'], capture_output=True, text=True, check=True)
        lines = result.stdout.strip().split('\n')
        entries = []
        for line in lines:
            if not line:
                continue
            parts = line.split('\t', 1)
            if len(parts) == 2:
                entry_id, content = parts
                entry_id = entry_id.strip()
                content = content.strip()
                is_image = content.startswith('[[ binary data')
                
                # Format preview
                preview = "🖼️ [Image Data]" if is_image else content
                if len(preview) > 120:
                    preview = preview[:120] + "..."
                    
                entries.append({
                    'id': entry_id,
                    'raw': line, # cliphist needs the exact raw line for decoding/deletion
                    'content': content,
                    'preview': preview,
                    'is_image': is_image
                })
        return entries
    except Exception as e:
        return []

if __name__ == '__main__':
    print(json.dumps(get_clipboard_history()))
