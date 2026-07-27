local mat = require("colors")
hl.config (

{
    general = {
        layout = "scrolling",
        gaps_out = {top = 10,left = 25,right = 25, bottom = 10},
        gaps_in = 10,
        border_size = 1,
        col = {
            active_border = mat.primary,
            inactive_border = mat.surface
        }
    }
}

)