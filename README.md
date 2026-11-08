# ryoppippi's QMK Userspace

My keymaps, built against upstream [QMK](https://github.com/qmk/qmk_firmware) as an [External Userspace](https://docs.qmk.fm/newbs_external_userspace).

| Keyboard | Keymap |
|---|---|
| [Claw44 rev1](https://github.com/dailycraftkeyboard/claw44) | [`keyboards/dailycraft/claw44/keymaps/ryoppippi`](keyboards/dailycraft/claw44/keymaps/ryoppippi) |

## Build

Every push runs GitHub Actions and publishes the firmware to the `latest` release.

Locally:

```sh
qmk config user.overlay_dir="$(realpath .)"
qmk userspace-compile
```

## Flash

```sh
qmk flash -kb dailycraft/claw44/rev1 -km ryoppippi
```

Then press the reset switch on each half.
