#!/bin/bash

case "${1:-}" in
	reload)
		killall -9 waybar
		sleep 1
		waybar &
		;;
	toggle)
		if pgrep -x waybar > /dev/null; then
			killall -q waybar
			while pgrep -x waybar > /dev/null; do sleep 0.1; done
		else
			waybar &
		fi
		;;
	*)
		echo "Usage: $0 {reload|toggle}"
		exit 1
		;;
esac
