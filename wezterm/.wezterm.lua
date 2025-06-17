local wezterm = require("wezterm")

return {
	font = wezterm.font("FiraCode Nerd Font"),
	font_size = 12.0,

	-- Tmux and Neovim friendly
	enable_tab_bar = false,
	term = "xterm-256color",

	-- Appearance
	--	color_scheme = "Catppuccin Mocha",
	window_background_opacity = 0.85,
	text_background_opacity = 1.0,

	-- Optional blur (works via Hyprland or Picom)
	window_background_gradient = {
		orientation = "Vertical",
		colors = { "#111111", "#11111b" },
	},

	-- Padding for a cleaner look
	window_padding = {
		left = 4,
		right = 4,
		top = 2,
		bottom = 2,
	},
}
