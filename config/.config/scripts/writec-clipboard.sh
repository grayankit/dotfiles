#!/usr/bin/env bash
# Type clipboard as keystrokes (like writec; quotes/special chars preserved).
sleep 0.1
wl-paste --no-newline --type text 2>/dev/null \
  | xdotool type --clearmodifiers --file -
