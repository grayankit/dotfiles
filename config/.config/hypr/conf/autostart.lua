hl.on("hyprland.start", function()
	-- Export the session environment to systemd so the user manager can
	-- start graphical-session.target, then start our session target.
	-- dms is pulled in by the inline Wants= in hyprland-session.target
	-- (NOT a .wants/ dir: systemd ignores symlinked .wants/ dirs, and
	--  Before=graphical-session.target would create an ordering cycle).
	hl.exec_cmd("dbus-update-activation-environment --systemd --all")
	hl.exec_cmd("systemctl --user start hyprland-session.target")

	-- Clipboard: kept (DMS clipboard uses cliphist as its store)
	hl.exec_cmd("clipse -listen")
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")

	-- Removed: waybar, awww-daemon, dunst, hypridle, polkit-kde-agent-1
	-- All replaced by DankMaterialShell (started by hyprland-session.target).
end)
