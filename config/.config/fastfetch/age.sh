#!/bin/sh
# Age of this install, from the root filesystem birth time.
# Falls back to the first pacman log line when birth time is unavailable.
set -eu

birth=$(stat -c %W / 2>/dev/null || echo 0)
if [ "$birth" -le 0 ] && [ -r /var/log/pacman.log ]; then
  stamp=$(head -1 /var/log/pacman.log | cut -d']' -f1 | tr -d '[')
  birth=$(date -d "$stamp" +%s 2>/dev/null || echo 0)
fi
[ "$birth" -gt 0 ] || exit 1

by=$(date -d "@$birth" +%Y)
bm=$(date -d "@$birth" +%-m)
bd=$(date -d "@$birth" +%-d)
ny=$(date +%Y)
nm=$(date +%-m)
nd=$(date +%-d)

years=$((ny - by))
months=$((nm - bm))
days=$((nd - bd))

if [ "$days" -lt 0 ]; then
  months=$((months - 1))
  days=$((days + $(date -d "$ny-$nm-01 -1 day" +%-d)))
fi
if [ "$months" -lt 0 ]; then
  years=$((years - 1))
  months=$((months + 12))
fi

piece() {
  n=$1
  word=$2
  if [ "$n" -eq 0 ]; then
    return 0
  elif [ "$n" -eq 1 ]; then
    printf '%s %s' "$n" "$word"
  else
    printf '%s %ss' "$n" "$word"
  fi
}

out=
for spec in "$years year" "$months month" "$days day"; do
  n=${spec%% *}
  word=${spec#* }
  bit=$(piece "$n" "$word")
  [ -n "$bit" ] || continue
  if [ -n "$out" ]; then
    out="$out, $bit"
  else
    out=$bit
  fi
done

printf '%s\n' "${out:-0 days}"
