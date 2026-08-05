#!/usr/bin/env python3
import os
import sys
import json
import argparse

def main():
    parser = argparse.ArgumentParser(description="Update Tide Island userconfig.json")
    parser.add_argument("--clock-format", choices=["12", "24"], help="Clock format (12 or 24)")
    parser.add_argument("--disable-auto-expand", choices=["true", "false"], help="Disable auto expand on track change")
    parser.add_argument("--show-battery-percentage", choices=["true", "false"], help="Show/hide battery percentage text")
    parser.add_argument("--primary-action", help="Primary click action")
    parser.add_argument("--secondary-action", help="Secondary click action")
    parser.add_argument("--notepad-default-mode", choices=["edit", "preview"], help="Default notepad mode (edit or preview)")
    parser.add_argument("--notepad-auto-save", choices=["true", "false"], help="Default notepad auto-save state")

    args = parser.parse_args()
    config_path = os.path.expanduser("~/.config/tide-island/userconfig.json")

    config = {}
    if os.path.exists(config_path):
        try:
            with open(config_path, 'r') as f:
                config = json.load(f)
        except Exception as e:
            print(f"Error loading config: {e}", file=sys.stderr)

    if args.clock_format is not None:
        config['clockFormat'] = args.clock_format
    if args.disable_auto_expand is not None:
        config['disableAutoExpandOnTrackChange'] = (args.disable_auto_expand.lower() == "true")
    if args.show_battery_percentage is not None:
        config['showBatteryPercentage'] = (args.show_battery_percentage.lower() == "true")
    if args.primary_action is not None:
        config['dynamicIslandPrimaryAction'] = args.primary_action
    if args.secondary_action is not None:
        config['dynamicIslandSecondaryAction'] = args.secondary_action
    if args.notepad_default_mode is not None:
        config['notepadDefaultMode'] = args.notepad_default_mode
    if args.notepad_auto_save is not None:
        config['notepadAutoSave'] = (args.notepad_auto_save.lower() == "true")

    os.makedirs(os.path.dirname(config_path), exist_ok=True)
    with open(config_path, 'w') as f:
        json.dump(config, f, indent=4)
    print("Updated userconfig.json successfully")

if __name__ == "__main__":
    main()
