
-- Preferred default applications
mainMod = "SUPER"
terminal = "kitty"
filemanager = "dolphin"
code_editor = "code"
browser = "zen-browser"


hl.env("HYPRSHOT_DIR", os.getenv("HOME") .. "/Pictures/hyprshot/")

-- Themes
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("XDG_MENU_PREFIX", "plasma-")