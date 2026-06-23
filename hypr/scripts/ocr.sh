#!/usr/bin/env bash

# Create a temporary file for the screenshot
TEMP_IMG=$(mktemp /tmp/ocr_XXXXXX.png)

# Clean up temporary file on exit
cleanup() {
    rm -f "$TEMP_IMG"
}
trap cleanup EXIT

# Capture selected region with grim and slurp
# slurp provides the geometry, grim saves the screenshot
if ! grim -g "$(slurp)" "$TEMP_IMG" 2>/dev/null; then
    # User cancelled selection or grim failed
    exit 0
fi

# Run OCR using ocrdesktop (using -n to hide GUI and -o to print to stdout)
# Redirect stderr to /dev/null to suppress Python warning messages from ocrdesktop
OCR_TEXT=$(ocrdesktop -f "$TEMP_IMG" -n -o 2>/dev/null)

# Check if the extracted text contains any non-whitespace characters
if [ -n "$(echo -n "$OCR_TEXT" | tr -d '[:space:]')" ]; then
    # Copy the extracted text to Wayland clipboard
    echo -n "$OCR_TEXT" | wl-copy
    
    # Notify user of success
    notify-send -t 3000 "OCR" "Text has been extracted and copied to clipboard."
else
    # Notify user of failure to find any text
    notify-send -t 3000 "OCR" "No text recognized in the selected region."
fi
