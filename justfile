default: build

target := "dailycraft/claw44/rev1:ryoppippi"

# Incremental build against the pinned QMK from the dev shell.
qmk_make := 'make -C "${QMK_HOME:?enter the dev shell first}" QMK_USERSPACE="$PWD" BUILD_DIR="$PWD/.build" SKIP_GIT=yes -j' + num_cpus()

build:
    {{ qmk_make }} {{ target }}

flash:
    {{ qmk_make }} {{ target }}:flash

draw:
    nix run .#draw-keymap

fmt:
    nix fmt

lint:
    qmk lint -kb dailycraft/claw44/rev1 -km ryoppippi

check:
    nix flake check

update:
    nix flake update
