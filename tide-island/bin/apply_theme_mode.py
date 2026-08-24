#!/usr/bin/env python3
import os
import sys
import json
import hashlib
import subprocess
import configparser

VIDEO_EXTS = {'.mp4', '.webm', '.mkv', '.mov', '.avi', '.flv', '.m4v', '.gif'}
IMAGE_EXTS = {'.png', '.jpg', '.jpeg', '.webp', '.bmp', '.avif'}

def get_current_wallpaper():
    # 1. Try reading ~/.config/tide-island/userconfig.json
    tide_config = os.path.expanduser("~/.config/tide-island/userconfig.json")
    if os.path.exists(tide_config):
        try:
            with open(tide_config, 'r') as f:
                data = json.load(f)
                wp = data.get('wallpaperPath')
                if wp and os.path.exists(os.path.expanduser(wp)):
                    return os.path.abspath(os.path.expanduser(wp))
        except Exception:
            pass

    # 2. Try reading ~/.config/waypaper/config.ini
    waypaper_config = os.path.expanduser("~/.config/waypaper/config.ini")
    if os.path.exists(waypaper_config):
        try:
            config = configparser.ConfigParser()
            config.read(waypaper_config)
            if 'Settings' in config and 'wallpaper' in config['Settings']:
                wp = os.path.expanduser(config['Settings']['wallpaper'])
                if os.path.exists(wp):
                    return os.path.abspath(wp)
        except Exception:
            pass

    # 3. Fallback to ~/Pictures/Wallpapers
    wp_dir = os.path.expanduser("~/Pictures/Wallpapers")
    if os.path.exists(wp_dir) and os.path.isdir(wp_dir):
        for f in sorted(os.listdir(wp_dir)):
            ext = os.path.splitext(f)[1].lower()
            if ext in IMAGE_EXTS or ext in VIDEO_EXTS:
                return os.path.join(wp_dir, f)

    return ""

def main():
    if len(sys.argv) < 2:
        mode = "dark"
    else:
        mode = sys.argv[1].lower()
    
    if mode not in ["dark", "light"]:
        mode = "dark"

    # Save cached mode
    cache_dir = os.path.expanduser("~/.cache/tide-island")
    os.makedirs(cache_dir, exist_ok=True)
    with open(os.path.join(cache_dir, "theme_mode"), "w") as f:
        f.write(mode + "\n")

    # Update userconfig.json if present
    tide_config = os.path.expanduser("~/.config/tide-island/userconfig.json")
    if os.path.exists(tide_config):
        try:
            with open(tide_config, 'r') as f:
                data = json.load(f)
            data['themeMode'] = mode
            with open(tide_config, 'w') as f:
                json.dump(data, f, indent=4)
        except Exception:
            pass

    # Set GNOME / GTK color-scheme via gsettings
    gsettings_mode = "prefer-dark" if mode == "dark" else "prefer-light"
    try:
        subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", gsettings_mode], check=False)
    except Exception:
        pass

    # Set gtk-theme preference
    try:
        gtk_theme = "Adwaita-dark" if mode == "dark" else "Adwaita"
        subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", "gtk-theme", gtk_theme], check=False)
    except Exception:
        pass

    # Run matugen for active wallpaper
    wp = get_current_wallpaper()
    if wp:
        target_img = wp
        ext = os.path.splitext(wp)[1].lower()
        if ext in VIDEO_EXTS:
            h = hashlib.md5(wp.encode('utf-8')).hexdigest()
            thumb_cache_dir = os.path.expanduser("~/.cache/tide-island/thumbnails")
            os.makedirs(thumb_cache_dir, exist_ok=True)
            thumb_path = os.path.join(thumb_cache_dir, f"{h}.jpg")
            if not os.path.exists(thumb_path):
                subprocess.run(
                    ["ffmpeg", "-y", "-ss", "00:00:01", "-i", wp, "-vframes", "1",
                     "-vf", "scale=240:135:force_original_aspect_ratio=decrease,pad=240:135:(ow-iw)/2:(oh-ih)/2",
                     thumb_path],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    check=False
                )
            if os.path.exists(thumb_path):
                target_img = thumb_path

        try:
            subprocess.run(["matugen", "image", "--mode", mode, "-v", "--source-color-index", "0", target_img], check=False)
        except Exception as e:
            print(f"Error running matugen: {e}", file=sys.stderr)

if __name__ == "__main__":
    main()
