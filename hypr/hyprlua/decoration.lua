local mat = require("colors")
hl.config (
    {
        decoration = {
            rounding = 7,
            -- dim_special = 0.5,

            blur = {
                -- enabled = false
                size=25,
                passes = 3,
                vibrancy=0,
                contrast=2
            -- special = trues
          },
          shadow = {
            -- enabled = false,
            color = mat.outline,
            color_inactive = mat.outline_variant,
            range = 1
            -- color = "rgb(AC128C)",
          }
        },
    }
)