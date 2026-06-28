#!/usr/bin/env python3
import sys
import os
import json
import subprocess
import shutil

def update_vscode_settings(theme_name=None, auto_update=None):
    paths = [
        "~/.config/Code/User/settings.json",
        "~/.config/VSCodium/User/settings.json",
        "~/.config/Code - Insiders/User/settings.json"
    ]
    for p in paths:
        full_path = os.path.expanduser(p)
        # Check if parent dir exists
        parent_dir = os.path.dirname(full_path)
        if os.path.exists(parent_dir):
            if not os.path.exists(full_path):
                try:
                    with open(full_path, 'w') as f:
                        f.write("{}")
                except Exception as e:
                    print(f"Error creating {full_path}: {e}", file=sys.stderr)
                    continue

            try:
                with open(full_path, 'r') as f:
                    content = f.read().strip()
                    if content == "":
                        data = {}
                    else:
                        data = json.loads(content)
            except Exception as e:
                print(f"Error reading {full_path}: {e}", file=sys.stderr)
                continue

            changed = False
            if theme_name is not None:
                data["workbench.colorTheme"] = theme_name
                changed = True
            if auto_update is not None:
                # Convert string "true"/"false" to boolean
                val = auto_update.lower() == "true" if isinstance(auto_update, str) else bool(auto_update)
                data["matugenTheme.autoUpdate"] = val
                changed = True

            if changed:
                try:
                    with open(full_path, 'w') as f:
                        json.dump(data, f, indent=4)
                    print(f"Updated VS Code theme configuration in {full_path}")
                except Exception as e:
                    print(f"Error writing to {full_path}: {e}", file=sys.stderr)

def install_vscode_extension():
    binaries = ["code", "codium", "code-insiders"]
    installed_any = False
    for b in binaries:
        if shutil.which(b):
            print(f"Installing extension for {b}...")
            try:
                # Run with --force to update/reinstall if needed
                subprocess.run([b, "--install-extension", "haikalllp.matugen-theme", "--force"], check=True)
                installed_any = True
            except Exception as e:
                print(f"Failed to install extension for {b}: {e}", file=sys.stderr)
    return installed_any

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

    # VS Code arguments
    parser.add_argument("--install-vscode-extension", action="store_true", help="Install Matugen extension for VS Code/Codium")
    parser.add_argument("--set-vscode-theme", help="Set VS Code workbench color theme")
    parser.add_argument("--set-vscode-autoupdate", choices=["true", "false"], help="Set VS Code extension autoUpdate value")

    args = parser.parse_args()

    # Handle VS Code settings/install actions first
    if args.install_vscode_extension:
        install_vscode_extension()
    if args.set_vscode_theme is not None or args.set_vscode_autoupdate is not None:
        update_vscode_settings(theme_name=args.set_vscode_theme, auto_update=args.set_vscode_autoupdate)

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
    if (changed or args.apply_only or args.wallpaper is not None) and not (args.install_vscode_extension or args.set_vscode_theme or args.set_vscode_autoupdate):
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
