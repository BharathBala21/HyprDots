#!/usr/bin/env python3
import os
import sys
import json
import configparser

VIDEO_EXTS = {'.mp4', '.webm', '.mkv', '.mov', '.avi', '.flv', '.m4v', '.gif'}

def main():
    if len(sys.argv) < 2:
        sys.exit(1)
    new_path = os.path.abspath(os.path.expanduser(sys.argv[1]))
    config_path = os.path.expanduser("~/.config/tide-island/userconfig.json")
    if os.path.exists(config_path):
        try:
            with open(config_path, 'r') as f:
                config = json.load(f)
            config['wallpaperPath'] = new_path
            with open(config_path, 'w') as f:
                json.dump(config, f, indent=4)
        except Exception as e:
            print(f"Error updating config: {e}", file=sys.stderr)

    waypaper_config_path = os.path.expanduser("~/.config/waypaper/config.ini")
    if os.path.exists(waypaper_config_path):
        try:
            ext = os.path.splitext(new_path)[1].lower()
            is_video = ext in VIDEO_EXTS
            cfg = configparser.ConfigParser()
            cfg.read(waypaper_config_path)
            if 'Settings' not in cfg:
                cfg['Settings'] = {}
            cfg['Settings']['wallpaper'] = new_path
            cfg['Settings']['backend'] = 'mpvpaper' if is_video else 'hyprpaper'
            with open(waypaper_config_path, 'w') as f:
                cfg.write(f)
        except Exception:
            pass

if __name__ == "__main__":
    main()
