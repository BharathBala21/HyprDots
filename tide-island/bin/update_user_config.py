#!/usr/bin/env python3
import sys
import os
import json
import subprocess

def main():
    import argparse
    parser = argparse.ArgumentParser(description="Update user config and apply matugen")
    parser.add_argument("--mode", help="Matugen theme mode (light/dark)")
    parser.add_argument("--type", help="Matugen theme type")
    parser.add_argument("--contrast", type=float, help="Matugen contrast (-1.0 to 1.0)")
    parser.add_argument("--prefer", help="Matugen color preference")
    parser.add_argument("--source-color-index", type=int, help="Matugen source color index (0-4)")
    parser.add_argument("--wallpaper", help="Set new wallpaper path and apply matugen")
    parser.add_argument("--apply-only", action="store_true", help="Just apply matugen with current config settings")

    args = parser.parse_args()

    config_path = os.path.expanduser("~/.config/tide-island/userconfig.json")
    config = {}
    if os.path.exists(config_path):
        try:
            with open(config_path, 'r') as f:
                config = json.load(f)
        except Exception as e:
            print(f"Error reading config: {e}", file=sys.stderr)

    changed = False

    if args.mode is not None:
        config['matugenMode'] = args.mode
        changed = True
    if args.type is not None:
        config['matugenType'] = args.type
        changed = True
    if args.contrast is not None:
        config['matugenContrast'] = args.contrast
        changed = True
    if args.prefer is not None:
        config['matugenPrefer'] = args.prefer
        changed = True
    if args.source_color_index is not None:
        config['matugenSourceColorIndex'] = args.source_color_index
        changed = True
    if args.wallpaper is not None:
        config['wallpaperPath'] = args.wallpaper
        changed = True

    if changed:
        try:
            with open(config_path, 'w') as f:
                json.dump(config, f, indent=4)
        except Exception as e:
            print(f"Error writing config: {e}", file=sys.stderr)

    # Now apply matugen if needed
    if changed or args.apply_only or args.wallpaper is not None:
        wallpaper_path = config.get('wallpaperPath')
        if not wallpaper_path:
            print("No wallpaper path found in config, cannot apply matugen", file=sys.stderr)
            return

        # Build matugen command
        cmd = ["matugen", "image", "-v"]
        
        mode = config.get('matugenMode', 'dark')
        cmd.extend(["-m", mode])

        theme_type = config.get('matugenType', 'scheme-tonal-spot')
        cmd.extend(["-t", theme_type])

        contrast = config.get('matugenContrast', 0.0)
        cmd.extend(["--contrast", str(contrast)])

        prefer = config.get('matugenPrefer')
        if prefer and prefer != "default":
            cmd.extend(["--prefer", prefer])

        color_index = config.get('matugenSourceColorIndex', 0)
        cmd.extend(["--source-color-index", str(color_index)])

        cmd.append(wallpaper_path)

        print(f"Running matugen command: {' '.join(cmd)}")
        try:
            subprocess.run(cmd, check=True)
        except subprocess.CalledProcessError as e:
            print(f"Error running matugen: {e}", file=sys.stderr)

if __name__ == "__main__":
    main()
