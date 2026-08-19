require("hyprlua.env")

-- Helper for layout-aware keybindings
local function layout_bind(bind_table)
    return function()
        local workspace = hl.get_active_special_workspace() or hl.get_active_workspace()
        if not workspace then return end

        local layout = workspace.tiled_layout or "dwindle"
        local dispatcher = bind_table[layout] or bind_table["default"]
        if dispatcher then
            hl.dispatch(dispatcher)
        end
    end
end

local closeWindowBind = hl.bind(mainMod .. " + Q", hl.dsp.window.close())

-- Move focus with "SUPER" + arrow keys (layout aware: handles scrolling vs dwindle/master/etc)
hl.bind(mainMod .. " + left", layout_bind({
    scrolling = hl.dsp.layout("focus l"),
    default   = hl.dsp.focus({ direction = "left" }),
}))
hl.bind(mainMod .. " + right", layout_bind({
    scrolling = hl.dsp.layout("focus r"),
    default   = hl.dsp.focus({ direction = "right" }),
}))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))



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
hl.bind("SUPER + SHIFT+mouse_up", hl.dsp.focus({ workspace = "r+1" }))
hl.bind("SUPER + SHIFT+mouse_down", hl.dsp.focus({ workspace = "r-1" }))

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


-- Niri-style Fullscreen (True Fullscreen: hides tide-island pills, switchable with SUPER + Left/Right)
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", layout_aware = true }))

-- Niri-style Fit/Maximize (100% Monitor Width: keeps tide-island pills VISIBLE, switchable with SUPER + Left/Right)
local col_maximized = {}
hl.bind(mainMod .. " + SHIFT + F", function()
    local win = hl.get_active_window()
    local addr = win and win.address or "active"
    if col_maximized[addr] then
        hl.dispatch(hl.dsp.layout("colresize 0.5"))
        col_maximized[addr] = nil
    else
        hl.dispatch(hl.dsp.layout("colresize 1.0"))
        col_maximized[addr] = true
    end
end)

hl.bind(
    mainMod .. " + D",
    hl.dsp.exec_cmd(
        "qs ipc -p " .. os.getenv("HOME") .. "/.local/src/HyprDots/tide-island call island toggleLauncher"
    )
)

hl.bind(
    mainMod .. " + U",
    hl.dsp.exec_cmd(
        "qs ipc -p " .. os.getenv("HOME") .. "/.local/src/HyprDots/tide-island call island toggleUtilities"
    )
)

hl.bind(
    mainMod .. " + ALT + U",
    hl.dsp.exec_cmd(
        "qs ipc -p " .. os.getenv("HOME") .. "/.local/src/HyprDots/tide-island call island toggleTimer"
    )
)


--application binds
-- hl.bind(mainMod .. " +ALT+E", hl.dsp.exec_cmd("kitty yazi"))
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal,{float = true,size= {713,433}}))
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
    hl.workspace_rule({workspace = "special:yazi_special", on_created_empty = "kitty yazi",})
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
    mainMod .. " + N",
    hl.dsp.exec_cmd(
        "qs ipc -p " .. os.getenv("HOME") .. "/.local/src/HyprDots/tide-island call island toggleNotepad"
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

hl.bind(
    mainMod .. " + CTRL + W",
    hl.dsp.exec_cmd(
        "qs ipc -p " .. os.getenv("HOME") .. "/.local/src/HyprDots/tide-island call island randomWallpaper"
    )
)

--hyprpicker
hl.bind(mainMod .. " +SHIFT + C",hl.dsp.exec_cmd("hyprpicker -a"))

--hyprshot
hl.bind(mainMod .. " +SHIFT + S", hl.dsp.exec_cmd("hyprshot -z -m region"))
hl.bind("Print", hl.dsp.exec_cmd("hyprshot -z -m output"))
hl.bind(mainMod .. " +SHIFT + W", hl.dsp.exec_cmd("hyprshot -z -m window"))
hl.bind(mainMod .. " +SHIFT + O", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/ocr.sh"))
hl.bind(mainMod .. " +SHIFT + V", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/visual_search.sh"))
hl.bind(mainMod .. " +SHIFT + B", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/qr_barcode.sh"))
-- hl.bind(mainMod .. " +SHIFT + M", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/mirror.sh"))

--wf-Recorder
hl.bind(mainMod .. " + SHIFT+R", function()
    local status = os.execute("pgrep -x wf-recorder")
    local is_running = (status == 0 or status == true)
    if is_running then
        hl.exec_cmd(os.getenv("HOME") .. "/.local/src/HyprDots/tide-island/bin/record.sh")
    else
        hl.exec_cmd(os.getenv("HOME") .. "/.local/src/HyprDots/tide-island/bin/record.sh -r")
    end
end)





hl.bind(
    "SUPER + A",
    hl.dsp.exec_cmd(
        "qs ipc -p " .. os.getenv("HOME") .. "/.local/src/HyprDots/tide-island call island toggleControlCenter"
    )
)

-- -- btop
-- hl.bind("CTRL + SHIFT + code:9",
--     hl.dsp.exec_cmd("pgrep -x btop && pkill -x btop || kitty --title btop btop")
-- )

-- Lock screen
hl.bind("SUPER + L", hl.dsp.exec_cmd("~/.local/src/HyprDots/tide-island/lockscreen/lock.sh"))

-- Cheatsheet toggle
hl.bind(
    mainMod .. " + slash",
    hl.dsp.exec_cmd(
        "qs ipc -p " .. os.getenv("HOME") .. "/.local/src/HyprDots/tide-island call island toggleCheatsheet"
    )
)


-- LAYOUT SPECIFIC BINDS
hl.bind(mainMod .. " + equal", hl.dsp.layout("colresize +0.1"))
hl.bind(mainMod .. " + minus", hl.dsp.layout("colresize -0.1"))

hl.bind(mainMod .. " + bracketright", layout_bind({
    scrolling = hl.dsp.layout("consume_or_expel next"),
    dwindle   = hl.dsp.window.swap({ next = true }),
}))

hl.bind(mainMod .. " + bracketleft", layout_bind({
    scrolling = hl.dsp.layout("consume_or_expel prev"),
    dwindle   = hl.dsp.window.swap({ prev = true }),
}))

hl.bind(mainMod .. " + semicolon", layout_bind({
    scrolling = hl.dsp.layout("swapcol l"),
    dwindle   = hl.dsp.window.swap({ direction = "left" }),
}))

hl.bind(mainMod .. " + apostrophe", layout_bind({
    scrolling = hl.dsp.layout("swapcol r"),
    dwindle   = hl.dsp.window.swap({ direction = "right" }),
}))

-- Monitor width & column fit controls (Niri-style fit to width)
-- hl.bind(mainMod .. " + M", hl.dsp.layout("colresize 1.0"))             -- Fit active column to 100% monitor width (within gaps)
hl.bind(mainMod .. " + ALT + M", hl.dsp.window.fullscreen({ mode = "maximized" })) -- Fit active window to 100% monitor width, ignoring gaps
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.layout("fit expand"))        -- Expand column to fill available monitor space
hl.bind(mainMod .. " + R", layout_bind({
    scrolling = hl.dsp.layout("colresize +conf"),
    dwindle   = hl.dsp.layout("togglesplit"),
}))



--NIRI-LIKE_OVERVIEW
hl.bind("SUPER + TAB", function()
    hl.plugin.scrolloverview.overview("toggle")
end)

hl.bind("SUPER + mouse_up", layout_bind({
    scrolling = hl.dsp.layout("focus r"),
    default   = hl.dsp.focus({ direction = "right" }),
}))
hl.bind("SUPER + mouse_down", layout_bind({
    scrolling = hl.dsp.layout("focus l"),
    default   = hl.dsp.focus({ direction = "left" }),
}))



-- Cycle current workspace layout between scrolling <-> dwindle
hl.bind("SUPER + SHIFT + J", function()
    local workspace = hl.get_active_special_workspace() or hl.get_active_workspace()
    if not workspace then return end

    local layouts = { "scrolling", "dwindle" }
    local current_layout = workspace.tiled_layout or "dwindle"
    local next_layout = layouts[1]

    for i = 1, #layouts do
        if layouts[i] == current_layout then
            local next_idx = (i % #layouts) + 1
            next_layout = layouts[next_idx]
            break
        end
    end

    if workspace.special then
        hl.workspace_rule({ workspace = "special:" .. workspace.name, layout = next_layout })
    else
        hl.workspace_rule({ workspace = tostring(workspace.id), layout = next_layout })
    end

    hl.exec_scheduled_prop_refresh_immediately()
    hl.exec_cmd(string.format('qs ipc -p %s/.local/src/HyprDots/tide-island call island showLayoutToast "%s"', os.getenv("HOME"), next_layout))
end)