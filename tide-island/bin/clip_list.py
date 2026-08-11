#!/usr/bin/env python3
import subprocess
import json
import os
import re
import sys

PINNED_FILE = os.path.expanduser('~/.config/cliphist/pinned.json')

def ensure_dirs():
    os.makedirs(os.path.dirname(PINNED_FILE), exist_ok=True)

def load_pinned_descriptions():
    ensure_dirs()
    if not os.path.exists(PINNED_FILE):
        return []
    try:
        with open(PINNED_FILE, 'r') as f:
            data = json.load(f)
            if isinstance(data, list):
                return data
            return []
    except Exception:
        return []

def save_pinned_descriptions(pinned):
    ensure_dirs()
    try:
        with open(PINNED_FILE, 'w') as f:
            json.dump(pinned, f, indent=2)
    except Exception as e:
        sys.stderr.write(f"Error saving pinned: {e}\n")

def get_content_description(item_id):
    try:
        result = subprocess.run(['cliphist', 'list'], capture_output=True, text=True, check=True)
        lines = result.stdout.strip().split('\n')
        for line in lines:
            if not line:
                continue
            parts = line.split('\t', 1)
            if len(parts) == 2 and parts[0].strip() == str(item_id).strip():
                return parts[1].strip()
    except Exception:
        pass
    return None

def get_clipboard_history():
    try:
        result = subprocess.run(['cliphist', 'list'], capture_output=True, text=True, check=True)
        lines = result.stdout.strip().split('\n')
        entries = []
        
        thumbnail_dir = os.path.expanduser('~/.cache/cliphist/thumbnails')
        os.makedirs(thumbnail_dir, exist_ok=True)
        
        pinned_descs = set(load_pinned_descriptions())
        
        recent_count = 0
        for line in lines:
            if not line:
                continue
            parts = line.split('\t', 1)
            if len(parts) == 2:
                entry_id, content = parts
                entry_id = entry_id.strip()
                content = content.strip()
                
                is_pinned = content in pinned_descs
                if not is_pinned and recent_count >= 150:
                    continue
                if not is_pinned:
                    recent_count += 1
                
                is_image = content.startswith('[[ binary data')
                thumbnail_path = ""
                
                if is_image:
                    match = re.search(r'(png|jpg|jpeg|bmp|gif)\s*\]\]$', content, re.IGNORECASE)
                    ext = match.group(1).lower() if match else 'png'
                    thumbnail_path = os.path.join(thumbnail_dir, f"{entry_id}.{ext}")
                    
                    if not os.path.exists(thumbnail_path):
                        try:
                            decode_proc = subprocess.Popen(['cliphist', 'decode'], stdin=subprocess.PIPE, stdout=subprocess.PIPE)
                            stdout, _ = decode_proc.communicate(input=entry_id.encode('utf-8'))
                            if decode_proc.returncode == 0 and len(stdout) > 0:
                                with open(thumbnail_path, 'wb') as f:
                                    f.write(stdout)
                            else:
                                thumbnail_path = ""
                        except Exception:
                            thumbnail_path = ""
                
                preview = "🖼️ [Image Data]" if is_image else content
                if len(preview) > 120:
                    preview = preview[:120] + "..."
                
                entries.append({
                    'id': entry_id,
                    'raw': line,
                    'content': content,
                    'preview': preview,
                    'is_image': is_image,
                    'thumbnail': f"file://{thumbnail_path}" if thumbnail_path else "",
                    'is_pinned': is_pinned
                })
        return entries
    except Exception:
        return []

def pin_item(item_id):
    content_desc = get_content_description(item_id)
    if not content_desc:
        return False
    pinned = load_pinned_descriptions()
    if content_desc not in pinned:
        pinned.append(content_desc)
        save_pinned_descriptions(pinned)
    return True

def unpin_item(item_id):
    pinned = load_pinned_descriptions()
    removed = False
    
    # If it is a numeric ID, try to look up its content description
    if str(item_id).isdigit():
        content_desc = get_content_description(item_id)
        if content_desc and content_desc in pinned:
            pinned.remove(content_desc)
            removed = True
            
    # Otherwise or if lookup failed, treat item_id as the content description directly
    if not removed and item_id in pinned:
        pinned.remove(item_id)
        removed = True
        
    if removed:
        save_pinned_descriptions(pinned)
    return removed

def wipe_unpinned():
    history = get_clipboard_history()
    thumbnail_dir = os.path.expanduser('~/.cache/cliphist/thumbnails')
    for item in history:
        if not item.get('is_pinned', False):
            subprocess.run(['cliphist', 'delete'], input=item['raw'].encode('utf-8'), check=False)
            if item.get('is_image', False):
                match = re.search(r'(png|jpg|jpeg|bmp|gif)\s*\]\]$', item['content'], re.IGNORECASE)
                ext = match.group(1).lower() if match else 'png'
                thumb_path = os.path.join(thumbnail_dir, f"{item['id']}.{ext}")
                if os.path.exists(thumb_path):
                    try:
                        os.remove(thumb_path)
                    except Exception:
                        pass
    return True

def wipe_pinned():
    history = get_clipboard_history()
    thumbnail_dir = os.path.expanduser('~/.cache/cliphist/thumbnails')
    for item in history:
        if item.get('is_pinned', False):
            subprocess.run(['cliphist', 'delete'], input=item['raw'].encode('utf-8'), check=False)
            if item.get('is_image', False):
                match = re.search(r'(png|jpg|jpeg|bmp|gif)\s*\]\]$', item['content'], re.IGNORECASE)
                ext = match.group(1).lower() if match else 'png'
                thumb_path = os.path.join(thumbnail_dir, f"{item['id']}.{ext}")
                if os.path.exists(thumb_path):
                    try:
                        os.remove(thumb_path)
                    except Exception:
                        pass
    save_pinned_descriptions([])
    return True

if __name__ == '__main__':
    ensure_dirs()
    if len(sys.argv) > 1:
        arg = sys.argv[1]
        if arg == '--pinned':
            history = get_clipboard_history()
            pinned_items = [item for item in history if item['is_pinned']]
            print(json.dumps(pinned_items))
        elif arg == '--pin' and len(sys.argv) > 2:
            item_id = sys.argv[2]
            success = pin_item(item_id)
            print(json.dumps({'success': success}))
        elif arg == '--unpin' and len(sys.argv) > 2:
            item_id = sys.argv[2]
            success = unpin_item(item_id)
            print(json.dumps({'success': success}))
        elif arg == '--wipe-unpinned':
            success = wipe_unpinned()
            print(json.dumps({'success': success}))
        elif arg == '--wipe-pinned':
            success = wipe_pinned()
            print(json.dumps({'success': success}))
        else:
            print(json.dumps(get_clipboard_history()))
    else:
        print(json.dumps(get_clipboard_history()))
