#!/usr/bin/env python3
import os
import json
import re
import sys
import argparse

USAGE_FILE = os.path.expanduser('~/.cache/tide-island/app_usage.json')
CACHE_FILE = os.path.expanduser('~/.cache/tide-island/app_cache.json')

APP_DIRS = [
    os.path.expanduser('~/.local/share/applications'),
    '/usr/local/share/applications',
    '/usr/share/applications'
]

CATEGORY_MAP = {
    'development': 'dev',
    'ide': 'dev',
    'texteditor': 'dev',
    'debugger': 'dev',
    'programming': 'dev',
    'network': 'web',
    'webbrowser': 'web',
    'email': 'web',
    'chat': 'web',
    'instantmessaging': 'web',
    'feed': 'web',
    'audiovideo': 'media',
    'audio': 'media',
    'video': 'media',
    'music': 'media',
    'player': 'media',
    'recorder': 'media',
    'graphics': 'media',
    'photography': 'media',
    'system': 'system',
    'settings': 'system',
    'packagemanager': 'system',
    'monitor': 'system',
    'terminalemulator': 'system',
    'utility': 'tools',
    'accessories': 'tools',
    'filemanager': 'tools',
    'calculator': 'tools',
    'core': 'tools',
    'game': 'games'
}

def normalize_category(raw_cats):
    if not raw_cats:
        return 'tools'
    cats = [c.strip().lower() for c in raw_cats.split(';') if c.strip()]
    for c in cats:
        if c in CATEGORY_MAP:
            return CATEGORY_MAP[c]
    return 'tools'

def parse_desktop_file(filepath):
    entry = {}
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            in_group = False
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                if line.startswith('[') and line.endswith(']'):
                    if line == '[Desktop Entry]':
                        in_group = True
                    else:
                        in_group = False
                    continue
                if in_group and '=' in line:
                    parts = line.split('=', 1)
                    key = parts[0].strip()
                    val = parts[1].strip()
                    if key in ('Name', 'Exec', 'Icon', 'Comment', 'GenericName', 'Keywords', 'Categories', 'Terminal', 'NoDisplay', 'Hidden'):
                        entry[key] = val
    except Exception:
        return None
    return entry

def track_app(filename):
    os.makedirs(os.path.dirname(USAGE_FILE), exist_ok=True)
    counts = {}
    if os.path.exists(USAGE_FILE):
        try:
            with open(USAGE_FILE, 'r', encoding='utf-8') as f:
                counts = json.load(f)
                if not isinstance(counts, dict):
                    counts = {}
        except Exception:
            counts = {}
    
    counts[filename] = counts.get(filename, 0) + 1
    
    try:
        with open(USAGE_FILE, 'w', encoding='utf-8') as f:
            json.dump(counts, f, indent=2)
    except Exception as e:
        print(f"Error writing usage counts: {e}", file=sys.stderr)

def get_apps():
    usage_counts = {}
    if os.path.exists(USAGE_FILE):
        try:
            with open(USAGE_FILE, 'r', encoding='utf-8') as f:
                usage_counts = json.load(f)
                if not isinstance(usage_counts, dict):
                    usage_counts = {}
        except Exception:
            pass

    cache_valid = False
    apps = {}

    if os.path.exists(CACHE_FILE):
        try:
            cache_mtime = os.path.getmtime(CACHE_FILE)
            dir_mtimes = [os.path.getmtime(d) for d in APP_DIRS if os.path.exists(d)]
            if dir_mtimes and cache_mtime > max(dir_mtimes):
                with open(CACHE_FILE, 'r', encoding='utf-8') as f:
                    cached_data = json.load(f)
                    if isinstance(cached_data, dict) and len(cached_data) > 0:
                        apps = cached_data
                        cache_valid = True
        except Exception:
            cache_valid = False

    if not cache_valid:
        apps = {}
        for d in APP_DIRS:
            if not os.path.exists(d):
                continue
            try:
                filenames = os.listdir(d)
            except Exception:
                continue
            for filename in filenames:
                if not filename.endswith('.desktop') or filename in apps:
                    continue
                filepath = os.path.join(d, filename)
                entry = parse_desktop_file(filepath)
                if not entry:
                    continue
                
                if entry.get('NoDisplay') == 'true' or entry.get('Hidden') == 'true':
                    continue
                if 'Name' not in entry or 'Exec' not in entry:
                    continue
                    
                exec_cmd = entry['Exec']
                exec_cmd = re.sub(r'%[fFuUdDnNicCkv]', '', exec_cmd).strip()
                
                name = entry['Name']
                icon = entry.get('Icon', 'application-x-executable')
                comment = entry.get('Comment', '')
                generic = entry.get('GenericName', '')
                keywords = entry.get('Keywords', '').replace(';', ' ')
                raw_categories = entry.get('Categories', '')
                category = normalize_category(raw_categories)
                is_terminal = entry.get('Terminal', 'false').lower() == 'true'
                
                apps[filename] = {
                    'filename': filename,
                    'name': name,
                    'exec': exec_cmd,
                    'icon': icon,
                    'description': comment or generic,
                    'category': category,
                    'rawCategories': raw_categories,
                    'terminal': is_terminal,
                    'search': f"{name} {comment} {generic} {keywords} {raw_categories} {exec_cmd}".lower()
                }
        
        try:
            os.makedirs(os.path.dirname(CACHE_FILE), exist_ok=True)
            with open(CACHE_FILE, 'w', encoding='utf-8') as f:
                json.dump(apps, f)
        except Exception:
            pass

    # Attach live usage count and sort
    app_list = []
    for filename, app in apps.items():
        app_copy = dict(app)
        count = usage_counts.get(filename, 0)
        app_copy['count'] = count
        app_list.append(app_copy)

    app_list.sort(key=lambda x: (-x['count'], x['name'].lower()))
    return app_list

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--track', type=str, help='Track app usage')
    args = parser.parse_args()
    if args.track:
        track_app(args.track)
    else:
        print(json.dumps(get_apps()))
