hl.config({
    input = {
        touchpad = {
            natural_scroll = true
        }
    },
})

-- 4-finger vertical swipe gestures for workspace switching
hl.gesture({ fingers = 3, direction = "down", action = function() hl.dispatch(hl.dsp.focus({ workspace = "r-1" })) end })
hl.gesture({ fingers = 3, direction = "up", action = function() hl.dispatch(hl.dsp.focus({ workspace = "r+1" })) end })

hl.gesture({ fingers = 3, direction = "swipe", action = "scroll_move" })
