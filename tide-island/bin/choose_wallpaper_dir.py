#!/usr/bin/env python3
import os
import sys
import json
import subprocess

def choose_directory(initial_dir):
    initial_dir = os.path.expanduser(initial_dir or "~/Pictures/Wallpapers")
    if not os.path.exists(initial_dir):
        initial_dir = os.path.expanduser("~")

    if not initial_dir.endswith("/"):
        initial_dir += "/"

    # 1. Try zenity directory selection
    try:
        res = subprocess.run(
            ["zenity", "--file-selection", "--directory", "--title=Select Wallpaper Directory", f"--filename={initial_dir}"],
            capture_output=True,
            text=True,
            check=False
        )
        if res.returncode == 0:
            selected = res.stdout.strip()
            if selected and os.path.exists(selected) and os.path.isdir(selected):
                return os.path.abspath(selected)
    except Exception:
        pass

    # 2. Try kdialog fallback
    try:
        res = subprocess.run(
            ["kdialog", "--getexistingdirectory", initial_dir, "--title", "Select Wallpaper Directory"],
            capture_output=True,
            text=True,
            check=False
        )
        if res.returncode == 0:
            selected = res.stdout.strip()
            if selected and os.path.exists(selected) and os.path.isdir(selected):
                return os.path.abspath(selected)
    except Exception:
        pass

    # 3. Try yad fallback
    try:
        res = subprocess.run(
            ["yad", "--file", "--directory", f"--filename={initial_dir}", "--title=Select Wallpaper Directory"],
            capture_output=True,
            text=True,
            check=False
        )
        if res.returncode == 0:
            selected = res.stdout.strip()
            if selected and os.path.exists(selected) and os.path.isdir(selected):
                return os.path.abspath(selected)
    except Exception:
        pass

    return None

def main():
    initial_path = sys.argv[1] if len(sys.argv) > 1 else "~/Pictures/Wallpapers"
    selected = choose_directory(initial_path)

    if selected:
        # Update userconfig.json directly as well
        userconfig_path = os.path.expanduser("~/.config/tide-island/userconfig.json")
        try:
            cfg = {}
            if os.path.exists(userconfig_path):
                with open(userconfig_path, 'r') as f:
                    cfg = json.load(f)
            cfg['wallpaperFolder'] = selected
            os.makedirs(os.path.dirname(userconfig_path), exist_ok=True)
            with open(userconfig_path, 'w') as f:
                json.dump(cfg, f, indent=4)
        except Exception as e:
            print(f"Error saving to userconfig.json: {e}", file=sys.stderr)

        print(json.dumps({"status": "success", "folder": selected}))
    else:
        print(json.dumps({"status": "cancelled"}))

if __name__ == "__main__":
    main()
