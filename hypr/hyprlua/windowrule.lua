local mat = require("colors")

hl.window_rule({
    match = {
        class = "kitty",
        title = "btop"
    },
    float = true,
    size = { 1000, 750 },
    center = true
})


hl.window_rule({

    match = {

        class = "org.kde.dolphin"

    },

    float = true,
    persistent_size = true

})

hl.layer_rule({
    name = "screenshot_overlay",
    blur = true,
    ignore_alpha = true,
    no_screen_share = true
})

hl.layer_rule({
    name = "screenshot_recording",
    no_screen_share = true
})

hl.window_rule({
    match = { title = "Screenshot Recording Pill" },
    float = true,
    pin = true,
    border_size = 0,
    no_shadow = true,
    no_initial_focus = true,
    no_screen_share = true,
    move = "monitor_w/2-160 monitor_h-144"
})

-- Float and center the Cheat sheet window
hl.window_rule({
    match = { title = "Cheat sheet" },
    float = true,
    size = { 1100, 600 },
    center = true
})
