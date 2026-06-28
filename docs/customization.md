---
title: Customization
description: Personalize HyerDOTS by editing configs, themes, and runtime overrides.
---

This page explains how to customize HyerDOTS without losing the repository source of truth.

## Repository-first workflow

HyerDOTS is intended to be edited in the repository, then installed or symlinked into `~/.config`.

- keep repo files as the canonical config
- avoid committing machine-specific secrets
- use local overrides for per-device customizations

## Customizing Hyprland behavior

Edit `hypr/hyprland.lua` to adjust general Hyprland settings.

Use `hypr/hyprlua/` for automation and input:

- `exec.lua` — control startup services
- `input.lua` — gesture and touchpad behavior
- `binds.lua` — shortcuts and workspace controls
- `windowrule.lua` — float rules and placement logic
- `env.lua` — default apps and environment variables

## Safe local overrides

Use `hypr/hyprlua/custom` for machine-specific settings.

- create local files when the installer prompts you
- add hardware-specific fixes or local paths
- keep the repo version unchanged

## Wallpaper and theme customization

To change the look of the desktop:

1. place a wallpaper in `assets/`
2. update `matugen/config.toml`
3. run `matugen` to regenerate themes
4. restart the apps that use the generated files

## Customizing the widget shell

Edit `tide-island/` to tune the home screen and island UI.

- `qml/` — adjust UI components and pages
- `bin/` — update helper scripts for wallpapers and recording
- `lockscreen/` — edit the lockscreen experience

## Terminal and shell tweaks

- `kitty/` contains terminal appearance settings
- `fish/` contains shell prompt and environment settings

If you need a terminal theme change, update the `kitty` files and restart Kitty.
If you want a shell update, edit the `fish` files and restart the shell.

## Preserving custom config

For local tweaks without affecting the repo:

- use `hypr/hyprlua/custom`
- keep personal overrides outside git
- apply custom files only on the target machine

## Summary

HyerDOTS is designed to be both customizable and maintainable.
Use the repository as the source of truth, and reserve local overrides for device-specific adjustments.
