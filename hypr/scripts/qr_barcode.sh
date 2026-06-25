#!/usr/bin/env python3
import os
import sys
import subprocess
import argparse
from PIL import Image

# Terminal colors
GREEN = '\033[92m'
BLUE = '\033[94m'
YELLOW = '\033[93m'
RED = '\033[91m'
CYAN = '\033[96m'
BOLD = '\033[1m'
RESET = '\033[0m'

BANNER = f"""
{BLUE}{BOLD}┌────────────────────────────────────────────────────────┐
│             📷   ANTIGRAVITY QR/BARCODE SCANNER   📷        │
│          Extracts & Scans QR/Barcodes to Clipboard     │
└────────────────────────────────────────────────────────┘{RESET}
"""

def send_notification(title, message, icon="scanner", disable=False):
    """Sends a system desktop notification using notify-send."""
    if disable:
        return
    try:
        subprocess.run(["notify-send", "-i", icon, title, message], check=False)
    except FileNotFoundError:
        pass

def copy_to_clipboard(text):
    """Copies text to clipboard using wl-copy, xclip, or xsel."""
    for tool, args in [('wl-copy', []), ('xclip', ['-selection', 'clipboard']), ('xsel', ['--clipboard', '--input'])]:
        try:
            process = subprocess.Popen([tool] + args, stdin=subprocess.PIPE, text=True)
            process.communicate(input=text)
            return True, tool
        except FileNotFoundError:
            continue
    return False, None

def scan_image(image_path):
    """Scans an image for QR or Barcodes using zbarimg or pyzbar."""
    # Method 1: Try zbarimg CLI (extremely reliable and standard)
    try:
        # Running: zbarimg --raw -q <image_path>
        result = subprocess.run(['zbarimg', '--raw', '-q', image_path], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if result.returncode == 0 and result.stdout:
            return result.stdout.strip(), "zbarimg"
    except FileNotFoundError:
        pass

    # Method 2: Try pyzbar python module if available
    try:
        from pyzbar.pyzbar import decode
        img = Image.open(image_path)
        decoded = decode(img)
        if decoded:
            # Combine multiple decoded contents if present, but usually just one
            results = [obj.data.decode('utf-8') for obj in decoded if obj.data]
            if results:
                return "\n".join(results), "pyzbar"
    except ImportError:
        pass

    return None, None

def check_dependencies():
    """Checks if we have the necessary CLI scanner tool or python package."""
    # Check if zbarimg is available
    zbarimg_installed = subprocess.run(["which", "zbarimg"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0
    if zbarimg_installed:
        return True, None
    
    # Check if pyzbar is available
    try:
        import pyzbar
        return True, None
    except ImportError:
        pass
        
    return False, "Missing dependency: 'zbar' package is required. Install it using:\n  sudo pacman -S zbar (Arch)\n  sudo apt install zbar-tools (Ubuntu/Debian)"

def main():
    parser = argparse.ArgumentParser(description="Antigravity QR/Barcode Scanner - Scan QR/Barcodes from screen region or file.")
    parser.add_argument("-f", "--file", help="Path to an existing image file (skip screen cropping).")
    parser.add_argument("-n", "--no-notify", action="store_true", help="Disable desktop system notifications.")
    
    args = parser.parse_args()
    
    print(BANNER)
    
    # Check dependencies first
    has_dep, error_msg = check_dependencies()
    if not has_dep:
        print(f"{RED}❌ {error_msg}{RESET}")
        send_notification("Dependency Error", "Please install 'zbar' package to use the QR/barcode scanner.", icon="dialog-error", disable=args.no_notify)
        sys.exit(1)

    # 1. Acquire Image
    image_path = None
    is_temp = False
    
    if args.file:
        if not os.path.exists(args.file):
            print(f"{RED}❌ Error: File not found: {args.file}{RESET}")
            sys.exit(1)
        image_path = os.path.abspath(args.file)
        print(f"{CYAN}📁 Using image file: {BOLD}{image_path}{RESET}")
    else:
        # Screen capture mode using grim + slurp
        print(f"{CYAN}🖥️  Select a screen region containing QR/Barcode to capture (Click & drag)...{RESET}")
        send_notification("QR/Barcode Scanner", "Click and drag to select screen area...", icon="camera-photo", disable=args.no_notify)
        
        try:
            subprocess.run(["which", "slurp"], stdout=subprocess.DEVNULL, check=True)
            subprocess.run(["which", "grim"], stdout=subprocess.DEVNULL, check=True)
        except subprocess.CalledProcessError:
            print(f"{RED}❌ Error: 'slurp' and 'grim' are required for screen selection on Wayland but are not installed.{RESET}")
            send_notification("Scanner Error", "grim or slurp not found. Install them to crop screen.", icon="dialog-error", disable=args.no_notify)
            sys.exit(1)
            
        try:
            geom = subprocess.check_output(["slurp"], text=True).strip()
        except subprocess.CalledProcessError:
            print(f"{YELLOW}⚠️ Screen capture cancelled by user.{RESET}")
            send_notification("QR/Barcode Scanner", "Screen capture cancelled.", icon="dialog-warning", disable=args.no_notify)
            sys.exit(0)
            
        # Define path for temporary output crop in the same directory as the script
        script_dir = os.path.dirname(os.path.abspath(__file__))
        image_path = os.path.join(script_dir, "qr_crop.png")
        is_temp = True
        
        try:
            subprocess.run(["grim", "-g", geom, image_path], check=True)
            print(f"{GREEN}📸 Crop saved to: {BOLD}{image_path}{RESET}")
        except subprocess.CalledProcessError as e:
            print(f"{RED}❌ Error: Grim failed to capture screen region: {e}{RESET}")
            send_notification("Scanner Error", "Failed to capture selected region.", icon="dialog-error", disable=args.no_notify)
            sys.exit(1)

    # 2. Scan QR/Barcode
    print(f"{CYAN}🔍 Scanning image for QR/Barcodes...{RESET}")
    send_notification("QR/Barcode Scanner", "Scanning image for QR/Barcodes...", icon="scanner", disable=args.no_notify)
    
    decoded_text, scanner_util = scan_image(image_path)
    
    # Clean up temp image immediately
    if is_temp and os.path.exists(image_path):
        try:
            os.remove(image_path)
        except OSError:
            pass

    if decoded_text:
        print(f"{GREEN}✨ Scan Results Found ({scanner_util}):{RESET}")
        print(f"{BLUE}┌──────────────────────────────────────────────┐{RESET}")
        for line in decoded_text.splitlines():
            print(f"{BLUE}│{RESET} {line}")
        print(f"{BLUE}└──────────────────────────────────────────────┘{RESET}")
        
        # Copy to Clipboard
        copied, clipboard_util = copy_to_clipboard(decoded_text)
        if copied:
            print(f"{GREEN}📋 Copied scanned content to clipboard using {BOLD}{clipboard_util}{RESET}!")
            # Truncate content in notification if it's very long
            display_text = decoded_text if len(decoded_text) <= 50 else decoded_text[:47] + "..."
            send_notification("Scan Successful", f"Copied to clipboard:\n{display_text}", icon="edit-paste", disable=args.no_notify)
        else:
            print(f"{YELLOW}⚠️ Could not copy to clipboard. Clipboard utility not found.{RESET}")
            send_notification("Scan Successful", "QR/Barcode scanned successfully, but clipboard copy failed.", icon="dialog-warning", disable=args.no_notify)
    else:
        print(f"{RED}❌ No QR code or barcode detected.{RESET}")
        send_notification("Scan Failed", "No QR code or barcode detected in selected region.", icon="dialog-error", disable=args.no_notify)

if __name__ == "__main__":
    main()
