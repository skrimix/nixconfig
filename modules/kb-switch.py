import os
import evdev
from evdev import ecodes
from dbus import SessionBus

KEYBOARD_DEVICE_NAME = 'Weltrend USB Mouse'  # yeah, of course mouse is a keyboard

_SWITCH_HOTKEY = {"KEY_LEFTSHIFT", "KEY_LEFTCTRL"}
SWITCH_HOTKEY = set([ecodes.ecodes[k] for k in _SWITCH_HOTKEY])
hotkey_len = len(SWITCH_HOTKEY)


# this is ugly (hardcode username and dbus?)
def switch_layout():
    print("Switching keyboard layout")
    pid = os.popen("pidof -s kded6").read().strip('\n')
    uid = int(os.popen(f"stat -c %u /proc/{pid}").read().strip('\n'))
    #print(f"KDE daemon is running as user {uid}")
    if uid != os.geteuid():
        os.seteuid(uid)
    dbus_address = os.popen(f"grep -z DBUS_SESSION_BUS_ADDRESS /proc/{pid}/environ | sed 's/DBUS_SESSION_BUS_ADDRESS=//'").read().strip('\0\n')
    os.environ["DBUS_SESSION_BUS_ADDRESS"] = dbus_address
    # ask KDE to switch to the next layout
    #os.system(f"dbus-send --type=method_call --dest=org.kde.keyboard /Layouts org.kde.KeyboardLayouts.switchToNextLayout")
    bus = SessionBus(dbus_address)
    kde = bus.get_object('org.kde.keyboard', '/Layouts')
    kde.switchToNextLayout()


potential_hotkey = False
keys_pressed = set()


def start_listen():
    global potential_hotkey
    global keys_pressed
    devices = [evdev.InputDevice(fn) for fn in evdev.list_devices()]
    keyboard = [d for d in devices if KEYBOARD_DEVICE_NAME == d.name][0]
    for event in keyboard.read_loop():
        if event.type == ecodes.EV_KEY:
            if event.value == 1:
                #print(f"Key {ecodes.bytype[ecodes.EV_KEY][event.code]} pressed")
                keys_pressed.add(event.code)
            elif event.value == 0:
                #print(f"Key {ecodes.bytype[ecodes.EV_KEY][event.code]} released")
                keys_pressed.discard(event.code)
            if len(keys_pressed) > hotkey_len or (len(keys_pressed) == hotkey_len and keys_pressed != SWITCH_HOTKEY):
                if potential_hotkey:
                    print("Hotkey canceled")
                    potential_hotkey = False
            elif not potential_hotkey and event.value == 1 and keys_pressed == SWITCH_HOTKEY:
                print("Potential hotkey detected")
                potential_hotkey = True
            elif potential_hotkey and event.value == 0:
                print("Hotkey confirmed")
                potential_hotkey = False
                switch_layout()


print(f"Listening for hotkey: {_SWITCH_HOTKEY}")
start_listen()
