{
  description = "ryoppippi's QMK keymaps (External Userspace)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    qmk_firmware = {
      url = "git+https://github.com/qmk/qmk_firmware?ref=master&submodules=1&shallow=1";
      flake = false;
    };
  };

  outputs =
    { self, nixpkgs, qmk_firmware, ... }:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      keyboard = "dailycraft/claw44/rev1";
      keymap = "ryoppippi";
      hexName = "${builtins.replaceStrings [ "/" ] [ "_" ] keyboard}_${keymap}.hex";
    in
    {
      packages = forAllSystems (pkgs: {
        default = pkgs.stdenvNoCC.mkDerivation {
          name = "${keymap}-claw44-firmware";
          src = nixpkgs.lib.fileset.toSource {
            root = ./.;
            fileset = nixpkgs.lib.fileset.unions [
              ./keyboards
              ./layouts
              ./users
              ./qmk.json
            ];
          };

          nativeBuildInputs = [ pkgs.qmk ];

          buildPhase = ''
            runHook preBuild
            export HOME=$TMPDIR
            cp -r --no-preserve=mode ${qmk_firmware} $TMPDIR/qmk_firmware
            make -C $TMPDIR/qmk_firmware ${keyboard}:${keymap} \
              QMK_USERSPACE=$PWD SKIP_GIT=yes -j$NIX_BUILD_CORES
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            install -Dm644 ${hexName} -t $out
            runHook postInstall
          '';
        };

        keymap-drawing = pkgs.stdenvNoCC.mkDerivation {
          name = "${keymap}-claw44-keymap-drawing";
          src = nixpkgs.lib.fileset.toSource {
            root = ./.;
            fileset = nixpkgs.lib.fileset.unions [
              ./keyboards
              ./keymap-drawer.yaml
            ];
          };

          nativeBuildInputs = [
            pkgs.qmk
            pkgs.keymap-drawer
            pkgs.librsvg
            pkgs.yq-go
          ];

          buildPhase = ''
            runHook preBuild
            export HOME=$TMPDIR QMK_HOME=${qmk_firmware}
            keymap_c=keyboards/dailycraft/claw44/keymaps/${keymap}/keymap.c

            # Expand the keymap's own macros without pulling in QMK headers,
            # so keycodes stay readable for keymap-drawer.
            touch empty.h
            avr-gcc -E -P -DQMK_KEYBOARD_H='"empty.h"' -I. $keymap_c > keymap.i

            # keymap-drawer only understands numeric layers in LT(), so map
            # the layer enum to its indices and reuse its names as titles.
            layers=$(sed -n '/enum layer_number/,/};/s/^ *_\([A-Z0-9_]*\).*/\1/p' keymap.i)
            index=0 sed_args=() names=()
            for layer in $layers; do
              sed_args+=(-e "s/(_$layer,/($index,/g")
              names+=("''${layer:0:1}$(echo "''${layer:1}" | tr A-Z a-z)")
              index=$((index + 1))
            done
            sed "''${sed_args[@]}" keymap.i > keymap.c

            qmk c2json --no-cpp -kb ${keyboard} -km ${keymap} keymap.c > keymap.json
            qmk info -kb ${keyboard} -f json > info.json
            keymap dump-config > default.yaml
            yq eval-all '. as $i ireduce ({}; . * $i)' default.yaml keymap-drawer.yaml > config.yaml

            keymap -c config.yaml parse -c 12 -l "''${names[@]}" -q keymap.json > keymap.yaml
            keymap -c config.yaml draw --qmk-info-json info.json keymap.yaml > keymap.svg
            rsvg-convert -f pdf -o keymap.pdf keymap.svg
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            install -Dm644 keymap.svg keymap.pdf -t $out
            runHook postInstall
          '';
        };
      });

      apps = forAllSystems (pkgs: {
        flash = {
          type = "app";
          program = toString (
            pkgs.writeShellScript "flash" ''
              export QMK_HOME=${qmk_firmware}
              exec ${pkgs.lib.getExe pkgs.qmk} flash ${self.packages.${pkgs.stdenv.hostPlatform.system}.default}/${hexName}
            ''
          );
        };
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShellNoCC {
          packages = [
            pkgs.qmk
            pkgs.just
            pkgs.keymap-drawer
            pkgs.librsvg
          ];
          QMK_HOME = qmk_firmware;
        };
      });
    };
}
