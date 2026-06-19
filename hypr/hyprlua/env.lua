-- =========================================================================
-- USER CONFIGURATION - Customize these values for your setup
-- =========================================================================

-- The folder where you cloned this repository (HyprDots)
hyprdots_dir = os.getenv("HOME") .. "/.local/src/HyprDots"

-- Your active wallpaper path
wallpaper_path = os.getenv("HOME") .. "/Pictures/Wallpapers/eki.jpg"

-- The path to your Obsidian vault (where matugen.css snippet should be generated)
obsidian_vault = os.getenv("HOME") .. "/ObsidianVault"

-- The directory name of your Zen browser profile under ~/.config/zen/
-- Look inside ~/.config/zen/ to find your profile name (it usually ends with ".Default (release)")
zen_profile = "vzvuye4x.Default (release)"

-- Preferred default applications
mainMod = "SUPER"
terminal = "kitty"
filemanager = "dolphin"
code_editor = "code"
browser = "firefox"

-- =========================================================================
-- SYSTEM CONFIGURATION - Do not modify below this line
-- =========================================================================

-- Set the directory for screenshots
hl.env("HYPRSHOT_DIR", os.getenv("HOME") .. "/Pictures/hyprshot/")

-- Set the current desktop environment to KDE to ensure compatibility with certain applications (like dolphin)
hl.env("XDG_CURRENT_DESKTOP", "KDE")