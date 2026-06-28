#!/usr/bin/env bash

# Source folder for custom zen modifications in dotfiles
src_chrome="$HOME/.config/matugen/zen-chrome"

for d in "$HOME/.config/zen" "$HOME/.zen" "$HOME/.var/app/app.zen_browser.zen/config/zen"; do
    if [ -d "$d" ] && [ -f "$d/profiles.ini" ]; then
        mkdir -p "$d/current-theme"
        cp "$HOME/.cache/matugen/firefox-colors.css" "$d/current-theme/colors.css"
        grep -E "^Path=" "$d/profiles.ini" | cut -d= -f2 | while read -r p; do
            profile_dir="$d/$p"
            if [ -d "$profile_dir" ]; then
                # Ensure the chrome and chrome/websites directories exist
                mkdir -p "$profile_dir/chrome/websites"
                
                # Copy matugen generated colors
                cp "$HOME/.cache/matugen/firefox-colors.css" "$profile_dir/chrome/colors.css"
                
                # Copy website CSS customizations if they exist in templates
                if [ -d "$src_chrome" ]; then
                    cp -f "$src_chrome/userContent.css" "$profile_dir/chrome/userContent.css" 2>/dev/null
                    cp -rf "$src_chrome/websites/"* "$profile_dir/chrome/websites/" 2>/dev/null
                fi
                
                # Automatically enable custom stylesheets support in prefs.js if it exists
                if [ -f "$profile_dir/prefs.js" ]; then
                    if ! grep -q "toolkit.legacyUserProfileCustomizations.stylesheets" "$profile_dir/prefs.js"; then
                        echo 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' >> "$profile_dir/prefs.js"
                    fi
                fi
            fi
        done
    fi
done
