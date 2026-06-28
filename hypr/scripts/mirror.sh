#!/usr/bin/env python3
import os
import sys
import subprocess
import json
import re

def send_notification(title, message, icon="camera-photo"):
    try:
        subprocess.run(["notify-send", "-a", "Mirror", "-i", icon, title, message], check=False)
    except FileNotFoundError:
        pass

def parse_colors():
    """Parses colors.lua to extract active theme colors."""
    # Defaults matching tide-island
    colors = {
        "background": "#16130b",
        "primary": "#e2c46d",
        "surface": "#231f17",
        "on_surface": "#eae1d4",
        "outline": "#4c4639",
        "error": "#ffb4ab",
        "text_font": "Inter Display",
        "icon_font": "JetBrainsMono Nerd Font"
    }

    # Resolve active config paths
    colors_file = os.path.expanduser("~/.config/hypr/colors.lua")
    if not os.path.exists(colors_file):
        colors_file = os.path.expanduser("~/.local/src/HyprDots/hypr/colors.lua")

    if os.path.exists(colors_file):
        try:
            with open(colors_file, 'r', encoding='utf-8') as f:
                content = f.read()
                # Find assignments like key = "0xff16130b"
                matches = re.findall(r'(\w+)\s*=\s*["\']0x([0-9a-fA-F]+)["\']', content)
                for key, val in matches:
                    if len(val) == 8 and val.lower().startswith("ff"):
                        colors[key] = "#" + val[2:]
                    else:
                        colors[key] = "#" + val
        except Exception as e:
            print(f"Error parsing colors: {e}")
            
    return colors

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    qml_path = os.path.join(script_dir, "mirror.qml")
    theme_path = os.path.join(script_dir, "theme.json")
    
    if not os.path.exists(qml_path):
        print(f"Error: mirror.qml not found at {qml_path}")
        sys.exit(1)
        
    # Generate dynamic theme JSON
    theme_data = parse_colors()
    try:
        with open(theme_path, 'w', encoding='utf-8') as f:
            json.dump(theme_data, f, indent=4)
    except Exception as e:
        print(f"Failed to write theme.json: {e}")
        
    print(f"Launching Mirror QML application with active system theme...")
    send_notification("Mirror Tool", "Launching camera mirror window...")
    
    cmd = ["stdbuf", "-oL", "-eL", "qml6", qml_path]
    try:
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
        
        for line in process.stdout:
            print(line.strip())
            
            if "NOTIFICATION:" in line:
                content = line.split("NOTIFICATION:", 1)[1]
                parts = content.split("|", 1)
                if len(parts) == 2:
                    title = parts[0].strip()
                    message = parts[1].strip()
                    send_notification(title, message)
                    
        process.wait()
    except KeyboardInterrupt:
        print("\nStopping QML application...")
        if 'process' in locals():
            process.terminate()
            process.wait()
    finally:
        # Clean up theme file on exit
        if os.path.exists(theme_path):
            try:
                os.remove(theme_path)
            except OSError:
                pass

if __name__ == "__main__":
    main()
