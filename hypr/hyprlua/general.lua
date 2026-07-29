local mat = require("colors")
hl.config (

{
    general = {
        layout = "scrolling",
        gaps_out = {top = 10,left = 25,right = 25, bottom = 10},
        gaps_in = 10,
        border_size = 0,
        col = {
            active_border = mat.primary,
            inactive_border = mat.surface
        }
    },

    binds = {
        hide_special_on_workspace_change = true
    },


     misc = {
        disable_hyprland_logo = true,
        disable_autoreload = false,
        focus_on_activate = true
    },

    gestures = {
        
    }

}

)