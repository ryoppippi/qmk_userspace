default: build

build:
    nix build

flash:
    nix run .#flash

update:
    nix flake update qmk_firmware

lint:
    qmk lint -kb dailycraft/claw44/rev1 -km ryoppippi

draw:
    nix build .#keymap-drawing -o result-keymap
    install -m644 result-keymap/keymap.svg result-keymap/keymap.pdf .
