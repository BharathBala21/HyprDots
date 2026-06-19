
hl.gesture({
    fingers = 4,
    direction = "horizontal",
    action = "workspace"
})



hl.gesture({
  fingers = 4,
  direction = "up",
  action = function()
    hl.exec_cmd("qs ipc -p /home/aashiqed/.local/src/HyprDots/tide-island call overview toggle")
  end
})

hl.gesture({
  fingers = 4,
  direction = "down",
  action = function()
    hl.exec_cmd("qs ipc -p /home/aashiqed/.local/src/HyprDots/tide-island call overview toggle")
  end
})


hl.gesture({
  fingers = 3,
  direction = "swipe",
  action = "move"
})


hl.config({

    input =  {
		touchpad = {
			natural_scroll = true
		}
	},
})

-- hl.device({
-- 	name = "etps/2-elantech-touchpad",
-- 	enabled = false,
-- })
