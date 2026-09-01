

-- UNBINDS
-------------------------------------------------------------------------

hl.unbind("SUPER + R")
hl.unbind("SUPER + ALT+E")
hl.unbind("SUPER + P")
hl.unbind("SUPER + Tab")
hl.unbind("SUPER + F")


-- UNBINDS
-------------------------------------------------------------------------




-- CONFIG 
-------------------------------------------------------------------------

hl.config({

    dwindle = {
        special_scale_factor = 0.9
    },
    scrolling = {
        direction = "right",
        focus_fit_method = 1,
        follow_min_visible = 1,
        explicit_column_widths = "0.333, 0.5, 0.667, 1.0",
        fullscreen_on_one_column = true,
        wrap_focus = false,
        wrap_swapcol = false,
    },

    binds = {
        scroll_event_delay = 0
    },
    plugin = {
        scrolloverview = {
            gesture_distance = 300, -- how far is the "max" for the gesture
            scale = 0.5, -- preferred overview scale
            workspace_gap = 100,
            layout = "vertical", -- vertical or horizontal
            wallpaper = 0, -- 0: global only, 1: per-workspace only, 2: both
            blur = true, -- blur only the main overview wallpaper

            shadow = {
                enabled = true,
                range = 50,
            },
        },
    },
    decoration = {
        motion_blur = {
            enabled = true
        }
    },
  }
  )

  -- CONFIG 
-------------------------------------------------------------------------









-- ######   BINDS AND GESTURES 
-------------------------------------------------------------------------



-- SPECIAL WORKSPACES
-------------------------------------------------------------------------


hl.bind("SUPER+ALT+D", function ()
    hl.dispatch(hl.dsp.workspace.toggle_special("discord_special"))
    hl.workspace_rule({workspace = "special:discord_special", on_created_empty = "vesktop"})
    hl.window_rule({match ={workspace = "special:discord_special"},float = false})
end)

hl.bind("SUPER+ALT+E", function ()
    hl.dispatch(hl.dsp.workspace.toggle_special("yazi_special"))
    hl.workspace_rule({workspace = "special:yazi_special", on_created_empty = "kitty yazi",})
    hl.window_rule({match ={workspace = "special:yazi_special"},float = false})
end)

hl.bind("SUPER+ALT+RETURN", function ()
    local mon = hl.get_active_monitor()
    local left = math.floor(math.ceil(mon.width / mon.scale or 1) * 0.5)
    hl.dispatch(hl.dsp.workspace.toggle_special("terminal_special"))
    hl.workspace_rule({workspace = "special:terminal_special", on_created_empty = "kitty",layout = "dwindle",gaps_out = { left = left, right = 0, top = 0, bottom = 0 },})
end)

 
hl.bind("SUPER + ALT + S", function ()
    hl.dispatch(hl.dsp.workspace.toggle_special("spotify_special"))
    hl.workspace_rule({ workspace = "special:spotify_special", on_created_empty = "spotify" })
    hl.window_rule({match ={workspace = "special:spotify_special"},float = false})
end)



-- SPECIAL WORKSPACES
-------------------------------------------------------------------------





--- MOUSE 
-------------------------------------------------------------------------
hl.bind("SUPER + Z", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + X",hl.dsp.window.resize(), {mouse = true})
hl.bind("SUPER + SHIFT+ mouse_down", hl.dsp.focus({ direction = "r" }),{non_consuming = false})
hl.bind("SUPER + SHIFT+ mouse_up", hl.dsp.focus({ direction = "l" }),{non_consuming = false})
--- MOUSE 
------------------------------------------------------------------------- 
--  GESTURES 
 -------------------------------------------------------------------------
hl.gesture({ fingers = 4, direction = "down", action = function() hl.dispatch(hl.dsp.focus({ workspace = "r-1" })) end })
hl.gesture({ fingers = 4, direction = "up", action = function() hl.dispatch(hl.dsp.focus({ workspace = "r+1" })) end })

hl.gesture({ fingers = 3, direction = "swipe", action = "scroll_move" })

--  GESTURES 
 -------------------------------------------------------------------------




hl.bind("SUPER + T", hl.dsp.exec_cmd("kitty",{float = true,size= {713,433}}))

--  SCROLLING LAYOUT 
-------------------------------------------------------------------------


hl.bind("SUPER + R", hl.dsp.layout("colresize +conf"))
hl.bind("SUPER + equal", hl.dsp.layout("colresize +0.1"))
hl.bind("SUPER + minus", hl.dsp.layout("colresize -0.1"))
hl.bind("SUPER+bracketright",hl.dsp.layout("swapcol r"))
hl.bind("SUPER+bracketleft",hl.dsp.layout("swapcol l"))
hl.bind("SUPER+I",hl.dsp.layout("fit visible"))

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

hl.bind("SUPER +SHIFT+ P", hl.dsp.layout("promote"))
hl.bind("SUPER + C",function ()
        hl.dispatch(hl.dsp.layout("center"))
end)

--  SCROLLING LAYOUT 
-------------------------------------------------------------------------

hl.bind("SUPER + P", hl.dsp.window.pseudo())



hl.bind("SUPER + TAB", function()
    hl.plugin.scrolloverview.overview("toggle all")
end)











-- ####### BINDS AND GESTURES 
------------------------------------------------------------------------- 


hl.bind("SUPER + ALT+Right",function ()
        hl.dispatch(hl.dsp.layout("move -200"))
end)
hl.bind("SUPER + ALT+Left",function ()
        hl.dispatch(hl.dsp.layout("move +200"))
end)
