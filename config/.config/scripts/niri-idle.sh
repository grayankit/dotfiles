#!/usr/bin/env sh
# Idle stack for niri only (Hyprland keeps hypridle/hyprlock).

lock_cmd='pidof swaylock >/dev/null || swaylock'
dpms_off='niri msg action power-off-monitors'

exec swayidle -w \
    timeout 150 'brightnessctl -s set 10' resume 'brightnessctl -r' \
    timeout 150 'brightnessctl -sd rgb:kbd_backlight set 0' resume 'brightnessctl -rd rgb:kbd_backlight' \
    timeout 300 "$lock_cmd" \
    timeout 330 "$dpms_off" resume 'brightnessctl -r' \
    timeout 600 'systemctl suspend' \
    before-sleep "$lock_cmd"
