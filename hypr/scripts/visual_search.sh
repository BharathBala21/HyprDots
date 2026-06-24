#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import sys
import subprocess
import shlex
import urllib.request
import urllib.parse
import json
import mimetypes
import uuid
import argparse
import time
from PIL import Image
import pytesseract

# Terminal formatting colors
GREEN = '\033[92m'
BLUE = '\033[94m'
YELLOW = '\033[93m'
RED = '\033[91m'
CYAN = '\033[96m'
BOLD = '\033[1m'
RESET = '\033[0m'

cache_dir = os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache")
LOG_FILE = os.path.join(cache_dir, "visual_search_lens", "visual_search.log")

BANNER = f"""
{BLUE}{BOLD}┌────────────────────────────────────────────────────────┐
│             👁️   ANTIGRAVITY VISUAL LENS   👁️             │
│        Auto-Detecting Browser & Google Lens Search     │
└────────────────────────────────────────────────────────┘{RESET}
"""

def log_debug(message):
    """Logs a debug message to a file and stdout."""
    t_str = time.strftime('%Y-%m-%d %H:%M:%S')
    log_line = f"[{t_str}] {message}"
    print(log_line)
    try:
        os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(log_line + "\n")
    except Exception as e:
        print(f"Failed to write to log file: {e}")

def send_notification(title, message, icon="preferences-desktop-keyboard-shortcuts", disable=False):
    """Sends a system-level desktop notification using notify-send."""
    if disable:
        return
    try:
        subprocess.run(["notify-send", "-i", icon, title, message], check=False)
    except FileNotFoundError:
        pass

def get_hyprland_windows():
    """Queries Hyprland for active windows/clients and parses their details."""
    try:
        out = subprocess.check_output(["hyprctl", "clients", "-j"], text=True)
        data = json.loads(out)
        windows = {}
        for client in data:
            address = client.get("address")
            title = client.get("title", "")
            workspace_id = client.get("workspace", {}).get("id")
            workspace_name = client.get("workspace", {}).get("name", "")
            window_class = client.get("class", "")
            windows[address] = {
                "title": title,
                "workspace_id": workspace_id,
                "workspace_name": workspace_name,
                "class": window_class
            }
        return windows
    except Exception as e:
        log_debug(f"Error querying Hyprland clients: {e}")
        return {}

def run_hl_dispatch(dispatcher_lua):
    """Executes a dispatcher command formatted in native Hyprland Lua syntax."""
    log_debug(f"Executing: hyprctl dispatch \"{dispatcher_lua}\"")
    r = subprocess.run(["hyprctl", "dispatch", dispatcher_lua], capture_output=True, text=True)
    log_debug(f"Dispatch status: {r.returncode}, stdout: '{r.stdout.strip()}', stderr: '{r.stderr.strip()}'")
    return r

def focus_lens_window(windows_before, browser_class):
    """
    Waits for the default browser to receive the new tab and then
    switches workspaces/focuses the correct window immediately.
    """
    log_debug(f"Starting window focus tracking. Browser class constraint: {browser_class}")
    log_debug(f"HYPRLAND_INSTANCE_SIGNATURE: {os.environ.get('HYPRLAND_INSTANCE_SIGNATURE')}")
    
    start_time = time.time()
    
    # Poll for up to 8 seconds
    while time.time() - start_time < 8.0:
        time.sleep(0.05)  # Fast polling for high responsiveness (50ms)
        windows_now = get_hyprland_windows()
        
        target_address = None
        target_workspace_name = None
        target_workspace_id = None
        match_type = ""
        
        # 1. Search for a window explicitly containing Google Lens or search title elements
        for address, win in windows_now.items():
            win_class = win["class"].lower()
            b_class = browser_class.lower()
            if b_class in win_class or win_class in b_class:
                title = win["title"].lower()
                if any(k in title for k in ["google lens", "search what you see", "lens.google"]):
                    target_address = address
                    target_workspace_name = win["workspace_name"]
                    target_workspace_id = win["workspace_id"]
                    match_type = f"Direct Title Match ('{win['title']}')"
                    break
                
        # 2. Fallback: Search for any browser window whose title changed from before (instant tab detection)
        if not target_address:
            for address, win in windows_now.items():
                win_class = win["class"].lower()
                b_class = browser_class.lower()
                if b_class in win_class or win_class in b_class:
                    if address in windows_before:
                        # Title changed
                        if win["title"] != windows_before[address]["title"]:
                            target_address = address
                            target_workspace_name = win["workspace_name"]
                            target_workspace_id = win["workspace_id"]
                            match_type = f"Instant Title Change Match ('{windows_before[address]['title']}' -> '{win['title']}')"
                            break
                    else:
                        # New window appeared
                        target_address = address
                        target_workspace_name = win["workspace_name"]
                        target_workspace_id = win["workspace_id"]
                        match_type = f"New Window Match ('{win['title']}')"
                        break
                            
        # Switch workspace and focus if found
        if target_address and target_workspace_name:
            log_debug(f"FOUND MATCH: {match_type}")
            log_debug(f"Target Address: {target_address}, Workspace Name: '{target_workspace_name}' (ID: {target_workspace_id})")
            
            # Switch to workspace using lua command
            # hl.dsp.focus({workspace = 'name'})
            run_hl_dispatch(f"hl.dsp.focus({{workspace = '{target_workspace_name}'}})")
            
            # Focus specific window address using lua command
            # hl.dsp.focus({window = 'address:0x...'})
            run_hl_dispatch(f"hl.dsp.focus({{window = 'address:{target_address}'}})")
            
            return True
            
    log_debug("TIMEOUT: Could not find or match the browser tab containing Google Lens within 8 seconds.")
    return False

def get_default_browser_cmd():
    """Auto-detects the default browser command, name, and class."""
    try:
        # Step 1: Query xdg-settings
        desktop_file = subprocess.check_output(["xdg-settings", "get", "default-web-browser"], text=True).strip()
        if not desktop_file:
            # Step 2: Fallback to mime query
            desktop_file = subprocess.check_output(["xdg-mime", "query", "default", "x-scheme-handler/http"], text=True).strip()
        
        if not desktop_file:
            return None, "System Default Opener", "xdg-open"
            
        # Step 3: Search common desktop entry paths
        paths_to_search = [
            os.path.expanduser("~/.local/share/applications"),
            "/usr/share/applications",
            "/usr/local/share/applications"
        ]
        
        filepath = None
        for p in paths_to_search:
            candidate = os.path.join(p, desktop_file)
            if os.path.exists(candidate):
                filepath = candidate
                break
                
        if not filepath:
            return None, f"Desktop file '{desktop_file}' not found", desktop_file.replace(".desktop", "")
            
        # Step 4: Parse file
        exec_cmd = None
        name = None
        in_desktop_entry = False
        with open(filepath, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line == "[Desktop Entry]":
                    in_desktop_entry = True
                elif line.startswith("[") and line.endswith("]"):
                    in_desktop_entry = False
                
                if in_desktop_entry:
                    if line.startswith("Exec="):
                        exec_cmd = line.split("=", 1)[1].strip()
                    elif line.startswith("Name="):
                        name = line.split("=", 1)[1].strip()
                        
        if not exec_cmd:
            return None, f"No Exec command in {desktop_file}", desktop_file.replace(".desktop", "")
            
        name = name or desktop_file.replace(".desktop", "").capitalize()
        browser_class = desktop_file.replace(".desktop", "")
            
        # Step 5: Clean parameters
        tokens = shlex.split(exec_cmd)
        clean_tokens = []
        for t in tokens:
            if t in ("%u", "%U", "%f", "%F"):
                continue
            clean_tokens.append(t)
            
        return clean_tokens, name, browser_class
    except Exception as e:
        return None, f"Error auto-detecting: {str(e)}", "xdg-open"

def open_in_default_browser(url):
    """Launches the URL in the default browser."""
    cmd, name, browser_class = get_default_browser_cmd()
    if cmd:
        log_debug(f"Opening browser command: {cmd} with URL: {url}")
        subprocess.Popen(cmd + [url], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return name, browser_class
    else:
        import webbrowser
        log_debug(f"Fallback to webbrowser module to open: {url}")
        webbrowser.open(url)
        return "System Default Opener", browser_class

def copy_to_clipboard(text):
    """Copies text to clipboard using wl-copy (Wayland) or xclip/xsel (X11)."""
    try:
        process = subprocess.Popen(['wl-copy'], stdin=subprocess.PIPE, text=True)
        process.communicate(input=text)
        return True, "wl-copy"
    except FileNotFoundError:
        pass
        
    try:
        process = subprocess.Popen(['xclip', '-selection', 'clipboard'], stdin=subprocess.PIPE, text=True)
        process.communicate(input=text)
        return True, "xclip"
    except FileNotFoundError:
        pass
        
    try:
        process = subprocess.Popen(['xsel', '--clipboard', '--input'], stdin=subprocess.PIPE, text=True)
        process.communicate(input=text)
        return True, "xsel"
    except FileNotFoundError:
        pass
        
    return False, "None"

def upload_image(file_path):
    """Uploads the local image anonymously to tmpfiles.org and returns a direct image link."""
    boundary = uuid.uuid4().hex
    filename = os.path.basename(file_path)
    mime_type, _ = mimetypes.guess_type(file_path)
    if not mime_type:
        mime_type = 'image/png'
        
    with open(file_path, 'rb') as f:
        file_data = f.read()
        
    body = (
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="file"; filename="{filename}"\r\n'
        f"Content-Type: {mime_type}\r\n\r\n"
    ).encode('utf-8') + file_data + f"\r\n--{boundary}--\r\n".encode('utf-8')
    
    headers = {
        'Content-Type': f'multipart/form-data; boundary={boundary}',
        'Content-Length': str(len(body)),
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
    }
    
    req = urllib.request.Request("https://tmpfiles.org/api/v1/upload", data=body, headers=headers)
    
    with urllib.request.urlopen(req) as response:
        res_data = response.read().decode('utf-8')
        res_json = json.loads(res_data)
        if res_json.get("status") == "success":
            url = res_json["data"]["url"]
            direct_url = url.replace("https://tmpfiles.org/", "https://tmpfiles.org/dl/")
            return direct_url
        else:
            raise Exception(f"Upload failed: {res_json}")

def main():
    parser = argparse.ArgumentParser(description="Antigravity Visual Lens - Google Lens visual search and OCR.")
    parser.add_argument("-f", "--file", help="Path to an existing image file (skip screen cropping).")
    parser.add_argument("-o", "--ocr-only", action="store_true", help="Perform offline OCR only; do not upload to Google Lens.")
    parser.add_argument("-l", "--lens-only", action="store_true", help="Perform Google Lens visual search only; skip offline OCR.")
    parser.add_argument("-n", "--no-notify", action="store_true", help="Disable desktop system notifications.")
    
    args = parser.parse_args()
    
    log_debug("--- Starting Antigravity Visual Search ---")
    
    # 1. Acquire Image
    image_path = None
    if args.file:
        if not os.path.exists(args.file):
            log_debug(f"Error: File not found: {args.file}")
            sys.exit(1)
        image_path = os.path.abspath(args.file)
        log_debug(f"Using input file: {image_path}")
    else:
        # Screen capture mode using Wayland native grim + slurp
        log_debug("Triggering screen crop (slurp + grim)")
        send_notification("Visual Lens", "Click and drag to select screen area...", disable=args.no_notify)
        
        try:
            subprocess.run(["which", "slurp"], stdout=subprocess.DEVNULL, check=True)
            subprocess.run(["which", "grim"], stdout=subprocess.DEVNULL, check=True)
        except subprocess.CalledProcessError:
            log_debug("Error: 'slurp' and 'grim' are not installed.")
            send_notification("Visual Lens Error", "grim or slurp not found. Install them to crop screen.", disable=args.no_notify)
            sys.exit(1)
            
        try:
            geom = subprocess.check_output(["slurp"], text=True).strip()
        except subprocess.CalledProcessError:
            log_debug("User cancelled screenshot region selection.")
            send_notification("Visual Lens", "Screen capture cancelled.", disable=args.no_notify)
            sys.exit(0)
            
        # Define output crop path in scripts directory
        script_dir = os.path.dirname(os.path.abspath(__file__))
        image_path = os.path.join(script_dir, "lens_crop.png")
        
        try:
            subprocess.run(["grim", "-g", geom, image_path], check=True)
            log_debug(f"Crop captured and saved to: {image_path}")
        except subprocess.CalledProcessError as e:
            log_debug(f"Error: Grim failed to capture screen: {e}")
            sys.exit(1)
            
    # 2. Local OCR
    ocr_text = ""
    if not args.lens_only:
        log_debug("Extracting text via local OCR...")
        send_notification("Visual Lens", "Performing local text extraction...", disable=args.no_notify)
        try:
            img = Image.open(image_path)
            ocr_text = pytesseract.image_to_string(img).strip()
            
            if ocr_text:
                log_debug(f"OCR extracted text length: {len(ocr_text)} characters")
                copied, clipboard_util = copy_to_clipboard(ocr_text)
                if copied:
                    log_debug(f"Copied text to clipboard using {clipboard_util}")
                    send_notification("Visual Lens OCR", f"Extracted text copied to clipboard!", disable=args.no_notify)
                else:
                    log_debug("Could not copy to clipboard (no tool found)")
            else:
                log_debug("No text detected in crop.")
                send_notification("Visual Lens OCR", "No text detected in selected region.", disable=args.no_notify)
        except Exception as e:
            log_debug(f"Local OCR Failed: {e}")
            send_notification("Visual Lens Error", f"OCR process failed: {e}", disable=args.no_notify)
            
    # 3. Google Lens Visual Search
    if not args.ocr_only:
        log_debug("Preparing Google Lens upload...")
        send_notification("Visual Lens", "Uploading to Google Lens...", disable=args.no_notify)
        try:
            # Upload to temp host
            direct_image_url = upload_image(image_path)
            log_debug(f"Image uploaded. URL: {direct_image_url}")
            
            # Construct Google Lens URL
            encoded_url = urllib.parse.quote_plus(direct_image_url)
            lens_url = f"https://lens.google.com/uploadbyurl?url={encoded_url}"
            
            # Query window states BEFORE launch
            windows_before = get_hyprland_windows()
            
            # Launch in default browser
            browser_name, browser_class = open_in_default_browser(lens_url)
            
            # Redirect user focus to the correct workspace and browser window
            log_debug("Initiating focus tracking...")
            focused = focus_lens_window(windows_before, browser_class)
            if focused:
                log_debug("Redirection complete.")
                send_notification("Visual Lens Search", f"Focused results in {browser_name}.", disable=args.no_notify)
            else:
                log_debug("Redirection failed or timed out.")
                send_notification("Visual Lens Search", "Opening search results.", disable=args.no_notify)
            
        except Exception as e:
            log_debug(f"Google Lens upload failed: {e}")
            send_notification("Visual Lens Error", "Google Lens upload failed.", disable=args.no_notify)
            
    # Cleanup crop file
    if not args.file and os.path.exists(image_path):
        try:
            os.remove(image_path)
            log_debug("Temporary crop image cleaned up.")
        except OSError as e:
            log_debug(f"Failed to remove temp crop: {e}")

if __name__ == "__main__":
    main()
