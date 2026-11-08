default: build

build:
    nix build

flash:
    nix run .#flash

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
