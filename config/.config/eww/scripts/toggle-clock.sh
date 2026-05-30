#!/bin/bash
if eww active-windows 2>/dev/null | grep -q "^clock:"; then
	eww close clock
else
	eww open clock
fi
