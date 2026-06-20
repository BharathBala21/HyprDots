#!/usr/bin/env python3
import subprocess
import json
import os
import re

def get_clipboard_history():
    try:
        # Run cliphist list to retrieve all items
        result = subprocess.run(['cliphist', 'list'], capture_output=True, text=True, check=True)
        lines = result.stdout.strip().split('\n')
        entries = []
        
        # Ensure thumbnail directory exists
        thumbnail_dir = os.path.expanduser('~/.cache/cliphist/thumbnails')
        os.makedirs(thumbnail_dir, exist_ok=True)
        
        for line in lines:
            if not line:
                continue
            parts = line.split('\t', 1)
            if len(parts) == 2:
                entry_id, content = parts
                entry_id = entry_id.strip()
                content = content.strip()
                is_image = content.startswith('[[ binary data')
                thumbnail_path = ""
                
                if is_image:
                    # Extract extension from content e.g., "[[ binary data 240.23 KB png ]]"
                    match = re.search(r'(png|jpg|jpeg|bmp|gif)\s*\]\]$', content, re.IGNORECASE)
                    ext = match.group(1).lower() if match else 'png'
                    thumbnail_path = os.path.join(thumbnail_dir, f"{entry_id}.{ext}")
                    
                    if not os.path.exists(thumbnail_path):
                        try:
                            # Run cliphist decode using input pipe
                            decode_proc = subprocess.Popen(['cliphist', 'decode'], stdin=subprocess.PIPE, stdout=subprocess.PIPE)
                            stdout, _ = decode_proc.communicate(input=entry_id.encode('utf-8'))
                            if decode_proc.returncode == 0 and len(stdout) > 0:
                                with open(thumbnail_path, 'wb') as f:
                                    f.write(stdout)
                            else:
                                thumbnail_path = ""
                        except Exception as e:
                            thumbnail_path = ""
                
                # Format preview
                preview = "🖼️ [Image Data]" if is_image else content
                if len(preview) > 120:
                    preview = preview[:120] + "..."
                    
                entries.append({
                    'id': entry_id,
                    'raw': line,
                    'content': content,
                    'preview': preview,
                    'is_image': is_image,
                    'thumbnail': f"file://{thumbnail_path}" if thumbnail_path else ""
                })
        return entries
    except Exception as e:
        return []

if __name__ == '__main__':
    print(json.dumps(get_clipboard_history()))
