#!/usr/bin/env python3
import sys
import subprocess
import json
import os

def focus_by_name(app_name):
    # 1. Get hyprland clients
    try:
        res = subprocess.run(["hyprctl", "clients", "-j"], capture_output=True, text=True)
        if res.returncode == 0:
            clients = json.loads(res.stdout)
            app_lower = app_name.lower()
            
            # First try exact/close match on class
            for c in clients:
                c_class = c.get("class", "").lower()
                c_initial_class = c.get("initialClass", "").lower()
                if app_lower == c_class or app_lower == c_initial_class:
                    addr = c.get("address")
                    subprocess.run(["hyprctl", "dispatch", f"hl.dsp.focus({{ window = 'address:{addr}' }})"])
                    return True
            
            # Second try substring match on class/title
            for c in clients:
                c_class = c.get("class", "").lower()
                c_initial_class = c.get("initialClass", "").lower()
                c_title = c.get("title", "").lower()
                if app_lower in c_class or app_lower in c_initial_class or app_lower in c_title:
                    addr = c.get("address")
                    subprocess.run(["hyprctl", "dispatch", f"hl.dsp.focus({{ window = 'address:{addr}' }})"])
                    return True
    except Exception as e:
        print(f"Error checking hyprctl clients: {e}", file=sys.stderr)
    return False

def launch_app(app_name):
    app_lower = app_name.lower()
    
    # 1. Try to find a matching desktop file
    desktop_dirs = [
        os.path.expanduser("~/.local/share/applications"),
        "/usr/share/applications"
    ]
    
    best_desktop = None
    for d in desktop_dirs:
        if os.path.exists(d):
            # Scan files
            for entry in os.scandir(d):
                if entry.name.endswith(".desktop"):
                    entry_name_lower = entry.name.lower()
                    # Check if the app name is in the desktop filename (e.g. org.mozilla.firefox.desktop or firefox.desktop)
                    if app_lower in entry_name_lower:
                        # Prioritize exact/close matches
                        if entry_name_lower == f"{app_lower}.desktop":
                            best_desktop = entry.name
                            break
                        best_desktop = entry.name
            if best_desktop and best_desktop.lower() == f"{app_lower}.desktop":
                break
                
    if best_desktop:
        # Try gtk-launch
        try:
            subprocess.Popen(["gtk-launch", best_desktop], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            print(f"Launched via gtk-launch: {best_desktop}")
            return
        except Exception:
            pass
            
    # 2. Fallback to just running the app name as a command
    try:
        subprocess.Popen([app_lower], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        print(f"Launched command directly: {app_lower}")
    except Exception as e:
        print(f"Failed to launch command: {e}", file=sys.stderr)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: redirect_app.py <app_name>")
        sys.exit(1)
        
    app_name = sys.argv[1]
    if not app_name or app_name.lower() in ("battery", "tidebatteryalert", "system"):
        print("Ignored system appName")
        sys.exit(0)
        
    if not focus_by_name(app_name):
        print(f"App '{app_name}' not running. Launching...")
        launch_app(app_name)
