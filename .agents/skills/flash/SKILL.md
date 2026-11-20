---
name: flash
description: Flashes the Claw44 or wings42 firmware onto the keyboard. Use when the user asks to flash or write the firmware (書き込み).
---

# Flash

README.md's "Flashing" section has the cable and reset rules; follow it.

1. Flash only the left half (the master) when only a `keymap.c` changed.
   Flash both halves when QMK, `users/ryoppippi/config.h`, or a `rules.mk`
   changed.
2. Before asking for a reset, check the half is plugged straight into the Mac:
   in `ioreg -p IOUSB -l -w0 | rg '"USB Product Name"'` it must not sit under a
   hub. A hub is the usual reason no serial port appears, which `qmk flash`
   reports as a Caterina bootloader that is not writable.
3. Start `nix run .#flash-<keyboard>` in the background first, then ask the user
   to reset: the bootloader closes after about 8 seconds, so the flasher must
   already be waiting.
4. For the second half, ask the user to move the cable, repeat steps 2 and 3,
   then ask them to plug the cable back into the left half.
