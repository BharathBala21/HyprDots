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

def sync_vscode_themes_manually():
    roots = ["~/.vscode/extensions", "~/.vscode-oss/extensions"]
    ext_paths = []
    for r in roots:
        full_root = os.path.expanduser(r)
        if os.path.exists(full_root):
            for item in os.listdir(full_root):
                if item.startswith("haikalllp.matugen-theme"):
                    ext_paths.append(os.path.join(full_root, item))

    if not ext_paths:
        print("No VS Code Matugen extension folders found to sync themes directly.")
        return

    if not shutil.which("node"):
        print("Node.js not installed, cannot sync VS Code themes directly.")
        return

    for path in ext_paths:
        print(f"Syncing VS Code theme files for: {path}")
        js_code = f"""
const fs = require('fs');
const path = require('path');
const os = require('os');
const crypto = require('crypto');

const extDir = '{path}';
const Color = require(path.join(extDir, 'node_modules', 'color'));
const template = require(path.join(extDir, 'out', 'template.js')).default;

const colorsPath = path.join(os.homedir(), '.cache', 'matugen', 'vscode-colors');
const colorsJsonPath = path.join(os.homedir(), '.cache', 'matugen', 'vscode-colors.json');

if (!fs.existsSync(colorsPath)) {{
    console.error('vscode-colors file not found');
    process.exit(1);
}}

const colorsData = fs.readFileSync(colorsPath, 'utf-8');
const colorStrings = colorsData.trim().split(/\\s+/).filter(s => s.length > 0);
const colors = colorStrings.slice(0, 16).map(c => Color(c));

if (fs.existsSync(colorsJsonPath)) {{
    try {{
        const jsonData = fs.readFileSync(colorsJsonPath, 'utf-8');
        const parsed = JSON.parse(jsonData);
        if (parsed?.special?.background) colors[0] = Color(parsed.special.background);
        if (parsed?.special?.foreground) colors[7] = Color(parsed.special.foreground);
    }} catch (e) {{
        console.warn('Could not parse colors.json', e);
    }}
}}

const themesDir = path.join(extDir, 'themes');
if (!fs.existsSync(themesDir)) {{
    fs.mkdirSync(themesDir, {{ recursive: true }});
}}

fs.writeFileSync(path.join(themesDir, 'matugen.json'), JSON.stringify(template(colors, false), null, 4));
fs.writeFileSync(path.join(themesDir, 'matugen-bordered.json'), JSON.stringify(template(colors, true), null, 4));

const combined = colorsData + (fs.existsSync(colorsJsonPath) ? fs.readFileSync(colorsJsonPath, 'utf-8') : '');
const colorsHash = crypto.createHash('md5').update(combined).digest('hex');
const cacheStatePath = path.join(themesDir, '.matugen-theme-cache.json');
const state = {{
    colorsHash: colorsHash,
    lastUpdated: Date.now(),
    version: '1.0.0'
}};
fs.writeFileSync(cacheStatePath, JSON.stringify(state, null, 2), 'utf-8');

console.log('Successfully regenerated theme files and cache state.');
"""
        try:
            subprocess.run(["node", "-e", js_code], check=True)
        except Exception as e:
            print(f"Error executing Node.js theme sync for {path}: {e}", file=sys.stderr)

def install_spicetify():
    spicetify_bin = os.path.expanduser("~/.spicetify/spicetify")
    if not os.path.exists(spicetify_bin):
        print("Spicetify not found. Installing Spicetify via official installer script...")
        try:
            subprocess.run("curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh", shell=True, check=True)
            spicetify_dir = os.path.expanduser("~/.spicetify")
            if spicetify_dir not in os.environ.get("PATH", ""):
                os.environ["PATH"] = spicetify_dir + os.path.pathsep + os.environ.get("PATH", "")
        except Exception as e:
            print(f"Failed to install Spicetify: {e}", file=sys.stderr)
            return False
    else:
        print("Spicetify is already installed.")

    if os.path.exists(spicetify_bin):
        spicetify_cmd = spicetify_bin
    else:
        spicetify_cmd = shutil.which("spicetify") or "spicetify"

    print("Configuring Spicetify current_theme=Sleek and color_scheme=matugen...")
    try:
        subprocess.run([spicetify_cmd, "config", "current_theme", "Sleek"], check=True)
        subprocess.run([spicetify_cmd, "config", "color_scheme", "matugen"], check=True)
        print("Running spicetify backup apply...")
        subprocess.run([spicetify_cmd, "backup", "apply"], check=True)
        print("Spicetify configured and applied successfully!")
        return True
    except subprocess.CalledProcessError as e:
        print(f"Backup apply failed (Spotify might already be patched). Trying 'spicetify apply'...", file=sys.stderr)
        try:
            subprocess.run([spicetify_cmd, "apply"], check=True)
            print("Spicetify applied successfully!")
            return True
        except Exception as e2:
            print(f"Failed to apply Spicetify: {e2}", file=sys.stderr)
            return False
    except Exception as e:
        print(f"Error configuring Spicetify: {e}", file=sys.stderr)
        return False

def apply_spicetify():
    spicetify_bin = os.path.expanduser("~/.spicetify/spicetify")
    spicetify_cmd = spicetify_bin if os.path.exists(spicetify_bin) else (shutil.which("spicetify") or "spicetify")
    print("Running spicetify apply...")
    try:
        subprocess.run([spicetify_cmd, "apply"], check=True)
        print("Spicetify applied successfully!")
        return True
    except Exception as e:
        print(f"Failed to apply Spicetify: {e}", file=sys.stderr)
        return False

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

    # Spicetify arguments
    parser.add_argument("--install-spicetify", action="store_true", help="Install and configure Spicetify with matugen scheme")
    parser.add_argument("--apply-spicetify", action="store_true", help="Apply spicetify custom theme colors")

    args = parser.parse_args()

    # Handle VS Code settings/install actions first
    if args.install_vscode_extension:
        install_vscode_extension()
    if args.set_vscode_theme is not None or args.set_vscode_autoupdate is not None:
        update_vscode_settings(theme_name=args.set_vscode_theme, auto_update=args.set_vscode_autoupdate)

    # Handle Spicetify actions
    if args.install_spicetify:
        install_spicetify()
    if args.apply_spicetify:
        apply_spicetify()

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
            # Sync VS Code themes manually right after matugen is run to ensure consistency
            sync_vscode_themes_manually()
        except subprocess.CalledProcessError as e:
            print(f"Error running matugen: {e}", file=sys.stderr)

    # Sync VS Code themes manually if VS Code theme settings were updated directly
    if args.install_vscode_extension or args.set_vscode_theme is not None or args.set_vscode_autoupdate is not None:
        sync_vscode_themes_manually()

if __name__ == "__main__":
    main()
