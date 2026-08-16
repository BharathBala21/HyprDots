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
    parser.add_argument("--island-style", choices=["pill", "notch", "custom"], help="Island visual style (pill, notch, or custom)")
    parser.add_argument("--center-pill-style", choices=["pill", "notch"], help="Center island pill style")
    parser.add_argument("--top-left-pill-style", choices=["pill", "notch"], help="Top-left status/lyrics pill style")
    parser.add_argument("--top-right-pill-style", choices=["pill", "notch"], help="Top-right status pill style")
    parser.add_argument("--top-right-tray-style", choices=["pill", "notch"], help="Top-right tray pill style")
    parser.add_argument("--island-compact-width", type=int, help="Compact island width in px")
    parser.add_argument("--island-compact-height", type=int, help="Compact island height in px")
    parser.add_argument("--island-corner-radius", type=int, help="Island corner radius in px")
    parser.add_argument("--island-top-offset", type=int, help="Island top offset from screen edge in px")
    parser.add_argument("--island-inner-padding", type=int, help="Inner content padding in px")
    parser.add_argument("--reserved-top-space", type=int, help="Reserved top exclusive space for quickshell in px")
    parser.add_argument("--show-top-left-pill", choices=["true", "false"], help="Show/hide top-left status/lyrics pill")
    parser.add_argument("--show-top-right-cava", choices=["true", "false"], help="Show/hide top-right cava visualizer pill")
    parser.add_argument("--show-top-right-battery", choices=["true", "false"], help="Show/hide top-right battery status pill")
    parser.add_argument("--show-top-right-pill", choices=["true", "false"], help="Show/hide top-right status pill")
    parser.add_argument("--show-top-right-tray", choices=["true", "false"], help="Show/hide top-right tray pill")
    parser.add_argument("--island-auto-hide", choices=["true", "false"], help="Auto-hide idle center island")
    parser.add_argument("--notepad-default-mode", choices=["edit", "preview"], help="Default notepad mode (edit or preview)")
    parser.add_argument("--notepad-auto-save", choices=["true", "false"], help="Default notepad auto-save state")
    parser.add_argument("--tlp-permission-mode", choices=["password", "polkit", "sudoers", "skip"], help="Power mode permission mode")
    parser.add_argument("--auto-wallpaper-enabled", choices=["true", "false"], help="Enable/disable automatic wallpaper rotation")
    parser.add_argument("--auto-wallpaper-interval", type=int, help="Auto wallpaper rotation timer interval in minutes")
    parser.add_argument("--auto-wallpaper-notification", choices=["true", "false"], help="Show notification when wallpaper changes")
    parser.add_argument("--random-wallpaper-on-startup", choices=["true", "false"], help="Set random wallpaper on startup")
    parser.add_argument("--wallpaper-folder", help="Directory path to load wallpapers from")

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
    if args.island_style is not None:
        config['islandStyle'] = args.island_style
    if args.center_pill_style is not None:
        config['centerPillStyle'] = args.center_pill_style
    if args.top_left_pill_style is not None:
        config['topLeftPillStyle'] = args.top_left_pill_style
    if args.top_right_pill_style is not None:
        config['topRightPillStyle'] = args.top_right_pill_style
    if args.top_right_tray_style is not None:
        config['topRightTrayStyle'] = args.top_right_tray_style
    if args.island_compact_width is not None:
        config['islandCompactWidth'] = args.island_compact_width
    if args.island_compact_height is not None:
        config['islandCompactHeight'] = args.island_compact_height
    if args.island_corner_radius is not None:
        config['islandCornerRadius'] = args.island_corner_radius
    if args.island_top_offset is not None:
        config['islandTopOffset'] = args.island_top_offset
    if args.island_inner_padding is not None:
        config['islandInnerPadding'] = args.island_inner_padding
    if args.reserved_top_space is not None:
        config['reservedTopSpace'] = args.reserved_top_space
    if args.show_top_left_pill is not None:
        config['showTopLeftPill'] = (args.show_top_left_pill.lower() == "true")
    if args.show_top_right_cava is not None:
        config['showTopRightCava'] = (args.show_top_right_cava.lower() == "true")
    if args.show_top_right_battery is not None:
        config['showTopRightBattery'] = (args.show_top_right_battery.lower() == "true")
    if args.show_top_right_pill is not None:
        config['showTopRightPill'] = (args.show_top_right_pill.lower() == "true")
    if args.show_top_right_tray is not None:
        config['showTopRightTray'] = (args.show_top_right_tray.lower() == "true")
    if args.island_auto_hide is not None:
        config['islandAutoHideEnabled'] = (args.island_auto_hide.lower() == "true")
    if args.notepad_default_mode is not None:
        config['notepadDefaultMode'] = args.notepad_default_mode
    if args.notepad_auto_save is not None:
        config['notepadAutoSave'] = (args.notepad_auto_save.lower() == "true")
    if args.tlp_permission_mode is not None:
        config['tlpPermissionMode'] = args.tlp_permission_mode
    if args.auto_wallpaper_enabled is not None:
        config['autoWallpaperEnabled'] = (args.auto_wallpaper_enabled.lower() == "true")
    if args.auto_wallpaper_interval is not None:
        config['autoWallpaperInterval'] = args.auto_wallpaper_interval
    if args.auto_wallpaper_notification is not None:
        config['autoWallpaperNotification'] = (args.auto_wallpaper_notification.lower() == "true")
    if args.random_wallpaper_on_startup is not None:
        config['randomWallpaperOnStartup'] = (args.random_wallpaper_on_startup.lower() == "true")
    if args.wallpaper_folder is not None:
        config['wallpaperFolder'] = args.wallpaper_folder

    os.makedirs(os.path.dirname(config_path), exist_ok=True)
    with open(config_path, 'w') as f:
        json.dump(config, f, indent=4)
    print("Updated userconfig.json successfully")

if __name__ == "__main__":
    main()
