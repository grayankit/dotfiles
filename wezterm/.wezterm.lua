local wezterm = require("wezterm")

return {
	font = wezterm.font("FiraCode Nerd Font"),
	font_size = 12.0,

	enable_tab_bar = false,
	term = "xterm-256color",

	color_scheme_dirs = { wezterm.home_dir .. "/.config/wezterm/colors" },
	color_scheme = "wallust",

	window_background_opacity = 0.85,
	text_background_opacity = 1.0,

	window_padding = {
		left = 4,
		right = 4,
		top = 2,
		bottom = 2,
	},
	enable_kitty_graphics = true,
}
