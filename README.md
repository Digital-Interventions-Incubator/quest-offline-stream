# Quest 3 "One-Click" Wireless Streamer (no adb install needed) 🎮📺

Local, flicker-free casting of your **Meta Quest 3** to a PC or TV using **scrcpy** and **OBS Studio** — **Windows only**.

## Why this fork

The [original method](https://github.com/MitchSchauer/Offline-Quest-Stream) works, but it asks the user to open a terminal and type `adb tcpip 5555`, which means they need adb. You don't: **the scrcpy zip already bundles `adb.exe`**. These scripts use that bundled adb by path, so nobody has to install anything or type commands.

What you do instead:

| Step | Action |
|------|--------|
| Once (per headset reboot) | Plug in USB, double-click `setup-stream.bat`, unplug |
| Every time | Double-click `queststream.bat` |

## 🛠️ Setup (you, the host — not the end user)

1. **scrcpy (v3.3.4 or newer):** [Download from GitHub](https://github.com/Genymobile/scrcpy/releases) and extract the zip to a folder like `C:\scrcpy`.
2. Copy `setup-stream.bat` and `queststream.bat` **into that same folder** (next to `scrcpy.exe` and `adb.exe`).
3. **OBS Studio:** install it from [obsproject.com](https://obsproject.com/download) (the default install path is auto-detected; a `OBS Studio.lnk` shortcut on `C:\Users\Public\Desktop` also works).

## 🔑 One-time: Developer Mode (once per Meta account)

1. Register as a dev at [dashboard.oculus.com](https://dashboard.oculus.com) — create an "Organization" (any name). Meta may ask to verify your identity.
2. In the Meta Horizon app on your phone: **Menu > Devices > [Quest 3] > Headset Settings > Developer Mode**, toggle **Debug Mode** ON.
3. Reboot the headset.

## 🔌 One-time (per headset reboot): go wireless

1. Connect the Quest to the PC via USB-C.
2. Put the headset on and select **"Always allow USB debugging from this computer"**.
3. Double-click **`setup-stream.bat`**. It switches the headset to wireless mode, detects the Quest's Wi-Fi IP, saves it, and tells you to unplug.
4. Unplug the cable. Done.

## 📶 Streaming

Double-click **`queststream.bat`**. It reconnects over Wi-Fi, launches OBS, and opens the scrcpy window titled **`Quest3Full`**.

If you know the IP changed, you can override without re-running setup:

```
queststream.bat 192.168.1.42
```

## 🎨 OBS "TV-Ready" Cleanup (once)

You can also use Shift + Drag for freeform fitting.

1. **Add Source:** create a *Window Capture* source and select the `Quest3Full` window.
2. **Crop Filter:** right-click the source > *Filters* > *+* > *Crop/Pad*. Right: `800` (removes the right eye). Top/Bottom: `225` (centers the 16:9 view).
3. **Fix the Tilt:** right-click the source > *Transform* > *Edit Transform*. Rotation: `-22` (fixes the Quest 3 downward camera angle).
4. **Cast to TV:** right-click the OBS Preview > *Fullscreen Projector* > pick your TV (or use Win + K).

## 💡 Troubleshooting

- **"Could not connect"** — headset asleep or not on the same Wi-Fi as the PC, or you haven't run `setup-stream.bat` since the last headset reboot. Run it again.
- **IP changed?** Re-run `setup-stream.bat` (or pass the IP to `queststream.bat`).
- **Flickering?** Never add `--crop` to the scrcpy flags — let OBS do the cropping.
- **Laggy?** Put the Quest on 5 GHz/6 GHz Wi-Fi and the PC on Ethernet.
- **"adb.exe not found"** — the bats are not in the scrcpy folder, or you downloaded scrcpy without adb (the default Windows zip includes it).

## Notes

- The Quest's Wi-Fi IP can change after router restarts; that is why setup is run once per headset reboot (it's just plug + 2 clicks).
- All commands use the adb/scrcpy bundled in the scrcpy folder — nothing is installed system-wide.
