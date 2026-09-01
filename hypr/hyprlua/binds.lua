require("hyprlua.env")


local closeWindowBind = hl.bind(mainMod .. " + Q", hl.dsp.window.close())



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

--Change FOCUSED Window
hl.bind(mainMod .. "+ left", hl.dsp.focus({direction = "l"}))
hl.bind(mainMod .. "+ right", hl.dsp.focus({direction = "r"}))
hl.bind(mainMod .. "+ up", hl.dsp.focus({direction = "up"}))
hl.bind(mainMod .. "+ down", hl.dsp.focus({direction = "down"}))


-- move to next/previous workspace
-- 1. Using keyboard
hl.bind("SUPER + CTRL + left",  hl.dsp.focus({ workspace = "r-1" }))
hl.bind("SUPER + CTRL + right", hl.dsp.focus({ workspace = "r+1" }))

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
hl.bind(mainMod .. "+ A", hl.dsp.window.float())

--move window within a workspace
hl.bind(mainMod .. "+SHIFT + up",hl.dsp.window.move({direction = "up"}))
hl.bind(mainMod .. "+SHIFT + down",hl.dsp.window.move({direction = "down"}))
hl.bind(mainMod .. "+SHIFT + left",hl.dsp.window.move({direction = "left"}))
hl.bind(mainMod .. "+SHIFT + right",hl.dsp.window.move({direction = "right"}))




--application binds
-- hl.bind(mainMod .. " +ALT+E", hl.dsp.exec_cmd("kitty yazi"))
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal,{float = true,size= {713,433}}))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(filemanager))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd(code_editor))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(browser))


--special workspaces
hl.bind("SUPER + ALT + S", function ()
    hl.dispatch(hl.dsp.workspace.toggle_special("spotify_special"))
    hl.workspace_rule({ workspace = "special:spotify_special", on_created_empty = "spotify" })
end)

hl.bind("SUPER+ALT+D", function ()
    hl.dispatch(hl.dsp.workspace.toggle_special("discord_special"))
    hl.workspace_rule({workspace = "special:discord_special", on_created_empty = "vesktop"})
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







-- Lock screen
hl.bind("SUPER + L", hl.dsp.exec_cmd("~/.local/src/HyprDots/tide-island/lockscreen/lock.sh"))




--NIRI-LIKE_OVERVIEW
hl.bind("SUPER + TAB", function()
    hl.plugin.scrolloverview.overview("toggle")
end)



-- SCROLLING
hl.bind("SUPER + R", hl.dsp.layout("colresize +conf"))
hl.bind("SUPER + equal", hl.dsp.layout("colresize +0.1"))
hl.bind("SUPER + minus", hl.dsp.layout("colresize -0.1"))
hl.bind("SUPER+bracketright",hl.dsp.layout("swapcol r"))
hl.bind("SUPER+bracketleft",hl.dsp.layout("swapcol l"))
hl.bind("SUPER+I",hl.dsp.layout("fit visible"))
hl.bind("SUPER + SHIFT+ mouse_down", hl.dsp.focus({ direction = "r" }),{non_consuming = false})
hl.bind("SUPER + SHIFT+ mouse_up", hl.dsp.focus({ direction = "l" }),{non_consuming = false})


hl.bind("SUPER +SHIFT+ P", hl.dsp.layout("promote"))
hl.bind("SUPER + C",function ()
        hl.dispatch(hl.dsp.layout("center"))
end)


hl.bind("SUPER + ALT+Right",function ()
        hl.dispatch(hl.dsp.layout("move -200"))
end)
hl.bind("SUPER + ALT+Left",function ()
        hl.dispatch(hl.dsp.layout("move +200"))
end)




hl.bind("SUPER + SHIFT+F", function ()
    local win = hl.get_active_window()
    local columnsize = win.size.x
    if columnsize > 1800 then
        hl.dispatch(hl.dsp.layout("colresize 0.5"))

    else
        hl.dispatch(hl.dsp.layout("colresize 1"))
    end

end)

hl.bind("SUPER + F", function ()
    hl.dispatch(hl.dsp.window.fullscreen({mode = "fullscreen",layout_aware = true}))
end)