local mat = require("colors")
hl.config (
    {
        decoration = {
            rounding = 18,
            dim_inactive = false,
            dim_strength = 0.35,


            shadow = {
                enabled = true,
                 range = 4,
                render_power = 3,
                color = 0xee1a1a1a,
    },
            glow = {
                -- enabled = true,
                range = 50
            },
            blur = {
                enabled = false,
                size = 3,
                passes = 2,
            },
            motion_blur = {
                enabled = true
            },
        },
    }
)