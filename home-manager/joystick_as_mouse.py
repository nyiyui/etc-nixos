import sys
import time
import subprocess

from evdev import InputDevice, ecodes
import uinput

JOYSTICK_PATH = (
    "/dev/input/by-id/usb-Nintendo_Co.__Ltd._Pro_Controller_000000000001-event-joystick"
)

COEFF_X = 1000
COEFF_Y = 1000
BUTTON_MAP = {
    305: uinput.BTN_LEFT,
    304: uinput.BTN_RIGHT,
}


# Set your joystick event file
joystick = InputDevice(JOYSTICK_PATH)

# Create virtual mouse device
events = [
    uinput.KEY_A,
    uinput.KEY_S,
    uinput.KEY_D,
    uinput.KEY_F,
    uinput.REL_X,
    uinput.REL_Y,
    *BUTTON_MAP.values(),
    uinput.KEY_ENTER,
]
CMD_KEY = 307
CMD = [ "wl-kbptr", "-o", "modes=bisect" ];
ENTER_AND_CLICK = 308
STICK_THRESHOLD = 6000
STICK_MAP = {
    (-1, -1): uinput.KEY_A,
    (+1, -1): uinput.KEY_S,
    (-1, +1): uinput.KEY_D,
    (+1, +1): uinput.KEY_F,
}
ABS_X = 0
ABS_Y = 1

def signum(x):
    if x == 0:
        return 0
    elif x > 0:
        return 1
    else:
        return -1

with uinput.Device(events) as dev:
    print("looping...", file=sys.stderr)
    stick_x = 0
    stick_y = 0
    stick_x_now = 0
    stick_y_now = 0
    stick_lock = False # "lock" input after the first direction is entered, to prevent rebound from triggering an input
    BTN_TRIGGER = 305
    sitck_ignore_until = time.time()
    for event in joystick.read_loop():
        if event.type == ecodes.EV_ABS:
            if event.code == ABS_X:
                if abs(event.value) > STICK_THRESHOLD and not stick_lock:
                    print('rec', stick_x, stick_y)
                    stick_x = event.value
                if abs(stick_x) > STICK_THRESHOLD and abs(stick_y) > STICK_THRESHOLD:
                    stick_lock = True
                stick_x_now = event.value
                if abs(stick_x_now) < STICK_THRESHOLD and abs(stick_y_now) < STICK_THRESHOLD and stick_x != 0 and stick_y != 0 and time.time() > sitck_ignore_until:
                    mapped = STICK_MAP[(signum(stick_x), signum(stick_y))]
                    print('emit', mapped)
                    dev.emit_click(mapped)
                    stick_x = 0
                    stick_y = 0
                    stick_lock = False
                    sitck_ignore_until = time.time() + 0.1
            elif event.code == ABS_Y:
                if abs(event.value) > STICK_THRESHOLD and not stick_lock:
                    print('rec', stick_x, stick_y)
                    stick_y = event.value
                if abs(stick_x) > STICK_THRESHOLD and abs(stick_y) > STICK_THRESHOLD:
                    stick_lock = True
                stick_y_now = event.value
                if abs(stick_x_now) < STICK_THRESHOLD and abs(stick_y_now) < STICK_THRESHOLD and stick_x != 0 and stick_y != 0 and time.time() > sitck_ignore_until:
                    mapped = STICK_MAP[(signum(stick_x), signum(stick_y))]
                    print('emit', mapped)
                    dev.emit_click(mapped)
                    stick_x = 0
                    stick_y = 0
                    stick_lock = False
                    sitck_ignore_until = time.time() + 0.1
        elif event.type == ecodes.EV_KEY:
            if event.code in BUTTON_MAP.keys():
                dev.emit(BUTTON_MAP[event.code], event.value)
            elif event.code == ENTER_AND_CLICK:
                dev.emit_click(uinput.KEY_ENTER)
                dev.emit(uinput.BTN_LEFT, 1)
                dev.emit(uinput.BTN_LEFT, 0)
            elif event.code == CMD_KEY:
                subprocess.run(CMD)
        # now = time.time()
        # duration = now - prev_loop
        # dev.emit(uinput.REL_X, vel_x//COEFF_X)
        # dev.emit(uinput.REL_Y, vel_y//COEFF_Y)
        # prev_loop = now
