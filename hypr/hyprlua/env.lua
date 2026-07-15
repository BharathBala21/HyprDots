
-- Preferred default applications
mainMod = "SUPER"
terminal = "kitty"
filemanager = "dolphin"
code_editor = "code"
browser = "zen-browser"


hl.env("HYPRSHOT_DIR", os.getenv("HOME") .. "/Pictures/hyprshot/")

--XDF
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Toolkit Backend Variables
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")


--Qt Variables
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORMTHEME", "kde")