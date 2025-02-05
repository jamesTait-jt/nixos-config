local wezterm = require("wezterm")
local constants = require("constants")
local config = wezterm.config_builder()

config = {
    send_composed_key_when_left_alt_is_pressed = false,
	automatically_reload_config = true,
	enable_tab_bar = false,
	window_close_confirmation = "NeverPrompt",
	window_decorations = "RESIZE", -- disable the title bar but enable the resizable border
	color_scheme = "Everforest Dark Hard (Gogh)",
	font = wezterm.font("JetBrains Mono"), --, { weight = "Bold" }),
	font_size = 11,
	window_background_image = constants.bg_image,
	background = {
		{
			source = {
				Color = "#232A2E",
			},
			width = "100%",
			height = "100%",
			opacity = 0.9
		},
	},
}

return config
