-- Laptop panel (CMN N156HRA-EA1, ~95-99% sRGB, 8 bpc).
-- The ICC profile below is derived from this panel's own EDID; Hyprland
-- forces piecewise-sRGB EOTF and overrides the CM preset when icc is set,
-- so the compositor compensates for this panel's sub-sRGB primaries.
-- Fallback if the ICC path ever breaks: cm = "srgb", sdr_eotf = "srgb".
hl.monitor({
	output = "eDP-1",
	mode = "1920x1080@144",
	position = "0x0",
	scale = 1,
	icc = "/home/narayan/.local/share/icc/edid-e2e99a28c31cb2e9702fb801d69358e9.icc",
})

-- External panel (wide-gamut, 10-bit capable per its HDMI vendor block,
-- but a stub/invalid EDID so no usable ICC can be derived for it).
-- Pin CM + EOTF explicitly so both outputs render sRGB content identically.
hl.monitor({
	output = "DP-1",
	mode = "1920x1080@60.00000",
	position = "1920x0",
	scale = 1,
	bitdepth = 10,
	cm = "srgb",
	sdr_eotf = "srgb",
})

-- Note: HDMI-A-1 deliberately has no rule here. Its connector currently has
-- no EDID, and giving it the same position as DP-1 (1920x0) would overlap
-- outputs if a display is ever plugged in. Let Hyprland auto-place it.
