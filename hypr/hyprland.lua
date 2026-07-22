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
require("hyprlua.misc")
require("hyprlua.layout")
require("hyprlua.gui")
require("hyprlua.animations")
require("hyprlua.custom.exec")

hl.env("HYPRCURSOR_THEME", "Moga")
hl.env("HYPRCURSOR_SIZE", "24")

hl.env("XCURSOR_THEME", "Moga")
hl.env("XCURSOR_SIZE", "24")

-- .config/hypr/hyprland.lua
hl.config({
    plugin = {
        scrolloverview = {
            gesture_distance = 300, -- how far is the "max" for the gesture
            scale = 0.5, -- preferred overview scale
            workspace_gap = 100,
            layout = "vertical", -- vertical or horizontal
            wallpaper = 0, -- 0: global only, 1: per-workspace only, 2: both
            blur = true, -- blur only the main overview wallpaper

            shadow = {
                enabled = true,
                range = 50,
                render_power = 3,
                color = 0xee1a1a1a,
            },
        },
    },
})

-- hyprland.lua
hl.bind("SUPER + g", function()
    hl.plugin.scrolloverview.overview("toggle")
end)


