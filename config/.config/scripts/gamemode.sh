#!/usr/bin/env sh
HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')
if [ "$HYPRGAMEMODE" = "true" ] || [ "$HYPRGAMEMODE" = "1" ] ; then
    hyprctl eval "hl.config({
        animations = { enabled = false },
        decoration = {
            blur = { enabled = false },
            shadow = { enabled = false },
            active_opacity = 1.0,
            inactive_opacity = 1.0
        }
    })"
    exit
fi
hyprctl reload
