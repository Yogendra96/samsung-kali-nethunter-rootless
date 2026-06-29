# Samsung-Specific Notes for NetHunter Rootless

> These apply to any Samsung Galaxy phone running One UI 5.0+ (Android 13+).
> Includes S24, S25, S26, A series, etc.

## 1. Auto Blocker must be OFF

Samsung One UI 5.0+ ships with **Auto Blocker** enabled by default. This blocks:
- USB debugging (the ADB connection you need for everything else)
- Side-loading APKs (you can't install Termux manually without this off)
- USB data connections from "untrusted" computers

**This is a software security feature, NOT a Knox trip. Warranty is unaffected.**

### How to turn it off

```
Settings → Device Care → Auto Blocker → OFF
```

After the install, you can re-enable it (it'll just block future ADB / unknown-APK installs).

## 2. Knox warranty bit stays at 0x0000

The Knox hardware e-fuse (`ro.boot.warranty_bit`) only trips when you:
- Unlock the bootloader
- Flash a custom recovery
- Flash a modified kernel
- Root with Magisk/KSU/SuperSU

**None of these happen with this project.** The chroot runs entirely in userspace.

To verify after install:
```bash
adb -d shell getprop ro.boot.warranty_bit
# Should return: 0x0000
```

## 3. Battery optimization kills Termux in the background

Samsung's "Device Care" feature aggressively kills background apps. **Without the whitelist, Termux dies after ~10 minutes in the background**, taking the chroot with it.

### How to whitelist Termux

1. `Settings → Device Care → Battery → Background Usage Limits → Never Sleeping Apps → Add Termux`
2. Long-press the **Termux** app icon → **App Info** → **Battery** → select **Unrestricted**

### If that doesn't work

Also try:
- `Settings → Device Care → Memory → RAM Plus → OFF` (Samsung's zRAM extension can interfere with proot)

## 4. Developer Options setup

### On a fresh Samsung phone

1. `Settings → About Phone → Software Information → tap Build Number 7 times` (enables Developer Options)
2. `Settings → Developer Options → USB Debugging: ON`
3. `Settings → Developer Options → Default USB Configuration → File Transfer`
   - Default is "Charging only" which blocks ADB
4. (Optional) `Settings → Developer Options → Disable Permission Monitoring: OFF` (default is off)

### On a Samsung phone that already had Custom ROMs / Root

If you've ever unlocked the bootloader, the Knox warranty bit is already tripped (0x1). This project still works — but the phone has no warranty, and Samsung Pay / Secure Folder / banking apps may refuse to run.

## 5. Mac file transfer

macOS doesn't natively speak MTP (the protocol Android uses for file transfer). You won't see the phone in Finder. **Use `adb` instead:**

```bash
# Install APKs
adb -d install termux.apk
adb -d install NetHunterStore.apk

# Push/pull files
adb -d push /local/file /sdcard/Download/
adb -d pull /sdcard/Download/file /local/destination

# Take screenshots
adb -d shell screencap -p /sdcard/screenshot.png
adb -d pull /sdcard/screenshot.png ./

# Use Android File Transfer if you really want drag-and-drop
# (unreliable, install from https://www.android.com/filetransfer/)
```

## 6. Wi-Fi quirks

Samsung phones are aggressive about disconnecting Wi-Fi to save battery. If you see `apt update` fail with DNS errors, check:

```bash
# From Mac, check the phone's network state
adb -d shell dumpsys connectivity | grep "Active default"
# If output is "Active default network: none" or absent, the phone has disconnected
```

Manually reconnect by:
- Pull down the notification shade
- Tap the Wi-Fi tile to disable then enable
- OR select the network from the Wi-Fi list (will prompt for password)

## 7. Knox-specific apps that may not work

Even though Knox is at 0x0000 and warranty is intact, some apps use the Knox attestation API to verify device state. With rootless NetHunter (no actual system changes), these should still work:

- ✅ Samsung Pay
- ✅ Secure Folder
- ✅ Samsung Wallet
- ✅ Banking apps
- ✅ Google Pay
- ✅ Netflix HD (Samsung sometimes requires SafetyNet)

If any of these stop working, it's almost certainly unrelated to this project — they use Google's Play Integrity API which checks for things like "device is rooted" via hardware attestation. The rootless chroot doesn't trip any of those checks.

## 8. The hidden USB-C connection mode

When you plug the S26 Ultra into the Mac via USB-C, you might see a notification on the phone that says "USB for file transfer" or "USB controlled by". Tap it and select **"File Transfer / Android Auto"** mode. Without this, ADB may not connect.

## 9. Camera access from the chroot

Tools that need to access the camera (e.g., `zbarimg` for QR scanning from the live camera) won't work in the chroot. The chroot can't access Android's camera HAL.

Workaround: take a photo with the normal camera app, then analyze the file from the chroot:
```bash
# From the chroot
adb pull /sdcard/DCIM/photo.jpg /tmp/
zbarimg /tmp/photo.jpg
```

## 10. Battery and thermal throttling

Heavy CPU use (like running `nmap` against a large network) will heat up the phone and trigger thermal throttling. The Snapdragon 8 Elite Gen 5 has aggressive throttling — sustained load can drop the CPU to 50% within minutes.

For long-running scans, use the `nice` command:
```bash
nice -n 19 nmap -sV 192.168.1.0/24
```

Or break the scan into smaller chunks and run them with delays.
## See also

For the full Knox warranty verification table (all 12 checks with exact `adb` commands to run), see [KNOX-WARRANTY.md](KNOX-WARRANTY.md).
