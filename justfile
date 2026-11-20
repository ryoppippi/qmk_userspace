default: build

build:
    nix build

flash keyboard:
    nix run .#flash-{{ keyboard }}

draw:
    nix run .#draw-keymap

fmt:
    nix fmt

lint:
    qmk lint -kb dailycraft/claw44/rev1 -km ryoppippi
    qmk lint -kb dailycraft/wings42/rev2 -km ryoppippi

check:
    nix flake check

update:
    nix flake update
