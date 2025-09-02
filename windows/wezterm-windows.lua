local wezterm = require("wezterm")
local act = wezterm.action

-- This will hold the configuration.
local config = wezterm.config_builder()

-- GPU configuration
local gpus = wezterm.gui.enumerate_gpus()
config.webgpu_preferred_adapter = gpus[1] -- Select the dedicated GPU
config.front_end = "WebGpu"               -- Try WebGPU first
config.prefer_egl = true                  -- Enable EGL support
config.max_fps = 144                      -- Good match for most gaming monitors
config.animation_fps = 1                  -- Reduce unnecessary animations

-- Launch env selector on startup
config.default_prog = {
    "powershell",
    "-Command",
    "& {PowerShell -ExecutionPolicy Bypass -File C:\\Users\\Dream\\wsl-selector.ps1}"
}

-- Font ------------------------------------------------------
config.font = wezterm.font("JetBrains Mono Regular")
config.cell_width = 0.9
config.window_background_opacity = 0.9
config.font_size = 15.0

-- Window Padding --------------------------------------------
config.window_padding = {
    left = 50,
    right = 50,
    top = 50,
    bottom = 30,
}

-- Remove all Tabs & all -------------------------------------
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false

-- Disable all pane controls since using tmux ----------------
config.disable_default_key_bindings = true
config.keys = {
    {
        key = "E",
        mods = "CTRL|SHIFT|ALT",
        action = wezterm.action.EmitEvent("toggle-colorscheme"),
    },
    {
        key = "O",
        mods = "CTRL|ALT",
        -- toggling opacity
        action = wezterm.action_callback(function(window, _)
            local overrides = window:get_config_overrides() or {}
            if overrides.window_background_opacity == 1.0 then
                overrides.window_background_opacity = 0.9
            else
                overrides.window_background_opacity = 1.0
            end
            window:set_config_overrides(overrides)
        end),
    },
    {
        key = "V",
        mods = "CTRL|SHIFT",
        action = wezterm.action.PasteFrom("Clipboard"),
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

    cloud = {
        background = "#0c0b0f",
        foreground = "#f8f2f5",
        cursor_border = "#bea3c7",
        cursor_bg = "#bea3c7",
        selection_bg = "#bea3c7",
        selection_fg = "#0c0b0f",
        ansi = {
            "#222222", -- black
            "#e33c3a", -- red
            "#69c62c", -- green
            "#c2c33d", -- yellow
            "#4584d2", -- blue
            "#d160c4", -- magenta
            "#21c4c4", -- cyan
            "#d0d0d0", -- white
        },
        brights = {
            "#666666", -- bright black
            "#e33c3a", -- bright red
            "#69c62c", -- bright green
            "#c2c33d", -- bright yellow
            "#4584d2", -- bright blue
            "#d160c4", -- bright magenta
            "#21c4c4", -- bright cyan
            "#ffffff", -- bright white
        },
        tab_bar = {
            background = "#0c0b0f",
            active_tab = {
                bg_color = "#0c0b0f",
                fg_color = "#bea3c7",
                intensity = "Normal",
                underline = "None",
                italic = false,
                strikethrough = false,
            },
            inactive_tab = {
                bg_color = "#0c0b0f",
                fg_color = "#f8f2f5",
                intensity = "Normal",
                underline = "None",
                italic = false,
                strikethrough = false,
            },
            new_tab = {
                bg_color = "#0c0b0f",
                fg_color = "white",
            },
        },
    }
}

-- color scheme toggling -------------------------------------
wezterm.on("toggle-colorscheme", function(window, pane)
    local overrides = window:get_config_overrides() or {}
    if not overrides.colors or overrides.colors == themes.cloud then
        overrides.colors = themes.gruvbox
        overrides.window_frame = {
            active_titlebar_bg = "#282828",
        }
    else
        overrides.colors = themes.cloud
        overrides.window_frame = {
            active_titlebar_bg = "#0c0b0f",
        }
    end
    window:set_config_overrides(overrides)
end)

-- Set initial color scheme and colors
config.colors = themes.gruvbox -- Starting with Cloud theme

config.window_frame = {
    font = wezterm.font({ family = "Iosevka Custom", weight = "Regular" }),
    active_titlebar_bg = "#0c0b0f",
}

config.window_decorations = "NONE | RESIZE"
config.initial_cols = 80
config.window_background_image = "C:\\Users\\Dream\\Documents\\Wallpaper\\GKfktRsaIAAdh6Y.jpeg"
config.window_background_image_hsb = {
    brightness = 0.01,
}

config.audible_bell = "Disabled"

return config
