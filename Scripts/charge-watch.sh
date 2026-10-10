#!/usr/bin/env bash
# Live battery charge rate monitor. Usage: ./charge-watch.sh [interval_seconds]
interval="${1:-3}"
bat=/sys/class/power_supply/BAT0

while true; do
  status=$(<"$bat/status")
  cap=$(<"$bat/capacity")
  v=$(<"$bat/voltage_now")
  i=$(<"$bat/current_now")
  now=$(<"$bat/charge_now")
  full=$(<"$bat/charge_full")
  temp=$(<"$bat/temp")
  awk -v t="$(date +%H:%M:%S)" -v s="$status" -v c="$cap" -v v="$v" -v i="$i" -v n="$now" -v f="$full" -v tp="$temp" 'BEGIN {
    w = v * i / 1e12
    eta = (s == "Charging" && i > 0) ? (f - n) / i * 60 : -1
    if (eta >= 0) e = sprintf("%d min", eta); else e = "-"
    printf "%s  %-11s %3d%%  %.3f A  %.2f V  %.1f W  %.1f C  ETA %s\n", t, s, c, i / 1e6, v / 1e6, w, tp / 10, e
  }'
  sleep "$interval"
done
