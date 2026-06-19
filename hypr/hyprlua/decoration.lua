local mat = require("colors")
hl.config (
    {
        decoration = {
            rounding = 7,
            -- dim_special = 0.5,

        --     blur = {
        --         -- enabled = false
        --     -- special = trues
        --     size = 12,
        --     passes = 1,
        --     ignore_opacity = false,
        --     contrast = 1.5,
            
        --   },
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