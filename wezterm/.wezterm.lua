local wezterm = require("wezterm")
local act = wezterm.action

-- This will hold the configuration.
local config = wezterm.config_builder()

-- GPU configuration
local gpus = wezterm.gui.enumerate_gpus()
config.webgpu_preferred_adapter = gpus[1]
config.max_fps = 120
config.animation_fps = 1
config.front_end = "OpenGL"
config.enable_wayland = false

-- Font ------------------------------------------------------
config.font = wezterm.font("JetBrainsMono Nerd Font")
config.cell_width = 0.9
config.window_background_opacity = 1.0
config.font_size = 18.0

-- Window Padding --------------------------------------------
config.window_padding = {
    left = 30,
    right = 30,
    top = 30,
    bottom = 20,
}

-- Remove all Tabs & all -------------------------------------
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false

-- Disable all pane controls since using tmux ----------------
config.disable_default_key_bindings = true
config.keys = {
    {
        key = "V",
        mods = "SUPER",
        action = wezterm.action.PasteFrom("Clipboard"),
    },
    -- Added zoom in shortcut (CMD +)
    {
        key = "=",
        mods = "SUPER",
        action = wezterm.action.IncreaseFontSize,
    },
    -- Added zoom out shortcut (CMD -)
    {
        key = "-",
        mods = "SUPER",
        action = wezterm.action.DecreaseFontSize,
    },
    -- Optional: Add reset zoom shortcut (CMD 0)
    {
        key = "0",
        mods = "SUPER",
        action = wezterm.action.ResetFontSize,
    },
}

-- Define themes --------------------------------------------
local themes = {
    gruvbox = {
        background = "#282828",
        foreground = "#ebdbb2",
        cursor_bg = "#ebdbb2",
        cursor_border = "#ebdbb2",
        cursor_fg = "#282828",
        selection_bg = "#504945",
        selection_fg = "#ebdbb2",
        ansi = {
            "#282828", -- black
            "#cc241d", -- red
            "#98971a", -- green
            "#d79921", -- yellow
            "#458588", -- blue
            "#b16286", -- magenta
            "#689d6a", -- cyan
            "#a89984", -- white
        },
        brights = {
            "#928374", -- bright black
            "#fb4934", -- bright red
            "#b8bb26", -- bright green
            "#fabd2f", -- bright yellow
            "#83a598", -- bright blue
            "#d3869b", -- bright magenta
            "#8ec07c", -- bright cyan
            "#ebdbb2", -- bright white
        },
        tab_bar = {
            background = "#282828",
            active_tab = {
                bg_color = "#282828",
                fg_color = "#ebdbb2",
                intensity = "Normal",
                underline = "None",
                italic = false,
                strikethrough = false,
            },
            inactive_tab = {
                bg_color = "#282828",
                fg_color = "#a89984",
                intensity = "Normal",
                underline = "None",
                italic = false,
                strikethrough = false,
            },
            new_tab = {
                bg_color = "#282828",
                fg_color = "#ebdbb2",
            },
        },
    },
}

-- Set initial color scheme and colors
config.colors = themes.gruvbox

config.window_frame = {
    font = wezterm.font({ family = "Iosevka Custom", weight = "Regular" }),
    active_titlebar_bg = "#0c0b0f",
}

config.window_decorations = "NONE | RESIZE"
config.initial_cols = 80
config.window_background_image = "/Users/guillaumethibault/Documents/Wallpaper/background.jpeg"
config.window_background_image_hsb = {
    brightness = 0.01,
}

config.audible_bell = "Disabled"

return config
