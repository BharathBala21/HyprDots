#!/usr/bin/env python3
import os
import sys
import json
import configparser
import hashlib

def run_background_generator(folder_path, cache_dir):
    try:
        os.nice(19)
    except:
        pass

    try:
        from PIL import Image
    except ImportError:
        return

    import time

    if not os.path.exists(folder_path) or not os.path.isdir(folder_path):
        return

    try:
        files = os.listdir(folder_path)
    except Exception:
        return

    for file in files:
        ext = os.path.splitext(file)[1].lower()
        if ext in ['.png', '.jpg', '.jpeg', '.webp']:
            src_path = os.path.join(folder_path, file)
            h = hashlib.md5(src_path.encode('utf-8')).hexdigest()
            thumb_path = os.path.join(cache_dir, f"{h}.jpg")

            need_gen = True
            if os.path.exists(thumb_path):
                try:
                    if os.path.getmtime(src_path) <= os.path.getmtime(thumb_path):
                        need_gen = False
                except:
                    pass

            if need_gen:
                try:
                    with Image.open(src_path) as img:
                        img.thumbnail((240, 135))
                        if img.mode in ('RGBA', 'LA') or (img.mode == 'P' and 'transparency' in img.info):
                            background = Image.new('RGB', img.size, (0, 0, 0))
                            try:
                                background.paste(img, mask=img.split()[3] if img.mode == 'RGBA' else img.split()[1])
                            except:
                                background.paste(img)
                            img = background
                        elif img.mode != 'RGB':
                            img = img.convert('RGB')
                        img.save(thumb_path, 'JPEG', quality=80)
                except Exception:
                    pass
                time.sleep(0.02)

def main():
    if len(sys.argv) > 1 and sys.argv[1] == "--background-generate":
        if len(sys.argv) > 3:
            run_background_generator(sys.argv[2], sys.argv[3])
        sys.exit(0)

    tide_config_path = os.path.expanduser("~/.config/tide-island/userconfig.json")
    config_path = os.path.expanduser("~/.config/waypaper/config.ini")
    current_wallpaper = ""
    folder_path = os.path.expanduser("~/Pictures/Wallpapers")

    if os.path.exists(tide_config_path):
        try:
            with open(tide_config_path, 'r') as f:
                tcfg = json.load(f)
                if 'wallpaperPath' in tcfg and os.path.exists(os.path.expanduser(tcfg['wallpaperPath'])):
                    current_wallpaper = os.path.abspath(os.path.expanduser(tcfg['wallpaperPath']))
                if 'wallpaperFolder' in tcfg and os.path.exists(os.path.expanduser(tcfg['wallpaperFolder'])):
                    folder_path = os.path.abspath(os.path.expanduser(tcfg['wallpaperFolder']))
        except Exception:
            pass

    if not current_wallpaper and os.path.exists(config_path):
        try:
            config = configparser.ConfigParser()
            config.read(config_path)
            if 'Settings' in config:
                settings = config['Settings']
                if 'wallpaper' in settings:
                    current_wallpaper = os.path.expanduser(settings['wallpaper'])
                if 'folder' in settings and folder_path == os.path.expanduser("~/Pictures/Wallpapers"):
                    wfolder = os.path.expanduser(settings['folder'])
                    if os.path.exists(wfolder):
                        folder_path = os.path.abspath(wfolder)
        except Exception as e:
            print(f"Error reading config: {e}", file=sys.stderr)

    cache_dir = os.path.expanduser("~/.cache/tide-island/thumbnails")
    os.makedirs(cache_dir, exist_ok=True)

    wallpapers = []
    needs_generator = False

    if os.path.exists(folder_path) and os.path.isdir(folder_path):
        try:
            for file in os.listdir(folder_path):
                ext = os.path.splitext(file)[1].lower()
                if ext in ['.png', '.jpg', '.jpeg', '.webp']:
                    src_path = os.path.join(folder_path, file)
                    h = hashlib.md5(src_path.encode('utf-8')).hexdigest()
                    thumb_path = os.path.join(cache_dir, f"{h}.jpg")

                    is_valid = False
                    if os.path.exists(thumb_path):
                        try:
                            if os.path.getmtime(src_path) <= os.path.getmtime(thumb_path):
                                is_valid = True
                        except:
                            pass

                    if is_valid:
                        thumb = thumb_path
                    else:
                        thumb = src_path
                        needs_generator = True

                    wallpapers.append({
                        "name": file,
                        "path": src_path,
                        "thumb": thumb
                    })
            wallpapers.sort(key=lambda x: x["name"])
        except Exception as e:
            print(f"Error listing folder: {e}", file=sys.stderr)

    result = {
        "folder": folder_path,
        "current": current_wallpaper,
        "wallpapers": wallpapers
    }

    print(json.dumps(result))

    if needs_generator:
        import subprocess
        try:
            subprocess.Popen(
                [sys.executable, __file__, "--background-generate", folder_path, cache_dir],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True
            )
        except Exception:
            pass

if __name__ == "__main__":
    main()
