#!/usr/bin/env python3
import os
import sys
import json
import subprocess
import configparser

def get_current_wallpaper():
    # 1. Try reading ~/.config/tide-island/userconfig.json
    tide_config = os.path.expanduser("~/.config/tide-island/userconfig.json")
    if os.path.exists(tide_config):
        try:
            with open(tide_config, 'r') as f:
                data = json.load(f)
                wp = data.get('wallpaperPath')
                if wp and os.path.exists(wp):
                    return wp
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
                    return wp
        except Exception:
            pass

    # 3. Fallback to ~/Pictures/Wallpapers
    wp_dir = os.path.expanduser("~/Pictures/Wallpapers")
    if os.path.exists(wp_dir) and os.path.isdir(wp_dir):
        for f in sorted(os.listdir(wp_dir)):
            if f.lower().endswith(('.png', '.jpg', '.jpeg', '.webp')):
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
        try:
            subprocess.run(["matugen", "image", "--mode", mode, "-v", "--source-color-index", "0", wp], check=False)
        except Exception as e:
            print(f"Error running matugen: {e}", file=sys.stderr)

if __name__ == "__main__":
    main()
