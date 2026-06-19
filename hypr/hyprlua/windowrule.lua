local mat = require("colors")
hl.window_rule({

    match = {
        class = "waypaper"
    },
    float = true,
    persistent_size = true
})
hl.window_rule({

    match = {
        class = "kitty|code|firefox|thunar|org.kde.dolphin|yazi|discord"
    },
    opacity=0.77
})

hl.window_rule({
    match = {
        class = "thunar|org.kde.dolphin"
    },
    float = true,
    size = { 800, 550 },
    center = true
})

hl.window_rule({
    match = {
        class = "kitty",
        title = "btop"
    },
    float = true,
    size = { 1000, 750 },
    center = true
})