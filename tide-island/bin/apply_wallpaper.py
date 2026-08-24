#!/usr/bin/env python3
import os
import sys
import json
import hashlib
import argparse
import subprocess
import configparser

VIDEO_EXTS = {'.mp4', '.webm', '.mkv', '.mov', '.avi', '.flv', '.m4v', '.gif'}
IMAGE_EXTS = {'.png', '.jpg', '.jpeg', '.webp', '.bmp', '.avif'}

def is_video_file(path):
    if not path:
        return False
    ext = os.path.splitext(path)[1].lower()
    return ext in VIDEO_EXTS

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

def get_fill_mode(waypaper_config_path):
    if os.path.exists(waypaper_config_path):
        try:
            config = configparser.ConfigParser()
            config.read(waypaper_config_path)
            if 'Settings' in config and 'fill' in config['Settings']:
                return config['Settings']['fill'].lower()
        except Exception:
            pass
    return "fill"

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

    default_dir = os.path.expanduser("~/Pictures/Wallpapers")
    if os.path.exists(default_dir) and os.path.isdir(default_dir):
        for f in sorted(os.listdir(default_dir)):
            ext = os.path.splitext(f)[1].lower()
            if ext in IMAGE_EXTS or ext in VIDEO_EXTS:
                return os.path.join(default_dir, f)

    return ""

def update_userconfig(userconfig_path, wallpaper_path):
    try:
        cfg = {}
        if os.path.exists(userconfig_path):
            with open(userconfig_path, 'r') as f:
                cfg = json.load(f)
        cfg['wallpaperPath'] = wallpaper_path
        os.makedirs(os.path.dirname(userconfig_path), exist_ok=True)
        with open(userconfig_path, 'w') as f:
            json.dump(cfg, f, indent=4)
    except Exception as e:
        print(f"Error updating userconfig.json: {e}", file=sys.stderr)

def update_waypaper_config(waypaper_config_path, wallpaper_path, is_video):
    if not os.path.exists(waypaper_config_path):
        return
    try:
        config = configparser.ConfigParser()
        config.read(waypaper_config_path)
        if 'Settings' not in config:
            config['Settings'] = {}
        config['Settings']['wallpaper'] = wallpaper_path
        if is_video:
            config['Settings']['backend'] = 'mpvpaper'
        else:
            config['Settings']['backend'] = 'hyprpaper'
        with open(waypaper_config_path, 'w') as f:
            config.write(f)
    except Exception as e:
        print(f"Error updating waypaper config: {e}", file=sys.stderr)

def stop_video_wallpaper():
    try:
        subprocess.run(["pkill", "-9", "-f", "mpvpaper"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(["pkill", "-9", "-f", "mpvpaper-holder"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

def get_or_create_video_thumbnail(video_path):
    cache_dir = os.path.expanduser("~/.cache/tide-island/thumbnails")
    os.makedirs(cache_dir, exist_ok=True)
    h = hashlib.md5(video_path.encode('utf-8')).hexdigest()
    thumb_path = os.path.join(cache_dir, f"{h}.jpg")

    need_gen = True
    if os.path.exists(thumb_path):
        try:
            if os.path.getmtime(video_path) <= os.path.getmtime(thumb_path):
                need_gen = False
        except Exception:
            pass

    if need_gen:
        try:
            subprocess.run(
                ["ffmpeg", "-y", "-ss", "00:00:01", "-i", video_path, "-vframes", "1",
                 "-vf", "scale=240:135:force_original_aspect_ratio=decrease,pad=240:135:(ow-iw)/2:(oh-ih)/2",
                 thumb_path],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                check=False
            )
        except Exception as e:
            print(f"Error generating video thumbnail: {e}", file=sys.stderr)

    return thumb_path if os.path.exists(thumb_path) else ""

def apply_matugen_theme(source_image, mode):
    if not source_image or not os.path.exists(source_image):
        return
    try:
        subprocess.Popen(
            ["matugen", "image", "--mode", mode, "-v", "--source-color-index", "0", source_image],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True
        )
    except Exception as e:
        print(f"Error running matugen: {e}", file=sys.stderr)

def apply_video_wallpaper(video_path, fill_mode="fill"):
    stop_video_wallpaper()
    
    fill_opt = "--panscan=1.0"
    if fill_mode == "stretch":
        fill_opt = "--keepaspect=no"
    elif fill_mode == "fit":
        fill_opt = "--panscan=0.0"
    elif fill_mode == "fill":
        fill_opt = "--panscan=1.0"

    mpv_opts = f"loop no-audio --hwdec=auto {fill_opt} --video-unscaled=no"
    cmd = [
        "mpvpaper",
        "--fork",
        "-p",
        "-s",
        "-a", "FULL",
        "-o", mpv_opts,
        "*",
        video_path
    ]
    try:
        subprocess.Popen(
            cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True
        )
    except Exception as e:
        print(f"Error starting mpvpaper: {e}", file=sys.stderr)

def apply_image_wallpaper(image_path):
    stop_video_wallpaper()

    try:
        # Use waypaper CLI if available
        res = subprocess.run(["waypaper", "--wallpaper", image_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if res.returncode != 0:
            # Fallback to direct hyprctl hyprpaper
            subprocess.run(["hyprctl", "hyprpaper", "preload", image_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run(["hyprctl", "hyprpaper", "wallpaper", f",{image_path}"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        try:
            subprocess.run(["hyprctl", "hyprpaper", "preload", image_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run(["hyprctl", "hyprpaper", "wallpaper", f",{image_path}"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception as e:
            print(f"Error applying image wallpaper: {e}", file=sys.stderr)

def main():
    parser = argparse.ArgumentParser(description="Unified Wallpaper Applicator for HyprDots / Tide-Island")
    parser.add_argument("path", nargs="?", default="", help="Path to image or video wallpaper")
    parser.add_argument("--wallpaper", "-w", dest="wallpaper_opt", help="Path to wallpaper")
    parser.add_argument("--fill", choices=["fill", "fit", "stretch"], help="Fill mode (fill, fit, stretch)")
    parser.add_argument("--mode", "-m", choices=["dark", "light"], help="Theme mode for Matugen")
    parser.add_argument("--no-matugen", action="store_true", help="Skip running matugen (e.g. for live previews)")
    parser.add_argument("--restore", action="store_true", help="Restore active wallpaper from config")
    parser.add_argument("--stop-video", action="store_true", help="Stop video wallpaper")
    args = parser.parse_args()

    if args.stop_video:
        stop_video_wallpaper()
        sys.exit(0)

    userconfig_path = os.path.expanduser("~/.config/tide-island/userconfig.json")
    waypaper_config_path = os.path.expanduser("~/.config/waypaper/config.ini")

    target_wallpaper = args.wallpaper_opt or args.path

    if args.restore or not target_wallpaper:
        target_wallpaper = get_current_wallpaper(userconfig_path, waypaper_config_path)

    if not target_wallpaper or not os.path.exists(os.path.expanduser(target_wallpaper)):
        print(f"Error: Wallpaper file not found: {target_wallpaper}", file=sys.stderr)
        sys.exit(1)

    target_wallpaper = os.path.abspath(os.path.expanduser(target_wallpaper))
    is_video = is_video_file(target_wallpaper)
    fill_mode = args.fill or get_fill_mode(waypaper_config_path)

    # 1. Apply wallpaper
    if is_video:
        apply_video_wallpaper(target_wallpaper, fill_mode)
    else:
        apply_image_wallpaper(target_wallpaper)

    # 2. Persist configuration
    update_userconfig(userconfig_path, target_wallpaper)
    update_waypaper_config(waypaper_config_path, target_wallpaper, is_video)

    # 3. Apply Matugen Material You theme
    if not args.no_matugen:
        theme_mode = args.mode or get_theme_mode(userconfig_path)
        if is_video:
            thumb = get_or_create_video_thumbnail(target_wallpaper)
            if thumb:
                apply_matugen_theme(thumb, theme_mode)
        else:
            apply_matugen_theme(target_wallpaper, theme_mode)

    print(json.dumps({
        "status": "success",
        "wallpaper": target_wallpaper,
        "isVideo": is_video,
        "fill": fill_mode
    }))

if __name__ == "__main__":
    main()
