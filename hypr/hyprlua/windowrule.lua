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
    ignore_alpha = true
})
