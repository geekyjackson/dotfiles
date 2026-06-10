-- This is an example Hyprland Lua config file.
-- Refer to the wiki for more information.
-- https://wiki.hypr.land/Configuring/Start/

-- Please note not all available settings / options are set here.
-- For a full list, see the wiki

-- You can (and should!!) split this configuration into multiple files
-- Create your files separately and then require them like this:
-- require("myColors")


------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})
hl.monitor({
    output   = "eDP-1",
    mode     = "3000x2000@60.00Hz",
    position = "0x0",
    scale    = 2,
    vrr      = 3,
})
hl.monitor({
    output   = "DP-3",
    mode     = "3840x2160@120",
    position = "0x1080",
    scale    = 2,
    vrr      = 3,
})
hl.monitor({
    output   = "DP-4",
    mode     = "preferred",
    position = "1920x530",
    scale    = 2,
    transform = 3,
})
hl.monitor({
    output   = "DP-5",
    mode     = "preferred",
    position = "0x0",
    scale    = 2,
})


---------------------
---- MY PROGRAMS ----
---------------------

local terminal = "kitty"
-- local menu = "hyprlauncher"
local menu = "wofi --show drun"
local browser = "firefox"


-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
-- Autostart necessary processes (notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:

hl.on("hyprland.start", function () 
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("waybar")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("udiskie")
    hl.exec_cmd("strawberry")
    hl.exec_cmd("~/.config/hypr/bin/volume-notify-daemon")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme \"Adwaita-dark\"")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme \"prefer-dark\"")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("GDK_SCALE", "2")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
--- hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("GTK_THEME", "Adwaita:dark")


-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart and are not 
-- applied on-the-fly for security reasons

-- hl.config({
--   ecosystem = {
--     enforce_permissions = true,
--   },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        border_size = 1,
        gaps_in  = 4,
        gaps_out = 8,
        col = {
            inactive_border = "rgba(a89984ff)",
            active_border = "rgba(fbf1c7ff)",
        },
        layout = "dwindle",
    },

    decoration = {
        rounding       = 5,
        rounding_power = 10,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled = false,
        },
        blur = {
            enabled   = true,
            size      = 3,
            passes    = 1,
            vibrancy  = 0.1696,
        },
    },
    
    animations = {
        enabled = false,
    },

    binds = {
        scroll_event_delay = 10,
    },

    xwayland = {
        force_zero_scaling = true,
    },

    cursor = {
        no_hardware_cursors = true,
        zoom_disable_aa = true,
    }
})


-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
hl.workspace_rule({
    workspace = "f[1]",
    gaps_out = 0,
    gaps_in = 0,
})
hl.window_rule({
    name  = "no-gaps-f1",
    match = {
        float = false, 
        workspace = "f[1]", 
    },
    border_size = 0,
    rounding    = 0,
})

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
    dwindle = {
        force_split = 2,
        preserve_split = true,
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
    master = {
        new_status = "master",
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
    },
})

----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
        background_color = "#1d2021",
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
    },
})

----------------
---- LAYOUT ----
----------------

local state = {
    -- Stored bottom-to-top.
    -- First spawned window stays at index 1, newer windows are appended.
    order = {},
}

local function target_id(target)
    local window = target.window
    return window and tostring(window.stable_id) or tostring(target.index)
end

local function index_of(tbl, value)
    for i, v in ipairs(tbl) do
        if v == value then
            return i
        end
    end
end

local function sync_order(ctx)
    local present = {}
    local targets = {}

    for _, target in ipairs(ctx.targets) do
        local id = target_id(target)
        present[id] = true
        targets[id] = target
    end

    -- Keep existing windows in their original spawn order.
    local old_order = state.order
    state.order = {}

    for _, id in ipairs(old_order) do
        if present[id] then
            table.insert(state.order, id)
        end
    end

    -- Append newly seen windows.
    -- Since state.order is bottom-to-top, new windows go to the top.
    for _, target in ipairs(ctx.targets) do
        local id = target_id(target)
        if not index_of(state.order, id) then
            table.insert(state.order, id)
        end
    end

    return targets
end

local function place_bottom_to_top(ctx, targets)
    local n = #state.order

    if n == 0 then
        return
    end

    if n == 1 then
        local target = targets[state.order[1]]
        if target then
            target:place(ctx.area)
        end
        return
    end

    if n == 2 then
        local bottom = targets[state.order[1]]
        local top = targets[state.order[2]]

        if top then
            top:place(ctx:split(ctx.area, "top", 1 / 3))
        end

        if bottom then
            bottom:place(ctx:split(ctx.area, "bottom", 2 / 3))
        end

        return
    end

    for i, id in ipairs(state.order) do
        local target = targets[id]
        if target then
            -- state.order is bottom-to-top, but ctx:row(1, n) is top row.
            -- So bottom item gets row n, newest/top item gets row 1.
            local row = n - i + 1
            target:place(ctx:row(row, n))
        end
    end
end

hl.layout.register("bottom_stack", {
    recalculate = function(ctx)
        local targets = sync_order(ctx)
        place_bottom_to_top(ctx, targets)
    end,
})

hl.workspace_rule({ workspace = "10", layout = "lua:bottom_stack" })


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0,

        touchpad = {
            natural_scroll = false,
        },
    },
})

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})


---------------------
---- KEYBINDINGS ----
---------------------

-- see https://wiki.hypr.land/Configuring/Basics/Binds/ for more

local mainMod = "SUPER"

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd(browser))

-- hl.bind(mainMod .. " + CTRL + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + CTRL + L", function()
    hl.dispatch(hl.dsp.exec_cmd(
        "pidof hyprlock || hyprlock --immediate-render --no-fade-in"
    ))
    hl.timer(
        function()
            hl.dispatch(hl.dsp.dpms({ action = "disable" }))
        end, 
        {timeout = 500, type = "oneshot"}
    )
end)

-- Screenshots
hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot -o ~/Pictures/screenshots -m region"))
hl.bind("SUPER + PRINT", hl.dsp.exec_cmd("hyprshot -o ~/Pictures/screenshots -m window"))
hl.bind("SUPER + SHIFT + PRINT", hl.dsp.exec_cmd("hyprshot -o ~/Pictures/screenshots -m output"))

-- Windows
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + CTRL + C", hl.dsp.window.kill())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + CTRL + F", hl.dsp.window.float({ action = "toggle" }))

hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))    -- dwindle only

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + W", hl.dsp.workspace.swap_monitors({ monitor1 = "DP-3", monitor2 = "DP-5" }))

-- Example special workspace (scratchpad)
-- hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

hl.workspace_rule({
  workspace = "special:kitty",
  on_created_empty = "kitty --class kitty-special --title kitty-special"
})

hl.window_rule({
  name = "kitty-special-scratchpad",
  match = { initial_class = "^kitty-special$" },
  workspace = "special:kitty silent",
  size = {1400, 842},
  float = true,
  center = true,
})

-- Any non-scratchpad window opened while special:kitty is active
-- gets moved back to the previous normal workspace.
hl.window_rule({
  name = "keep-launched-apps-out-of-kitty-special",
  match = {
    workspace = "special:kitty",
    initial_class = "negative:^kitty-special$",
  },
  workspace = "m+0 silent",
})

hl.bind(
  mainMod .. " + S",
  hl.dsp.workspace.toggle_special("kitty"),
  { description = "Toggle kitty scratchpad" }
)



-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(mainMod .. " + SHIFT + mouse:272", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind(
    "XF86AudioRaiseVolume", 
    hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 4%+"),
    { locked = true, repeating = true }
)
hl.bind(
    "XF86AudioLowerVolume", 
    hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 4%-"),
    { locked = true, repeating = true }
)
hl.bind(
    "XF86AudioMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
    { locked = true, repeating = true }
)
hl.bind(
    "XF86AudioMicMute", 
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
    { locked = true, repeating = true }
)
hl.bind(
    "XF86MonBrightnessUp",
    hl.dsp.exec_cmd([[
        b=$(brightnessctl -m -e4 -n6 set 5%+ | cut -d',' -f4 | sed 's/%$//')
        b=$(( ($b - 35) * 100 / 65 ))
        dunstify \
            -a "brightness" \
            -h "string:x-dunst-stack-tag:brightness" \
            -h "int:value:$b" \
            -t 1000 \
            "Brightness" "${b}%"
    ]]),
    { locked = true, repeating = true }
)
hl.bind(
    "XF86MonBrightnessDown",
    hl.dsp.exec_cmd([[
        b=$(brightnessctl -m -e4 -n6 set 5%- | cut -d',' -f4 | sed 's/%$//')
        b=$(( ($b - 35) * 100 / 65 ))
        dunstify \
            -a "brightness" \
            -h "string:x-dunst-stack-tag:brightness" \
            -h "int:value:$b" \
            -t 1000 \
            "Brightness" "${b}%"
    ]]),
    { locked = true, repeating = true }
)

-- Requires playerctl, mpv-mpris
local play_pause = [[
    if playerctl --all-players status 2>/dev/null | grep -q "Playing"; then 
        playerctl --all-players pause; 
    else 
        playerctl play; 
    fi
]]
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd(play_pause), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd(play_pause), { locked = true })


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

-- Ignore maximize requests from all apps.
local suppressMaximizeRule = hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})

hl.workspace_rule({
    workspace = "10",
    monitor = "DP-4",
    default = true,
    persistent = true
})

hl.window_rule({
    match = { class = "^nm-connection-editor$" },
    float = true,
})

hl.window_rule({
    match = { class = "^blueman-manager$" },
    float = true,
})

hl.window_rule({
    match = { class = "^org.pulseaudio.pavucontrol$" },
    float = true,
})

hl.window_rule({
    match = { class = "^org.strawberrymusicplayer.strawberry$" },
    monitor = "DP-4",
})

hl.window_rule({
    match = { title = "^Yazi file picker$" },
    size = {1202, 720},
    float = true,
    center = true,
})

