#!/bin/bash
export NEWT_COLORS_FILE="${NEWT_COLORS_FILE:-$HOME/.config/nmtui/palette}"
exec nmtui "$@"
