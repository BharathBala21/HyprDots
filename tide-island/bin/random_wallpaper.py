#!/usr/bin/env python3
import os
import sys
import json
import random
import argparse
import subprocess
import configparser

def get_current_wallpaper(userconfig_path, waypaper_config_path):
    if os.path.exists(userconfig_path):
        try:
            with open(userconfig_path, 'r') as f:
                data = json.load(f)
                wp = data.get('wallpaperPath')
                if wp and os.path.exists(os.path.expanduser(wp)):
                    return os.path.abspath(os.path.expanduser(wp))
        except Exception:
            pass

    if os.path.exists(waypaper_config_path):
        try:
            config = configparser.ConfigParser()
            config.read(waypaper_config_path)
            if 'Settings' in config and 'wallpaper' in config['Settings']:
                wp = os.path.expanduser(config['Settings']['wallpaper'])
                if os.path.exists(wp):
                    return os.path.abspath(wp)
        except Exception:
            pass

    return ""

def get_wallpaper_folder(userconfig_path, waypaper_config_path, cli_folder=None):
    if cli_folder and os.path.exists(os.path.expanduser(cli_folder)):
        return os.path.abspath(os.path.expanduser(cli_folder))

    if os.path.exists(userconfig_path):
        try:
            with open(userconfig_path, 'r') as f:
                data = json.load(f)
                folder = data.get('wallpaperFolder')
                if folder and os.path.exists(os.path.expanduser(folder)):
                    return os.path.abspath(os.path.expanduser(folder))
        except Exception:
            pass

    if os.path.exists(waypaper_config_path):
        try:
            config = configparser.ConfigParser()
            config.read(waypaper_config_path)
            if 'Settings' in config and 'folder' in config['Settings']:
                folder = os.path.expanduser(config['Settings']['folder'])
                if os.path.exists(folder):
                    return os.path.abspath(folder)
        except Exception:
            pass

    default_folder = os.path.expanduser("~/Pictures/Wallpapers")
    if os.path.exists(default_folder):
        return os.path.abspath(default_folder)
    return default_folder

def get_theme_mode(userconfig_path):
    theme_cache = os.path.expanduser("~/.cache/tide-island/theme_mode")
    if os.path.exists(theme_cache):
        try:
            with open(theme_cache, 'r') as f:
                m = f.read().strip().lower()
                if m in ["dark", "light"]:
                    return m
        except Exception:
            pass

    if os.path.exists(userconfig_path):
        try:
            with open(userconfig_path, 'r') as f:
                data = json.load(f)
                m = data.get('themeMode', '').strip().lower()
                if m in ["dark", "light"]:
                    return m
        except Exception:
            pass

    return "dark"

def scan_wallpapers(folder_path):
    valid_exts = {'.png', '.jpg', '.jpeg', '.webp'}
    wallpapers = []
    if not os.path.exists(folder_path) or not os.path.isdir(folder_path):
        return wallpapers

    try:
        for entry in os.listdir(folder_path):
            full_path = os.path.join(folder_path, entry)
            if os.path.isfile(full_path):
                ext = os.path.splitext(entry)[1].lower()
                if ext in valid_exts:
                    wallpapers.append(os.path.abspath(full_path))
    except Exception as e:
        print(f"Error reading folder: {e}", file=sys.stderr)

    return wallpapers

def main():
    parser = argparse.ArgumentParser(description="Switch to a random wallpaper in HyprDots / Tide-Island")
    parser.add_argument("--folder", help="Custom wallpaper folder")
    parser.add_argument("--notify", action="store_true", help="Force display notification")
    parser.add_argument("--silent", action="store_true", help="Suppress notification")
    args = parser.parse_args()

    userconfig_path = os.path.expanduser("~/.config/tide-island/userconfig.json")
    waypaper_config_path = os.path.expanduser("~/.config/waypaper/config.ini")

    folder_path = get_wallpaper_folder(userconfig_path, waypaper_config_path, args.folder)
    current_wp = get_current_wallpaper(userconfig_path, waypaper_config_path)

    wallpapers = scan_wallpapers(folder_path)
    if not wallpapers:
        res = {"status": "error", "message": f"No wallpapers found in {folder_path}"}
        print(json.dumps(res))
        sys.exit(1)

    # Pick random wallpaper, filtering out current if multiple choices exist
    candidates = [w for w in wallpapers if os.path.abspath(w) != os.path.abspath(current_wp)]
    if not candidates:
        candidates = wallpapers

    chosen_wallpaper = random.choice(candidates)
    wp_name = os.path.basename(chosen_wallpaper)

    # 1. Apply wallpaper via waypaper
    try:
        subprocess.run(["waypaper", "--wallpaper", chosen_wallpaper], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception as e:
        print(f"Error running waypaper: {e}", file=sys.stderr)

    # 2. Update userconfig.json
    try:
        cfg = {}
        if os.path.exists(userconfig_path):
            with open(userconfig_path, 'r') as f:
                cfg = json.load(f)
        cfg['wallpaperPath'] = chosen_wallpaper
        os.makedirs(os.path.dirname(userconfig_path), exist_ok=True)
        with open(userconfig_path, 'w') as f:
            json.dump(cfg, f, indent=4)
    except Exception as e:
        print(f"Error updating userconfig.json: {e}", file=sys.stderr)

    # 3. Apply matugen Material You colors
    theme_mode = get_theme_mode(userconfig_path)
    try:
        subprocess.Popen(
            ["matugen", "image", "--mode", theme_mode, "-v", "--source-color-index", "0", chosen_wallpaper],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True
        )
    except Exception as e:
        print(f"Error starting matugen: {e}", file=sys.stderr)

    # 4. Check notification preferences
    notify_enabled = args.notify
    if not args.silent and not args.notify:
        try:
            if os.path.exists(userconfig_path):
                with open(userconfig_path, 'r') as f:
                    data = json.load(f)
                    notify_enabled = data.get('autoWallpaperNotification', True)
        except Exception:
            notify_enabled = True

    if notify_enabled:
        # Display island toast via quickshell IPC if possible
        try:
            island_dir = os.path.expanduser("~/.local/src/HyprDots/tide-island")
            if not os.path.exists(island_dir):
                island_dir = "/usr/share/tide-island"
            subprocess.Popen(
                ["qs", "ipc", "-p", island_dir, "call", "island", "showWallpaperToast", wp_name],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True
            )
        except Exception:
            pass

        # Send desktop notification
        try:
            subprocess.Popen(
                ["notify-send", "-a", "Tide Island", "-i", chosen_wallpaper, "Wallpaper Changed", wp_name],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True
            )
        except Exception:
            pass

    output = {
        "status": "success",
        "wallpaper": chosen_wallpaper,
        "name": wp_name,
        "folder": folder_path
    }
    print(json.dumps(output))

if __name__ == "__main__":
    main()
