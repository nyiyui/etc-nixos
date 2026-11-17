#!/usr/bin/env fish
#
# auto-brightness - drive the display backlight from the ambient light sensor.
#
# All backlight access goes through brightnessctl, which already handles device
# selection, the percentage conversion, a minimum value of 1 so the panel never
# blanks, and falling back to logind when sysfs is not writable by this user.
#
#   auto-brightness              run continuously (the systemd user service)
#   auto-brightness --once -v    check the calibration for the current room
#   auto-brightness --status     show the sensor reading and current target
#
# To take manual control, stop the service; it stays stopped until restarted,
# so there is no override tracking here:
#
#   systemctl --user stop auto-brightness      # hold
#   systemctl --user restart auto-brightness   # release

# === Calibration =============================================================
# Ambient light sensor reading (in_illuminance_raw) -> backlight percentage.
# Both lists must be the same length and CAL_RAW must be ascending.
# Readings between two points are interpolated linearly; readings outside the
# table clamp to the first/last percentage.
set -g CAL_RAW 3 10 190 452 3355
set -g CAL_PCT 5 10 10 22 100

# === Tunables ================================================================
# INTERVAL and SMOOTHING are coupled: the EMA weights samples, not seconds, so
# raising INTERVAL without raising SMOOTHING multiplies the settling time. At
# INTERVAL 10 / SMOOTHING 0.6 a lighting change is 60% applied after one sample
# and 94% after three, i.e. ~30s - and 10s of that is just waiting to be
# sampled at all. SMOOTHING 1 disables averaging and leaves only DEADBAND.
set -g INTERVAL 10 # seconds between sensor samples
set -g SMOOTHING 0.6 # EMA weight of each new sample; lower = steadier, laggier
set -g DEADBAND 4 # ignore target changes smaller than this many percentage points
set -g RAMP_STEPS 40 # steps used to fade to a new brightness (1 = jump)
set -g RAMP_DELAY 0.025 # seconds between fade steps, so a fade takes ~1s
set -g MIN_PCT 1 # never go darker than this, whatever the table says

set -g BCTL brightnessctl
set -g SENSOR /sys/bus/iio/devices/iio:device0/in_illuminance_raw
# -c backlight is not just device selection: without a class brightnessctl
# scans both "backlight" and "leds", and reading ceka's chromeos:* LEDs emits
# "End-of-file reading brightness of device ..." on every single call.
set -g BCTL_ARGS -m -c backlight # plus -d NAME once --device is parsed
set -g ONCE false
set -g VERBOSE false

set -g BL_MAX ""

# === Helpers =================================================================

function log
    echo "auto-brightness: $argv" >&2
end

function vlog
    test "$VERBOSE" = true; and log $argv
end

# Read the first line of a file. Fails if unreadable or empty.
function read_attr --argument-names path
    test -r "$path"; or return 1
    read -l value <"$path"; or return 1
    test -n "$value"; or return 1
    echo $value
end

function usage
    echo "usage: auto-brightness [options]

  --once               adjust once and exit
  --status             print the sensor reading and target, then exit
  --verbose, -v        log each sample and decision
  --interval SECONDS   seconds between samples (default $INTERVAL)
  --sensor PATH        illuminance attribute (default $SENSOR)
  --device NAME        brightnessctl device (default: its own choice)
  --help, -h           this message"
end

# === brightnessctl ===========================================================
# -m prints "name,class,current,percent%,max", so field 3 is the raw value and
# field 5 the maximum. BCTL_ARGS carries -m -c backlight, plus any -d from --device.

# Current raw brightness, as brightnessctl reports it.
function bctl_current
    set -l fields (string split , -- ($BCTL $BCTL_ARGS info)); or return 1
    echo $fields[3]
end

# Apply a raw value and echo back what brightnessctl actually set, which may
# differ from what we asked for since it clamps to [1, max].
function bctl_set --argument-names value
    set -l fields (string split , -- ($BCTL $BCTL_ARGS set $value)); or return 1
    echo $fields[3]
end

# === Sensor ==================================================================

function check_sensor
    if not test -r "$SENSOR"
        log "sensor $SENSOR is not readable"
        return 1
    end
end

# === Calibration curve =======================================================

function target_pct --argument-names raw
    set -l n (count $CAL_RAW)

    if test $raw -le $CAL_RAW[1]
        echo $CAL_PCT[1]
        return 0
    end

    set -l i 2
    while test $i -le $n
        if test $raw -le $CAL_RAW[$i]
            set -l j (math $i - 1)
            set -l x0 $CAL_RAW[$j]
            set -l x1 $CAL_RAW[$i]
            set -l y0 $CAL_PCT[$j]
            set -l y1 $CAL_PCT[$i]
            math -s0 "round($y0 + ($raw - $x0) * ($y1 - $y0) / ($x1 - $x0))"
            return 0
        end
        set i (math $i + 1)
    end

    echo $CAL_PCT[$n]
end

# Percentage of BL_MAX. No clamping needed: brightnessctl enforces a minimum
# of 1 and a maximum of max.
function pct_to_raw --argument-names pct
    math -s0 "round($pct * $BL_MAX / 100)"
end

# Fade from $from to $to so the change is not a visible snap.
#
# Geometric rather than linear: the eye responds to relative change, so a
# linear ramp puts all the visible stepping at the dark end - fading 10% -> 100%
# on this panel, a linear first step is +45% relative while the last is +4.7%.
# Multiplying by a constant ratio each step makes every step the same relative
# size, which is also why brightnessctl offers --exponent for its percentages.
function ramp_to --argument-names from to
    if test $RAMP_STEPS -le 1 -o -z "$from"
        bctl_set $to >/dev/null
        return
    end
    # The ratio is undefined from zero, and brightnessctl floors a set at 1.
    test $from -lt 1; and set from 1
    set -l step 1
    while test $step -le $RAMP_STEPS
        set -l value (math -s0 "round($from * ($to / $from) ^ ($step / $RAMP_STEPS))")
        bctl_set $value >/dev/null; or return 1
        test $step -lt $RAMP_STEPS; and sleep $RAMP_DELAY
        set step (math $step + 1)
    end
end

# === Main ====================================================================

function do_status
    check_sensor; or return 1
    set -l fields (string split , -- ($BCTL $BCTL_ARGS info))
    or begin
        log "brightnessctl found no usable backlight device"
        return 1
    end
    set -g BL_MAX $fields[5]

    set -l lux (read_attr $SENSOR)
    set -l want (target_pct $lux)

    echo "sensor:     $SENSOR"
    echo "reading:    $lux"
    echo "backlight:  $fields[1] ($fields[3]/$fields[5], $fields[4])"
    echo "target:     $want% ("(pct_to_raw $want)"/$fields[5])"
end

function run_daemon
    set -l fields (string split , -- ($BCTL $BCTL_ARGS info))
    or begin
        log "brightnessctl found no usable backlight device"
        return 1
    end
    set -g BL_MAX $fields[5]

    log "sensor $SENSOR -> $fields[1] (max $BL_MAX)"

    set -l applied_pct ""
    set -l lux_avg ""

    while true
        set -l lux (read_attr $SENSOR)
        if test -z "$lux"
            log "failed to read $SENSOR"
        else
            # Exponential moving average, seeded with the first sample so we
            # do not ramp up out of darkness on every start.
            if test -z "$lux_avg"
                set lux_avg $lux
            else
                set lux_avg (math "$SMOOTHING * $lux + (1 - $SMOOTHING) * $lux_avg")
            end
            set -l lux_round (math -s0 "round($lux_avg)")

            set -l want (target_pct $lux_round)
            test $want -lt $MIN_PCT; and set want $MIN_PCT

            if test -n "$applied_pct" -a (math "abs($want - 0$applied_pct)") -lt $DEADBAND
                vlog "lux $lux (avg $lux_round) - target $want% within deadband of $applied_pct%"
            else
                set -l goal (pct_to_raw $want)
                vlog "lux $lux (avg $lux_round) - target $want% ($goal/$BL_MAX)"
                ramp_to (bctl_current) $goal; or return 1
                set applied_pct $want
            end
        end

        test "$ONCE" = true; and return 0
        sleep $INTERVAL
    end
end

function main
    argparse --name=auto-brightness h/help v/verbose once status \
        interval= sensor= device= -- $argv
    or return 2

    if set -q _flag_help
        usage
        return 0
    end
    set -q _flag_verbose; and set -g VERBOSE true
    set -q _flag_once; and set -g ONCE true
    set -q _flag_interval; and set -g INTERVAL $_flag_interval
    set -q _flag_sensor; and set -g SENSOR $_flag_sensor
    set -q _flag_device; and set -a BCTL_ARGS -d $_flag_device

    if test (count $CAL_RAW) -ne (count $CAL_PCT)
        log "CAL_RAW and CAL_PCT must have the same length"
        return 1
    end

    if not command -q $BCTL
        log "$BCTL is not on PATH"
        return 1
    end

    if set -q _flag_status
        do_status
        return $status
    end

    check_sensor; or return 1
    run_daemon
end

main $argv
