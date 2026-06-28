#!/usr/bin/env bash

for d in "$HOME/.config/zen" "$HOME/.zen" "$HOME/.var/app/app.zen_browser.zen/config/zen"; do
    if [ -d "$d" ] && [ -f "$d/profiles.ini" ]; then
        mkdir -p "$d/current-theme"
        cp "$HOME/.cache/matugen/firefox-colors.css" "$d/current-theme/colors.css"
        grep -E "^Path=" "$d/profiles.ini" | cut -d= -f2 | while read -r p; do
            mkdir -p "$d/$p/chrome"
            cp "$HOME/.cache/matugen/firefox-colors.css" "$d/$p/chrome/colors.css"
        done
    fi
done
