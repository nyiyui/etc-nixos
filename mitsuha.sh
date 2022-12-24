#!/usr/bin/env bash
# Created by marco, Di 5. Jan 20:11:25 CET 2016.

set -ux

GOVERNOR_NOCHARGE=powersave # CPU governor when not charging
GOVERNOR_CHARGE=performance # CPU governor when charging
recur=6 # Set governor after x seconds just in case it didn't correctly set or get set by another program; comment "let ticks--" line in function main to disable
 
# Don't change values below this text
ticks=$recur
laststate=1337
state=

CPUPOWER=cpupower
 
function die {
  echo "$@"
  exit 1
}
 
function checkACPluggedIn {
  cat /sys/class/power_supply/AC/online
}
 
function onSwitchState {
  echo
  ticks=$recur
  if [ $state -eq 0 ]; then
    $CPUPOWER frequency-set -g $GOVERNOR_NOCHARGE
    echo "Switched to governor $GOVERNOR_NOCHARGE"
  fi
  if [ $state -eq 1 ]; then
    $CPUPOWER frequency-set -g $GOVERNOR_CHARGE
    echo "Switched to governor $GOVERNOR_CHARGE"
  fi
}
 
function main {
  while true; do
    state="$(checkACPluggedIn)"
    if [ $state -lt 0 ]; then
      die "An unexpected error occurred. Does this computer have a battery?"
    fi
    if [ ! $state -eq $laststate ]; then
      onSwitchState
    fi
    laststate="$state"
    let ticks--
    if [ $ticks -lt 1 ]; then
      onSwitchState
    fi
    sleep 10
  done
}
 
main
exit $?
