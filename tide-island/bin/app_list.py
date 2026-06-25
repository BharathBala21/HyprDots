#!/usr/bin/env python3
import os
import json
import re
import sys
import argparse

USAGE_FILE = os.path.expanduser('~/.cache/tide-island/app_usage.json')

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
                    if key in ('Name', 'Exec', 'Icon', 'Comment', 'GenericName', 'Keywords', 'NoDisplay', 'Hidden'):
                        entry[key] = val
    except Exception:
        return None
    return entry

def track_app(filename):
    os.makedirs(os.path.dirname(USAGE_FILE), exist_ok=True)
    try:
        if os.path.exists(USAGE_FILE):
            with open(USAGE_FILE, 'r', encoding='utf-8') as f:
                counts = json.load(f)
                if not isinstance(counts, dict):
                    counts = {}
        else:
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
    try:
        if os.path.exists(USAGE_FILE):
            with open(USAGE_FILE, 'r', encoding='utf-8') as f:
                usage_counts = json.load(f)
                if not isinstance(usage_counts, dict):
                    usage_counts = {}
    except Exception:
        pass

    dirs = [
        os.path.expanduser('~/.local/share/applications'),
        '/usr/share/applications'
    ]
    apps = {}
    for d in dirs:
        if not os.path.exists(d):
            continue
        try:
            filenames = os.listdir(d)
        except Exception:
            continue
        for filename in filenames:
            if not filename.endswith('.desktop'):
                continue
            if filename in apps:
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
            
            apps[filename] = {
                'filename': filename,
                'name': name,
                'exec': exec_cmd,
                'icon': icon,
                'description': comment or generic,
                'search': f"{name} {comment} {generic} {keywords}".lower()
            }
            
    sorted_apps = sorted(
        apps.values(),
        key=lambda x: (-usage_counts.get(x['filename'], 0), x['name'].lower())
    )
    return sorted_apps

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--track', type=str, help='Track app usage')
    args = parser.parse_args()
    if args.track:
        track_app(args.track)
    else:
        print(json.dumps(get_apps()))
