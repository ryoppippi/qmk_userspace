# ryoppippi's QMK Userspace

My keymaps, built against upstream [QMK](https://github.com/qmk/qmk_firmware) as an [External Userspace](https://docs.qmk.fm/newbs_external_userspace).

| Keyboard | Keymap |
|---|---|
| [Claw44 rev1](https://github.com/dailycraftkeyboard/claw44) | [`keyboards/dailycraft/claw44/keymaps/ryoppippi`](keyboards/dailycraft/claw44/keymaps/ryoppippi) |

## Build

Every push runs GitHub Actions and publishes the firmware to the `latest` release.

Locally, with Nix (`direnv allow` once, or `nix develop`):

```sh
just build   # nix build -> result/*.hex
just flash   # build, then flash; press the reset switch on each half
just update  # bump the pinned qmk_firmware
```
