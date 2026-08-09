<div align="center">

# Pirate's Dots

Personal Hyprland dotfiles configured with modular Lua (`hyprlua`), Material You dynamic color generation (`matugen`), and a custom dynamic island desktop shell (`tide-island`) built on Quickshell.

![Overview](assets/overview.png)

[![Arch Linux](https://img.shields.io/badge/OS-Arch%20Linux-blue?logo=arch-linux)](https://archlinux.org)
[![Compositor](https://img.shields.io/badge/Compositor-Hyprland%200.55%2B-blue?logo=wayland)](https://hyprland.org)
[![Config](https://img.shields.io/badge/Config-Lua-blue?logo=lua)](https://www.lua.org)
[![Shell](https://img.shields.io/badge/Shell-Quickshell-purple)](https://git.outfoxxed.me/outfoxxed/quickshell)
[![Theme](https://img.shields.io/badge/Palette-Matugen-pink)](https://github.com/Inori/matugen)

</div>

---

## Overview

**Pirate's Dots** is a polished Arch Linux desktop environment centered around the Hyprland Wayland compositor. It moves beyond standard static configs by implementing:

- **Modular Lua Configuration**: Fully transitioned to Hyprland's native Lua configuration (`hyprlua`), cleanly structured into environment, bindings, layouts, and window rules.
- **Dynamic Color Palettes**: `matugen` extracts live color swatches from your current wallpaper and applies matching Material Design tokens across system apps, kitty, cava, btop, and widgets.
- **Tide Island Shell**: A custom interactive desktop shell powered by Quickshell providing dynamic island control panels, media controls, notepad, wallpaper selectors, clipboard history, and system utilities.
- **Niri-Style Scrolling Layout**: Column-based window tiling with smooth scrolling, presets, and edge-to-edge fitting.

---

## Screenshots

<div align="center">

### Control Center & Wallpaper Selection
| Control Center | Wallpaper Selector |
| :---: | :---: |
| ![Control Center](assets/Control_Center.png) | ![Wallpaper Selector](assets/wallpaper_selector.png) |

### Launcher & Workspace Overview
| App Launcher | Overview |
| :---: | :---: |
| ![App Launcher](assets/app_launcher.png) | ![Niri Overview](assets/niri-overview.png) |

### Widgets & Notes
| Live Lyrics | Notepad |
| :---: | :---: |
| ![Live Lyrics](assets/live-lyrics.png) | ![Notepad](assets/Notepad.png) |

### System Tools & Timer
| Utilities | Timer | Settings |
| :---: | :---: | :---: |
| ![Utilities](assets/utilities.png) | ![Timer](assets/timer.png) | ![Settings](assets/Settings.png) |

</div>

---

## Repository Structure

```
.
├── hypr/                    # Hyprland Lua configuration (~/.config/hypr)
│   ├── hyprland.lua         # Main entry point importing hyprlua modules
│   ├── colors.lua           # Matugen color token definitions
│   └── hyprlua/             # Config modules (binds, layout, rules, etc.)
├── tide-island/             # Quickshell desktop shell & dynamic island widgets
├── matugen/                 # Material You color scheme generation templates
├── assets/                  # Screenshot assets & wallpaper previews
├── btop/                    # System resource monitor configuration
├── cava/                    # Audio visualizer configuration
├── dunst/                   # Notification daemon settings
├── fastfetch/               # System information display settings
├── fish/                    # Fish shell configurations & aliases
├── kitty/                   # Terminal emulator configuration
├── yazi/                    # Terminal file manager configuration
└── install.sh               # Comprehensive setup wizard script
```

---

## Keybindings

> `Super` is configured as the main modifier key (`mainMod`).

### Navigation & Window Controls

| Keybinding | Action |
| :--- | :--- |
| `Super` + `F` | Toggle Niri-style True Fullscreen (hides island pills) |
| `Super` + `Shift` + `F` | Toggle Column Width (0.5 vs 1.0) |
| `Super` + `M` | Fit active column to 100% monitor width (within gaps) |
| `Super` + `Alt` + `M` | **Fit window to 100% monitor width (ignoring gaps)** |
| `Super` + `Shift` + `M` | Expand column to fill available monitor space |
| `Super` + `R` | Cycle column width presets (`0.333`, `0.5`, `0.667`, `1.0`) |
| `Super` + `Tab` | Toggle Workspace Overview |
| `Super` + `Q` | Close active window |
| `Super` + `Alt` + `Space` | Toggle window floating state |
| `Super` + `Z` / `X` | Interactive window drag / resize |
| `Super` + `Arrow Keys` | Focus window in direction |
| `Super` + `Shift` + `Arrow Keys` | Move window in direction |

### Tide Island Widgets & Shell

| Keybinding | Action |
| :--- | :--- |
| `Super` + `D` | Toggle App Launcher |
| `Super` + `A` | Toggle Control Center |
| `Super` + `N` | Toggle Quick Notepad |
| `Super` + `V` | Toggle Clipboard Manager |
| `Super` + `U` | Toggle Quick Utilities |
| `Super` + `Alt` + `U` | Toggle Timer |
| `Super` + `Alt` + `W` | Open Live Wallpaper Selector |
| `Super` + `.` | Open Emoji Selector |
| `Super` + `/` | Toggle Keybinding Cheatsheet |
| `Super` + `L` | Lock Screen |

### Applications & Special Workspaces

| Keybinding | Action |
| :--- | :--- |
| `Super` + `Return` | Launch Terminal (`kitty`) |
| `Super` + `W` | Launch Web Browser |
| `Super` + `C` | Launch Code Editor |
| `Super` + `E` | Launch File Manager |
| `Super` + `Alt` + `S` | Toggle Scratchpad: Spotify |
| `Super` + `Alt` + `D` | Toggle Scratchpad: Discord |
| `Super` + `Alt` + `E` | Toggle Scratchpad: Yazi File Manager |
| `Super` + `Alt` + `Return` | Toggle Scratchpad: Floating Terminal |

### Tools & Screenshots

| Keybinding | Action |
| :--- | :--- |
| `Super` + `Shift` + `S` | Capture region screenshot (`hyprshot`) |
| `Print` | Capture full monitor screenshot |
| `Super` + `Shift` + `W` | Capture window screenshot |
| `Super` + `Shift` + `O` | Run OCR on selected region |
| `Super` + `Shift` + `V` | Perform visual search on selected region |
| `Super` + `Shift` + `B` | Scan QR code / barcode from screen |
| `Super` + `Shift` + `R` | Toggle screen recording (`wf-recorder`) |
| `Super` + `Shift` + `C` | Pick color from screen (`hyprpicker`) |

---

## Prerequisites & Dependencies

The configuration relies on the following core packages on Arch Linux:

| Component | Package(s) | Source |
| :--- | :--- | :--- |
| **Compositor & Core** | `hyprland`, `hyprpaper`, `hypridle`, `hyprlock`, `hyprcursor` | `pacman` |
| **Desktop Shell** | `quickshell`, `tide-island` | `AUR` |
| **Dynamic Colors** | `matugen` | `AUR` |
| **Terminal & Shell** | `kitty`, `fish`, `yazi`, `btop`, `cava`, `fastfetch` | `pacman` |
| **Utilities & Media** | `wl-clipboard`, `cliphist`, `dunst`, `waypaper`, `wireplumber`, `brightnessctl` | `pacman` |
| **Screen Tools** | `hyprpicker`, `hyprshot`, `grim`, `slurp`, `wf-recorder`, `tesseract`, `zbar` | `pacman` |

---

## Quick Start

Use the included setup script to automatically verify system requirements, install missing dependencies, configure symlinks, and set up system integration:

```bash
# 1. Clone the repository
git clone https://github.com/BharathBala21/HyprDots.git
cd HyprDots

# 2. Make the installer executable & run
chmod +x install.sh
./install.sh
```
