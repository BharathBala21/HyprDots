require("hyprlua.env")
require("monitors")
require("hyprlua.binds")
require("hyprlua.general")
require("hyprlua.decoration")
require("hyprlua.exec")
require("hyprlua.workspace")
require("hyprlua.windowrule")
require("colors")
require("hyprlua.input")
require("hyprlua.animations")
require("hyprlua.plugins")
require("hyprlua.noctalia")

hl.env("HYPRCURSOR_THEME", "Moga")
hl.env("HYPRCURSOR_SIZE", "24")

hl.env("XCURSOR_THEME", "Moga")
hl.env("XCURSOR_SIZE", "24")


-- For Noctalia Color templates
require("noctalia").apply_theme()
