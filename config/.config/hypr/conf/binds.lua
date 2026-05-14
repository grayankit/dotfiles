local mainMod = "SUPER"
local SUPER_SHIFT = "SUPER + SHIFT"

-- Actions
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("wezterm"))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("pwvucontrol"))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("~/.config/ml4w/settings/filemanager.sh"))
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mainMod .. " + CTRL + RETURN", hl.dsp.exec_cmd("/home/narayan/.config/rofi/launchers/type-6/launcher.sh"))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("~/.config/ml4w/settings/browser.sh"))
hl.bind(SUPER_SHIFT .. " + B", hl.dsp.exec_cmd("~/.config/ml4w/scripts/reload-waybar.sh"))
hl.bind(mainMod .. " + F1", hl.dsp.exec_cmd("~/.config/scripts/gamemode.sh"))
hl.bind(SUPER_SHIFT .. " + W", hl.dsp.exec_cmd("~/.config/ml4w/scripts/reload-hyprpaper.sh"))

hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-"),
	{ repeating = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("$HOME/.config/scripts/brightness-notify.sh up"), { repeating = true })
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("$HOME/.config/scripts/brightness-notify.sh down"),
	{ repeating = true }
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

-- Move focus
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

-- Workspaces
for i = 1, 10 do
	local key = i % 10
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(SUPER_SHIFT .. " + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scroll workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- More execs
hl.bind(
	SUPER_SHIFT .. " + V",
	hl.dsp.exec_cmd(
		"cliphist list | rofi -dmenu -theme $HOME/.config/rofi/launchers/type-1/style-2.rasi | cliphist decode | wl-copy"
	)
)
hl.bind(SUPER_SHIFT .. " + R", hl.dsp.exec_cmd("$HOME/.config/scripts/refresh-rate.sh"))

--ScreenShots Binds
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot -m window"))
hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot -m output"))
hl.bind("SHIFT + PRINT", hl.dsp.exec_cmd("hyprshot -m region"))

hl.bind(SUPER_SHIFT .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(SUPER_SHIFT .. " + S", hl.dsp.exec_cmd("spotify"))

--Screen Recording
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("~/.config/scripts/wf-recorder.sh"))
