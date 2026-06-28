#!/usr/bin/env python3
import sys
import subprocess
import json
import os
import re
from urllib.request import pathname2url

def handle_special_workspace(workspace_name):
    if not workspace_name or not workspace_name.startswith("special"):
        return
        
    spec_name = ""
    if ":" in workspace_name:
        spec_name = workspace_name.split(":", 1)[1]
        
    # Check if already active on any monitor
    already_active = False
    try:
        res = subprocess.run(["hyprctl", "monitors", "-j"], capture_output=True, text=True)
        if res.returncode == 0:
            monitors = json.loads(res.stdout)
            for m in monitors:
                spec_ws = m.get("specialWorkspace", {})
                if spec_ws.get("name") == workspace_name:
                    already_active = True
                    break
    except Exception:
        pass
        
    if not already_active:
        # Toggle it to make it visible
        if spec_name:
            subprocess.run(["hyprctl", "dispatch", f"hl.dsp.workspace.toggle_special('{spec_name}')"])
        else:
            subprocess.run(["hyprctl", "dispatch", "hl.dsp.workspace.toggle_special()"])

def focus_by_name(app_name, summary="", body=""):
    try:
        res = subprocess.run(["hyprctl", "clients", "-j"], capture_output=True, text=True)
        if res.returncode != 0:
            return False
            
        clients = json.loads(res.stdout)
        app_lower = app_name.lower()
        
        # Find all matching clients
        matching_clients = []
        for c in clients:
            c_class = c.get("class", "").lower()
            c_initial_class = c.get("initialClass", "").lower()
            if app_lower == c_class or app_lower == c_initial_class or app_lower in c_class or app_lower in c_initial_class:
                matching_clients.append(c)
        
        # Webapp fallback: if no direct match, check if it is running inside a browser
        if not matching_clients:
            browser_classes = ["zen", "firefox", "chrome", "chromium", "brave-browser", "librewolf", "opera", "vivaldi-stable"]
            for c in clients:
                c_class = c.get("class", "").lower()
                c_initial_class = c.get("initialClass", "").lower()
                c_title = c.get("title", "").lower()
                
                # If it's a browser window and the title contains the app name (e.g. "whatsapp")
                if any(b in c_class or b in c_initial_class for b in browser_classes):
                    if app_lower in c_title or app_lower in c_class or app_lower in c_initial_class:
                        matching_clients.append(c)
        
        if not matching_clients:
            return False
            
        # Select the best matching client based on summary/body keywords
        best_client = None
        
        if len(matching_clients) == 1:
            best_client = matching_clients[0]
        else:
            best_score = -1
            summary_words = [w.lower() for w in summary.split() if len(w) > 2]
            body_words = [w.lower() for w in body.split() if len(w) > 2]
            
            for c in matching_clients:
                title = c.get("title", "").lower()
                score = 0
                
                # Check for word overlaps
                for word in summary_words:
                    if word in title:
                        score += 10
                for word in body_words:
                    if word in title:
                        score += 5
                        
                # Direct substring match
                if summary and summary.lower() in title:
                    score += 50
                if title and title in summary.lower():
                    score += 30
                    
                # Extra points if the title contains the app name (useful for webapp fallback scoring)
                if app_lower in title:
                    score += 20
                    
                if score > best_score:
                    best_score = score
                    best_client = c
            
            if not best_client or best_score <= 0:
                best_client = matching_clients[0]
                
        # Handle special workspace if needed
        ws_info = best_client.get("workspace", {})
        ws_name = ws_info.get("name", "")
        if ws_name.startswith("special"):
            handle_special_workspace(ws_name)
            
        # Focus the client window
        addr = best_client.get("address")
        subprocess.run(["hyprctl", "dispatch", f"hl.dsp.focus({{ window = 'address:{addr}' }})"])
        return True
            
    except Exception as e:
        print(f"Error focusing client: {e}", file=sys.stderr)
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
                    if app_lower in entry_name_lower:
                        if entry_name_lower == f"{app_lower}.desktop":
                            best_desktop = entry.name
                            break
                        best_desktop = entry.name
            if best_desktop and best_desktop.lower() == f"{app_lower}.desktop":
                break
                
    if best_desktop:
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

def extract_path(text):
    if not text:
        return None
    # 1. Look for quoted strings starting with / or ~/
    quoted = re.findall(r'["\'](/?(?:~?/)[^"\']+)["\']', text)
    for p in quoted:
        expanded = os.path.expanduser(p.strip())
        if os.path.exists(expanded) or os.path.exists(os.path.dirname(expanded)):
            if len(p.strip()) > 1:
                return expanded

    # 2. Look for words starting with / or ~/
    for token in text.split():
        cleaned = token.strip(".,!?;:()'\"`[]{}<>")
        if cleaned.startswith('/') or cleaned.startswith('~/'):
            expanded = os.path.expanduser(cleaned)
            if os.path.exists(expanded) or (os.path.exists(os.path.dirname(expanded)) and '/' in cleaned[1:]):
                if len(cleaned) > 2:
                    return expanded

    # 3. Regex for unquoted absolute paths or tilde-paths
    matches = re.findall(r'(~?/[a-zA-Z0-9_@:%._\+~#=/-]+)', text)
    for p in matches:
        p_clean = p.strip(".,!?;:()'\" ")
        expanded = os.path.expanduser(p_clean)
        if os.path.exists(expanded):
            return expanded

    return None

def open_directory_graphically(dir_path):
    dir_path = os.path.abspath(os.path.expanduser(dir_path))
    if not os.path.isdir(dir_path):
        return False
        
    # Try DBus org.freedesktop.FileManager1.ShowItems first (routes to default GUI fm)
    try:
        dir_uri = "file://" + pathname2url(dir_path)
        res = subprocess.run([
            "dbus-send",
            "--session",
            "--print-reply",
            "--dest=org.freedesktop.FileManager1",
            "--type=method_call",
            "/org/freedesktop/FileManager1",
            "org.freedesktop.FileManager1.ShowItems",
            f"array:string:{dir_uri}",
            "string:"
        ], capture_output=True, text=True, timeout=2)
        if res.returncode == 0:
            return True
    except Exception:
        pass
        
    # Fallback: scan for standard GUI file managers in PATH and run the first one
    gui_fms = ["dolphin", "nautilus", "nemo", "thunar", "pcmanfm", "pcmanfm-qt"]
    for fm in gui_fms:
        if subprocess.run(["which", fm], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0:
            subprocess.Popen([fm, dir_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return True
            
    # Ultimate fallback: xdg-open
    subprocess.Popen(["xdg-open", dir_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return True

def show_in_file_manager(file_path):
    file_path = os.path.abspath(os.path.expanduser(file_path))
    
    # If the path is a directory, open it directly using our graphical opener
    if os.path.isdir(file_path):
        return open_directory_graphically(file_path)
        
    # If it is a file, we want to open the parent directory and select/highlight the file
    parent_dir = os.path.dirname(file_path)
    if not os.path.exists(parent_dir):
        return False
        
    # Try using dbus method first
    try:
        file_uri = "file://" + pathname2url(file_path)
        res = subprocess.run([
            "dbus-send",
            "--session",
            "--print-reply",
            "--dest=org.freedesktop.FileManager1",
            "--type=method_call",
            "/org/freedesktop/FileManager1",
            "org.freedesktop.FileManager1.ShowItems",
            f"array:string:{file_uri}",
            "string:"
        ], capture_output=True, text=True, timeout=2)
        if res.returncode == 0:
            return True
    except Exception:
        pass
        
    # Fallback to specific file manager commands if we can detect them
    try:
        res = subprocess.run(["xdg-mime", "query", "default", "inode/directory"], capture_output=True, text=True)
        default_fm = res.stdout.strip().lower()
        if "nautilus" in default_fm:
            subprocess.Popen(["nautilus", "--select", file_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return True
        elif "dolphin" in default_fm:
            subprocess.Popen(["dolphin", "--select", file_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return True
        elif "nemo" in default_fm:
            subprocess.Popen(["nemo", "--select", file_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return True
        elif "thunar" in default_fm:
            subprocess.Popen(["thunar", "--select", file_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return True
    except Exception:
        pass
        
    # Ultimate fallback: open parent directory in default file manager
    subprocess.Popen(["xdg-open", parent_dir], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return True

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: redirect_app.py <app_name> [summary] [body]")
        sys.exit(1)
        
    app_name = sys.argv[1]
    summary = sys.argv[2] if len(sys.argv) > 2 else ""
    body = sys.argv[3] if len(sys.argv) > 3 else ""
    
    # Check for paths and file-manager redirects
    path = extract_path(summary) or extract_path(body)
    if path:
        if show_in_file_manager(path):
            print(f"Opened path in file manager: {path}")
            sys.exit(0)
            
    # Fallback based on keywords if no path is found
    lower_summary = summary.lower()
    lower_body = body.lower()
    lower_app = app_name.lower()
    
    if "screenshot" in lower_app or "screenshot" in lower_summary or "screenshot" in lower_body:
        sc_dirs = [os.path.expanduser("~/Pictures/Screenshots"), os.path.expanduser("~/Pictures")]
        for d in sc_dirs:
            if os.path.exists(d):
                if open_directory_graphically(d):
                    print(f"Opened screenshot directory: {d}")
                    sys.exit(0)
                
    if "recording" in lower_app or "recording" in lower_summary or "recording" in lower_body or "screencast" in lower_summary:
        rec_dirs = [os.path.expanduser("~/Videos/Recordings"), os.path.expanduser("~/Videos")]
        for d in rec_dirs:
            if os.path.exists(d):
                if open_directory_graphically(d):
                    print(f"Opened recording directory: {d}")
                    sys.exit(0)
                
    if "download" in lower_app or "download" in lower_summary or "download" in lower_body:
        dl_dir = os.path.expanduser("~/Downloads")
        if os.path.exists(dl_dir):
            if open_directory_graphically(dl_dir):
                print(f"Opened downloads directory: {dl_dir}")
                sys.exit(0)

    if not app_name or app_name.lower() in ("battery", "tidebatteryalert", "system"):
        print("Ignored system appName")
        sys.exit(0)
        
    if not focus_by_name(app_name, summary, body):
        print(f"App '{app_name}' not running. Launching...")
        launch_app(app_name)
