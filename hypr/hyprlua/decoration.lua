local mat = require("colors")
hl.config (
    {
        decoration = {
            rounding = 18,
            dim_inactive = true,
            dim_strength = 0.35,
            shadow = {
                color = "rgba(00000040)",
                color_inactive = "rgba(00000040)",
                range = 20,
                -- sharp = true,
                -- render_power = 10
            },
            glow = {
                -- enabled = true,
                range = 50
            },
            blur = {
                enabled = true,
                size = 8,
                passes = 1,
                ignore_opacity = true,
                new_optimizations = true,
                xray = false,
                noise = 0.0177,
                contrast = 0.8916,
                brightness = 0.8172,
                vibrancy = 0.1696,
                vibrancy_darkness = 0.0000
            },
            motion_blur = {
                enabled = true
            },
        },
    }
)