require("hyprlua.env")

-- hl.bind(keys, dispatcher, { flag1 = true, flag2 = true })


local closeWindowBind = hl.bind(mainMod .. " + Q", hl.dsp.window.close())

-- Move focus with "SUPER" + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Cycle through windows with "ALT + TAB"
hl.bind("ALT + TAB", hl.dsp.window.cycle_next())
hl.bind("ALT + SHIFT + TAB", hl.dsp.window.cycle_next({ next = false }))


-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })


-- Window drag & resize
-- 1. Using keyboard shortcuts + mouse movement
hl.bind(mainMod .. "+ Z", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. "+ X",hl.dsp.window.resize(), {mouse = true})
-- 2. Using mouse buttons (while holding the modifier key)
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

--pseudmode
hl.bind("SUPER + P", hl.dsp.window.pseudo())


-- change focused workspace
hl.bind(mainMod .. "+ 1",hl.dsp.focus({workspace = 1}))
hl.bind(mainMod .. "+ 2",hl.dsp.focus({workspace = 2}))
hl.bind(mainMod .. "+ 3",hl.dsp.focus({workspace = 3}))
hl.bind(mainMod .. "+ 4",hl.dsp.focus({workspace = 4}))
hl.bind(mainMod .. "+ 5",hl.dsp.focus({workspace = 5}))
hl.bind(mainMod .. "+ 6",hl.dsp.focus({workspace = 6}))
hl.bind(mainMod .. "+ 7",hl.dsp.focus({workspace = 7}))
hl.bind(mainMod .. "+ 8",hl.dsp.focus({workspace = 8}))
hl.bind(mainMod .. "+ 9",hl.dsp.focus({workspace = 9}))
-- move to next/previous workspace
-- 1. Using keyboard
hl.bind("SUPER + CTRL + left",  hl.dsp.focus({ workspace = "r-1" }))
hl.bind("SUPER + CTRL + right", hl.dsp.focus({ workspace = "r+1" }))
-- 2. Using mouse scroll
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "r+1" }))
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "r-1" }))

--move window to a specific tab
hl.bind(mainMod .. " + ALT + 1",hl.dsp.window.move({workspace = 1  }) )
hl.bind(mainMod .. " + ALT + 2",hl.dsp.window.move({workspace = 2  }) )
hl.bind(mainMod .. " + ALT + 3",hl.dsp.window.move({workspace = 3  }) )
hl.bind(mainMod .. " + ALT + 4",hl.dsp.window.move({workspace = 4  }) )
hl.bind(mainMod .. " + ALT + 5",hl.dsp.window.move({workspace = 5  }) )
hl.bind(mainMod .. " + ALT + 6",hl.dsp.window.move({workspace = 6  }) )
hl.bind(mainMod .. " + ALT + 7",hl.dsp.window.move({workspace = 7  }) )
hl.bind(mainMod .. " + ALT + 8",hl.dsp.window.move({workspace = 8  }) )
hl.bind(mainMod .. " + ALT + 9",hl.dsp.window.move({workspace = 9  }) )

--toggle floating state
hl.bind(mainMod .. "+ ALT + SPACE", hl.dsp.window.float())

--move window within a workspace
hl.bind(mainMod .. "+SHIFT + up",hl.dsp.window.move({direction = "up"}))
hl.bind(mainMod .. "+SHIFT + down",hl.dsp.window.move({direction = "down"}))
hl.bind(mainMod .. "+SHIFT + left",hl.dsp.window.move({direction = "left"}))
hl.bind(mainMod .. "+SHIFT + right",hl.dsp.window.move({direction = "right"}))


--fullscreen a window
hl.bind(mainMod .. "+F",hl.dsp.window.fullscreen({mode = "fullscreen"}))
-- maximize a window
hl.bind(mainMod .. "+D",hl.dsp.window.fullscreen({mode = "maximized"}))

hl.bind(
    "SUPER + SUPER_L",
    hl.dsp.exec_cmd(
        "qs ipc -p " .. os.getenv("HOME") .. "/.local/src/HyprDots/tide-island call island toggleLauncher"
    ),
    { release = true }
)


--application binds
-- hl.bind(mainMod .. " +ALT+E", hl.dsp.exec_cmd("kitty yazi"))
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(filemanager))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(code_editor))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(browser))


--special workspaces
hl.bind("SUPER + ALT + S", function ()
    hl.dispatch(hl.dsp.workspace.toggle_special("spotify_special"))
    hl.workspace_rule({ workspace = "special:spotify_special", on_created_empty = "spotify" })
end)

hl.bind("SUPER+ALT+D", function ()
    hl.dispatch(hl.dsp.workspace.toggle_special("discord_special"))
    hl.workspace_rule({workspace = "special:discord_special", on_created_empty = "discord"})
end)

hl.bind("SUPER+ALT+E", function ()
    hl.dispatch(hl.dsp.workspace.toggle_special("yazi_special"))
    hl.workspace_rule({workspace = "special:yazi_special", on_created_empty = "kitty sudo yazi",})
end)

hl.bind("SUPER+ALT+RETURN", function ()
    local mon = hl.get_active_monitor()
    local left = math.floor(math.ceil(mon.width / mon.scale or 1) * 0.5)
    hl.dispatch(hl.dsp.workspace.toggle_special("terminal_special"))
    hl.workspace_rule({workspace = "special:terminal_special", on_created_empty = "kitty",layout = "scrolling",gaps_out = { left = left, right = 0, top = 0, bottom = 0 },})
end)



hl.bind(
    mainMod .. " + V",
    hl.dsp.exec_cmd(
        "qs ipc -p " .. os.getenv("HOME") .. "/.local/src/HyprDots/tide-island call island toggleClipboard"
    )
)

hl.bind(
    mainMod .. " + period",
    hl.dsp.exec_cmd(
        "qs ipc -p " .. os.getenv("HOME") .. "/.local/src/HyprDots/tide-island call island toggleEmojis"
    )
)

hl.bind(
    mainMod .. " + ALT + W",
    hl.dsp.exec_cmd(
        "qs ipc -p " .. os.getenv("HOME") .. "/.local/src/HyprDots/tide-island call island toggleWallpapers"
    )
)

--hyprpicker
hl.bind(mainMod .. " +SHIFT + C",hl.dsp.exec_cmd("hyprpicker -a"))

--hyprshot
hl.bind(mainMod .. " +SHIFT + S", hl.dsp.exec_cmd("hyprshot -z -m region"))
hl.bind("Print", hl.dsp.exec_cmd("hyprshot -z -m output"))
hl.bind(mainMod .. " +SHIFT + W", hl.dsp.exec_cmd("hyprshot -z -m window"))

--wf-Recorder
hl.bind(mainMod .. " + R", function()
    local status = os.execute("pgrep -x wf-recorder")
    local is_running = (status == 0 or status == true)
    if is_running then
        hl.exec_cmd(os.getenv("HOME") .. "/.local/src/HyprDots/tide-island/bin/record.sh")
    else
        hl.exec_cmd(os.getenv("HOME") .. "/.local/src/HyprDots/tide-island/bin/record.sh -r")
    end
end)



--TIDE-ISLAND-OVERVIEW
hl.bind(
    "SUPER + TAB",
    hl.dsp.exec_cmd(
        "qs ipc -p " .. os.getenv("HOME") .. "/.local/src/HyprDots/tide-island call overview toggle"
    )
)

hl.bind(
    "SUPER + A",
    hl.dsp.exec_cmd(
        "qs ipc -p " .. os.getenv("HOME") .. "/.local/src/HyprDots/tide-island call island toggleControlCenter"
    )
)

-- btop
hl.bind("CTRL + SHIFT + code:9",
    hl.dsp.exec_cmd("pgrep -x btop && pkill -x btop || kitty --title btop btop")
)

-- Lock screen
hl.bind("SUPER + L", hl.dsp.exec_cmd("~/.local/share/quickshell-lockscreen/lock.sh"))