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
config.font_size = 21.0

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
        mods = "CTRL|SHIFT",
        action = wezterm.action.PasteFrom("Clipboard"),
    },
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
local theme = require 'theme'
config.colors = theme

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
