#!/bin/bash

# ==============================================================================
# HyprDots Installation Script
# ==============================================================================
# A comprehensive, interactive setup script to deploy and configure these
# dotfiles on Arch Linux.
# ==============================================================================

# Exit on error for critical commands, but handle optional steps gracefully
set -e

# --- Colors and Styles ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# --- Logging Helpers ---
log_info() {
    echo -e "${BLUE}${BOLD}[INFO]${RESET} $1"
}

log_success() {
    echo -e "${GREEN}${BOLD}[SUCCESS]${RESET} $1"
}

log_warning() {
    echo -e "${YELLOW}${BOLD}[WARNING]${RESET} $1"
}

log_error() {
    echo -e "${RED}${BOLD}[ERROR]${RESET} $1"
}

# --- Prompt Helper ---
# Usage: prompt_yes_no "Do you want to proceed?" "y"
# Returns 0 for Yes, 1 for No
prompt_yes_no() {
    local question="$1"
    local default="${2:-y}"
    local prompt_str

    if [[ "$default" =~ ^[Yy]$ ]]; then
        prompt_str="[Y/n]"
    else
        prompt_str="[y/N]"
    fi

    while true; do
        read -rp "$(echo -e "${CYAN}${BOLD}?${RESET} ${question} ${prompt_str} ")" choice
        choice="${choice:-$default}"
        case "$choice" in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo -e "${RED}Please answer yes or no.${RESET}" ;;
        esac
    done
}

# --- Welcome Banner ---
clear
echo -e "${MAGENTA}${BOLD}"
echo "██╗  ██╗██╗   ██╗██████╗ ██████╗ ██████╗  ██████╗ ████████╗███████╗"
echo "██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝"
echo "███████║ ╚████╔╝ ██████╔╝██████╔╝██║  ██║██║   ██║   ██║   ███████╗"
echo "██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗██║  ██║██║   ██║   ██║   ╚════██║"
echo "██║  ██║   ██║   ██║     ██║  ██║██████╔╝╚██████╔╝   ██║   ███████║"
echo "╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚═════╝  ╚═════╝    ╚═╝   ╚══════╝"
echo -e "${RESET}"
echo -e "${CYAN}${BOLD}Hyprland Dotfiles Setup Wizard${RESET}"
echo -e "========================================================\n"

# --- Repo Directory Discovery ---
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log_info "Detected repository directory: ${BOLD}${REPO_DIR}${RESET}"

# --- Step 1: OS Check ---
log_info "Checking system requirements..."
if [ ! -f /etc/arch-release ]; then
    log_warning "This script is designed and optimized for Arch Linux."
    if ! prompt_yes_no "Do you want to proceed anyway?" "n"; then
        log_info "Installation aborted."
        exit 0
    fi
else
    log_success "Arch Linux detected."
fi

# --- Step 2: Package Manager & AUR Helper Check ---
AUR_HELPER=""
if command -v paru &>/dev/null; then
    AUR_HELPER="paru"
elif command -v yay &>/dev/null; then
    AUR_HELPER="yay"
fi

if [ -n "$AUR_HELPER" ]; then
    log_success "Found AUR helper: ${BOLD}${AUR_HELPER}${RESET}"
else
    log_warning "No AUR helper (paru or yay) detected."
    log_info "You will need to manually install AUR packages (quickshell, matugen)."
fi

# --- Step 3: Package Installation ---
REQUIRED_PACMAN=(
    "hyprland" "hyprpaper" "hypridle" "hyprlock" "hyprcursor"
    "wl-clipboard" "cliphist" "dunst" "waypaper" "cava"
    "btop" "fastfetch" "fish" "kitty" "yazi" "python" "python-pillow" "jq"
    "wireplumber" "brightnessctl" "hyprpicker" "hyprshot" "tesseract"
    "tesseract-data-eng" "zbar" "grim" "slurp" "wf-recorder" "libnotify"
    "ttf-jetbrains-mono-nerd"
    "cmake" "qt6-base" "qt6-declarative" "qt6-connectivity" "qt6-svg"
    "libpulse" "hyprsunset" "upower" "bluez" "bluez-utils"
)
REQUIRED_AUR=(
    "quickshell" "matugen"
)

install_packages() {
    local missing_pacman=()
    local missing_aur=()

    log_info "Checking installed packages..."
    
    # Check official packages
    for pkg in "${REQUIRED_PACMAN[@]}"; do
        if ! pacman -Qq "$pkg" &>/dev/null; then
            missing_pacman+=("$pkg")
        fi
    done

    # Check AUR packages
    for pkg in "${REQUIRED_AUR[@]}"; do
        if ! pacman -Qq "$pkg" &>/dev/null; then
            missing_aur+=("$pkg")
        fi
    done

    # Show status
    if [ ${#missing_pacman[@]} -eq 0 ] && [ ${#missing_aur[@]} -eq 0 ]; then
        log_success "All required packages are already installed."
        return 0
    fi

    if [ ${#missing_pacman[@]} -gt 0 ]; then
        echo -e "\n${YELLOW}Missing official packages:${RESET} ${missing_pacman[*]}"
    fi
    if [ ${#missing_aur[@]} -gt 0 ]; then
        echo -e "${YELLOW}Missing AUR packages:${RESET} ${missing_aur[*]}"
    fi

    if prompt_yes_no "Do you want to install the missing packages?" "y"; then
        # Install official packages
        if [ ${#missing_pacman[@]} -gt 0 ]; then
            log_info "Installing official packages via pacman..."
            sudo pacman -S --needed "${missing_pacman[@]}"
        fi

        # Install AUR packages
        if [ ${#missing_aur[@]} -gt 0 ]; then
            if [ -n "$AUR_HELPER" ]; then
                log_info "Installing AUR packages via $AUR_HELPER..."
                $AUR_HELPER -S --needed "${missing_aur[@]}"
            else
                log_error "No AUR helper found. Please install the following AUR packages manually:"
                echo -e "  ${REQUIRED_AUR[*]}"
            fi
        fi
        log_success "Package installation completed."
    else
        log_info "Skipping package installation."
    fi
}

build_and_install_tide_island() {
    # Check if tide-island package is installed, if so remove it
    if pacman -Qq tide-island &>/dev/null; then
        log_info "Removing existing AUR package 'tide-island' to prevent conflicts..."
        sudo pacman -Rns --noconfirm tide-island
    fi

    # Ensure /usr/share/tide-island is not a directory or symlink before build/install
    if [ -L "/usr/share/tide-island" ]; then
        log_info "Removing existing symlink /usr/share/tide-island before installation..."
        sudo rm -f "/usr/share/tide-island"
    elif [ -d "/usr/share/tide-island" ]; then
        log_info "Removing existing directory /usr/share/tide-island before installation..."
        sudo rm -rf "/usr/share/tide-island"
    fi

    log_info "Downloading Tide-Island stable source tarball..."
    local temp_dir
    temp_dir=$(mktemp -d)
    local tarball="${temp_dir}/tide-island.tar.gz"
    local commit="106d38f4e1f4e683156564c1ae122ef7abc2a3cb"
    
    if ! curl -L "https://github.com/enhaoswen/Tide-island/archive/${commit}.tar.gz" -o "$tarball"; then
        log_error "Failed to download Tide-Island source code."
        rm -rf "$temp_dir"
        return 1
    fi
    
    log_info "Extracting source..."
    tar -xf "$tarball" -C "$temp_dir"
    local src_dir="${temp_dir}/Tide-island-${commit}"
    local build_dir="${temp_dir}/build"

    log_info "Building Tide-Island from source..."
    cmake -S "$src_dir" -B "$build_dir" \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_BUILD_TYPE=Release
        
    cmake --build "$build_dir"
    
    # Install to system directories (plugins, launcher, service)
    log_info "Installing compiled Tide-Island assets to system directories (requires sudo)..."
    sudo cmake --install "$build_dir"

    # Copy the freshly built binaries back to the repository's bin/ directory
    # so they are available via the /usr/share/tide-island symlink
    log_info "Deploying new binaries to repository bin/ folder..."
    mkdir -p "${REPO_DIR}/tide-island/bin"
    cp -f "$build_dir/lyricsmpris" "${REPO_DIR}/tide-island/bin/"
    cp -f "$build_dir/tide-island-setup" "${REPO_DIR}/tide-island/bin/"
    
    chmod +x "${REPO_DIR}/tide-island/bin/lyricsmpris"
    chmod +x "${REPO_DIR}/tide-island/bin/tide-island-setup"
    
    # Clean up temporary build files
    rm -rf "$temp_dir"
    log_success "Tide-Island successfully built and installed from source."
}

# --- Pre-installation Symlink Safety Cleanup ---
# If /usr/share/tide-island is a symbolic link, we must remove it BEFORE running
# the package manager (pacman/yay). Otherwise, pacman will follow the symlink
# during package installation/upgrade and delete the files inside the repository!
if [ -L "/usr/share/tide-island" ]; then
    log_info "Removing temporary system symlink /usr/share/tide-island to protect repository files from pacman..."
    sudo rm -f "/usr/share/tide-island"
fi

install_packages
build_and_install_tide_island

# --- Step 3.5: Auto-create Ignored Config Files ---
create_ignored_files() {
    log_info "Verifying ignored configuration files are present..."

    # Ensure hypr/hyprlua/custom/ directory exists
    local custom_dir="${REPO_DIR}/hypr/hyprlua/custom"
    if [ ! -d "$custom_dir" ]; then
        log_info "Creating missing custom directory: ${custom_dir}"
        mkdir -p "$custom_dir"
    fi

    # Ensure hypr/hyprlua/custom/exec.lua exists
    local custom_exec="${custom_dir}/exec.lua"
    if [ ! -f "$custom_exec" ]; then
        log_info "Creating missing exec.lua placeholder: ${custom_exec}"
        touch "$custom_exec"
    fi

    # Ensure hypr/hyprlua/gui.lua exists
    local gui_lua="${REPO_DIR}/hypr/hyprlua/gui.lua"
    if [ ! -f "$gui_lua" ]; then
        log_info "Creating missing gui.lua from default template: ${gui_lua}"
        cat << 'EOF' > "$gui_lua"
local mat = require("colors")

hl.config (
{
    general = {
        gaps_out = 15,
        gaps_in = 5,
        border_size = 2,
        col = {
            active_border = mat.primary,
            inactive_border = mat.surface
        }
    },
    decoration = {
        rounding = 12,
        shadow = {
            color = mat.outline,
            color_inactive = mat.outline_variant,
            range = 1
        },
        blur = {
            enabled = true,
            size = 8,
            passes = 1,
            ignore_opacity = true,
            new_optimizations = true,
            xray = false,
            noise = 0.0117,
            contrast = 0.8916,
            brightness = 0.8172,
            vibrancy = 0.1696,
            vibrancy_darkness = 0.0000
        }
    }
}
)
EOF
        log_success "Created gui.lua"
    fi
}

create_ignored_files

# --- Step 4: Symlink Configurations in ~/.config ---
CONFIG_DIRS=("btop" "cava" "dunst" "fastfetch" "fish" "hypr" "kitty" "matugen")

setup_configs() {
    if prompt_yes_no "Do you want to symlink configuration folders to ~/.config/?" "y"; then
        mkdir -p "$HOME/.config"
        
        # Ensure ~/.config/yazi exists as a real directory (not in repo, but needed by matugen)
        local yazi_dest="${HOME}/.config/yazi"
        if [ -L "$yazi_dest" ]; then
            log_info "Removing conflicting yazi symlink..."
            rm -f "$yazi_dest"
        fi
        mkdir -p "$yazi_dest"

        local timestamp
        timestamp=$(date +"%Y%m%d_%H%M%S")

        for dir in "${CONFIG_DIRS[@]}"; do
            local source_path="${REPO_DIR}/${dir}"
            local dest_path="${HOME}/.config/${dir}"

            if [ ! -d "$source_path" ]; then
                log_warning "Source directory $source_path does not exist. Skipping."
                continue
            fi

            # Check if destination exists
            if [ -e "$dest_path" ] || [ -L "$dest_path" ]; then
                # Check if it's already a symlink pointing to the right place
                if [ -L "$dest_path" ] && [ "$(readlink -f "$dest_path")" = "$source_path" ]; then
                    log_info "${BOLD}$dir${RESET} is already symlinked correctly."
                    continue
                fi

                # Delete existing safely
                if [ -L "$dest_path" ]; then
                    log_info "Removing existing symlink: ${dest_path}"
                    rm -f "$dest_path"
                else
                    log_info "Removing existing directory: ${dest_path}"
                    rm -rf "$dest_path"
                fi
            fi

            # Create symlink
            ln -sf "$source_path" "$dest_path"
            log_success "Symlinked ${BOLD}$dir${RESET} -> ~/.config/$dir"
        done
    else
        log_info "Skipping configuration symlinking."
    fi
}

setup_configs

# --- Step 4.5: Change Default Shell to Fish ---
setup_shell() {
    local fish_path
    fish_path=$(command -v fish || true)

    if [ -n "$fish_path" ] && [ "$SHELL" != "$fish_path" ]; then
        if prompt_yes_no "Do you want to change your default shell to Fish?" "y"; then
            log_info "Changing default shell to Fish (requires password)..."
            if chsh -s "$fish_path"; then
                log_success "Default shell changed to Fish."
            else
                log_warning "Failed to change default shell to Fish. You can run 'chsh -s $fish_path' manually later."
            fi
        fi
    fi
}

setup_shell

# --- Step 5: Cursor Theme (Moga) ---
setup_cursor() {
    local cursor_src="${REPO_DIR}/Cursor/Moga"
    local local_icons_dir="${HOME}/.local/share/icons"
    local system_icons_dir="/usr/share/icons/Moga"

    if [ -d "$cursor_src" ]; then
        if prompt_yes_no "Do you want to set up the Moga cursor theme in your user directory?" "y"; then
            # Verify if already installed system-wide
            if [ -d "$system_icons_dir" ]; then
                log_info "Moga cursor theme is already installed system-wide at ${system_icons_dir}."
            fi

            mkdir -p "$local_icons_dir"
            local dest_cursor="${local_icons_dir}/Moga"

            if [ -e "$dest_cursor" ] || [ -L "$dest_cursor" ]; then
                if [ -L "$dest_cursor" ] && [ "$(readlink -f "$dest_cursor")" = "$cursor_src" ]; then
                    log_info "Moga cursor is already symlinked in ~/.local/share/icons."
                else
                    if [ -L "$dest_cursor" ]; then
                        log_info "Removing existing cursor symlink: ${dest_cursor}"
                        rm -f "$dest_cursor"
                    else
                        log_info "Removing existing cursor directory: ${dest_cursor}"
                        rm -rf "$dest_cursor"
                    fi
                    ln -sf "$cursor_src" "$dest_cursor"
                    log_success "Symlinked Moga cursor theme to ~/.local/share/icons/Moga"
                fi
            else
                ln -sf "$cursor_src" "$dest_cursor"
                log_success "Symlinked Moga cursor theme to ~/.local/share/icons/Moga"
            fi
        fi
    fi
}

setup_cursor

# --- Step 6: Wallpapers ---
setup_wallpapers() {
    local wallpaper_src_dir="${REPO_DIR}/assets"
    local wallpaper_dest_dir="${HOME}/Pictures/Wallpapers"

    if [ -d "$wallpaper_src_dir" ]; then
        log_info "Copying wallpapers to ~/Pictures/Wallpapers..."
        mkdir -p "$wallpaper_dest_dir"
        
        # Copy wallpaper files with their original names (needed for configs like waypaper)
        for wp in "$wallpaper_src_dir"/*.{png,jpg,jpeg}; do
            [ -e "$wp" ] || continue
            local filename
            filename=$(basename "$wp")
            
            cp "$wp" "${wallpaper_dest_dir}/${filename}"
            log_success "Copied $(basename "$wp") -> ~/Pictures/Wallpapers/${filename}"
        done

        # Apply matugen for the new default wallpaper
        if command -v matugen &>/dev/null; then
            log_info "Generating Material You colors with matugen for tom_jazz.png..."
            matugen image --source-color-index 0 "${wallpaper_dest_dir}/tom_jazz.png" || log_warning "Matugen failed to generate colors."
        else
            log_warning "matugen is not installed. Skipping color generation."
        fi
    fi
}

setup_wallpapers

# --- Step 7: Tide-Island System Integration ---
setup_tide_island() {
    log_info "Integrating Tide-Island (Dynamic Island widget)..."

    # Make helper scripts executable
    log_info "Setting executable permissions on scripts..."
    chmod +x "${REPO_DIR}/tide-island/bin/"* 2>/dev/null || true
    chmod +x "${REPO_DIR}/tide-island/lockscreen/lock.sh" 2>/dev/null || true
    chmod +x "${REPO_DIR}/Scripts/"* 2>/dev/null || true

    local target_share="/usr/share/tide-island"
    local source_tide="${REPO_DIR}/tide-island"

    # Check the symlink in /usr/share/tide-island
    local needs_symlink=true
    if [ -L "$target_share" ]; then
        if [ "$(readlink -f "$target_share")" = "$source_tide" ]; then
            log_success "/usr/share/tide-island already correctly links to the repository."
            needs_symlink=false
        fi
    fi

    if [ "$needs_symlink" = true ]; then
        echo -e "\n${YELLOW}Tide Island Launcher requires /usr/share/tide-island to link to the QML source directory.${RESET}"
        if prompt_yes_no "Do you want to create the symbolic link in /usr/share/ (requires sudo)?" "y"; then
            if [ -L "$target_share" ]; then
                log_info "Removing existing symlink /usr/share/tide-island..."
                sudo rm -f "$target_share"
            elif [ -d "$target_share" ]; then
                log_info "Removing existing directory /usr/share/tide-island..."
                sudo rm -rf "$target_share"
            fi
            sudo ln -sfn "$source_tide" "$target_share"
            log_success "Symlinked /usr/share/tide-island -> $source_tide"
        fi
    fi

    # Apply tom_jazz.png wallpaper by default
    log_info "Applying default wallpaper (tom_jazz.png)..."
    if command -v waypaper &>/dev/null; then
        # Set via waypaper CLI (which also updates waypaper configuration)
        waypaper --wallpaper "${HOME}/Pictures/Wallpapers/tom_jazz.png" &>/dev/null || true
    fi

    # Update tide-island configuration with the new wallpaper path
    mkdir -p "${HOME}/.config/tide-island"
    local tide_config="${HOME}/.config/tide-island/userconfig.json"
    if [ ! -f "$tide_config" ]; then
        echo "{}" > "$tide_config"
    fi

    if command -v jq &>/dev/null; then
        log_info "Updating Tide Island configuration with the default wallpaper path..."
        local temp_json
        if temp_json=$(sed '/^[[:space:]]*\/\//d' "$tide_config" | jq --arg path "${HOME}/Pictures/Wallpapers/tom_jazz.png" '.wallpaperPath = $path' 2>/dev/null); then
            echo "$temp_json" > "$tide_config"
        else
            log_warning "Failed to parse and update Tide Island userconfig.json with jq. Skipping automatically updating wallpaper path."
        fi
    fi
}

setup_tide_island



# --- Final Step ---
# Create first boot flag file
mkdir -p "$HOME/.cache"
touch "$HOME/.cache/hyprdots_first_boot"

echo -e "\n========================================================"
log_success "HyprDots Installation and Configuration completed!"
echo -e "========================================================"
echo -e "A first-boot flag has been set to open the cheatsheet automatically."
echo -e "It is highly recommended to restart your system to apply all changes."
echo -e "========================================================"

if prompt_yes_no "Do you want to restart (reboot) your system now?" "y"; then
    log_info "Restarting system in 3 seconds..."
    sleep 3
    systemctl reboot || reboot
else
    echo -e "\nPlease reload Hyprland or restart your session later to apply changes."
    echo -e "Use ${BOLD}tide-island-setup --wizard${RESET} if you wish to re-configure Tide Island."
    echo -e "========================================================\n"
fi
