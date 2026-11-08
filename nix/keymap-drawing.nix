{
  inputs,
  lib,
  target,
  ...
}:
{
  perSystem =
    { pkgs, self', ... }:
    {
      # Typst only sees the pinned IBM Plex fonts and a fixed timestamp. The
      # PDF still differs between x86_64 and aarch64 (text is outlined with
      # floating-point maths), so it is a build artefact rather than a
      # tracked file; only the SVG is compared in checks.keymap-drawing.
      packages.render-keymap-pdf = pkgs.writeShellApplication {
        name = "render-keymap-pdf";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.typst
        ];
        text = ''
          svg=$(realpath "$1")
          pdf=$(realpath -m "$2")
          work=$(mktemp -d)
          trap 'rm -rf "$work"' EXIT
          cp "$svg" "$work/keymap.svg"
          printf '#set page(width: auto, height: auto, margin: 16pt)\n#image("keymap.svg")\n' > "$work/keymap.typ"
          SOURCE_DATE_EPOCH=0 typst compile \
            --root "$work" \
            --font-path ${pkgs.ibm-plex}/share/fonts/opentype \
            --ignore-system-fonts --ignore-embedded-fonts \
            "$work/keymap.typ" "$pdf"
        '';
      };

      packages.draw-keymap = pkgs.writeShellApplication {
        name = "draw-keymap";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.gnused
          pkgs.qmk
          pkgs.keymap-drawer
          pkgs.yq-go
          pkgs.pkgsCross.avr.buildPackages.gcc
          self'.packages.render-keymap-pdf
        ];
        text = ''
          out=$(realpath "''${1:-.}")
          work=$(mktemp -d)
          trap 'rm -rf "$work"' EXIT
          export HOME=$work QMK_HOME=${inputs.qmk_firmware}

          # Expand the keymap's own macros without pulling in QMK headers,
          # so keycodes stay readable for keymap-drawer.
          touch "$work/empty.h"
          avr-gcc -E -P -DQMK_KEYBOARD_H="\"$work/empty.h\"" ${target.keymapDir}/keymap.c > "$work/keymap.i"

          # keymap-drawer only understands numeric layers in LT(), so map
          # the layer enum to its indices and reuse its names as titles.
          index=0 sed_args=() names=()
          while IFS= read -r layer; do
            sed_args+=(-e "s/(_$layer,/($index,/g")
            names+=("''${layer:0:1}$(tr '[:upper:]' '[:lower:]' <<< "''${layer:1}")")
            index=$((index + 1))
          done < <(sed -n '/enum layer_number/,/};/s/^ *_\([A-Z0-9_]*\).*/\1/p' "$work/keymap.i")
          sed "''${sed_args[@]}" "$work/keymap.i" > "$work/keymap.c"

          qmk c2json --no-cpp -kb ${target.keyboard} -km ${target.keymap} "$work/keymap.c" > "$work/keymap.json"
          qmk info -kb ${target.keyboard} -f json > "$work/info.json"
          keymap dump-config > "$work/default.yaml"
          # shellcheck disable=SC2016
          yq eval-all '. as $i ireduce ({}; . * $i)' "$work/default.yaml" keymap-drawer.yaml > "$work/config.yaml"

          keymap -c "$work/config.yaml" parse -c 12 -l "''${names[@]}" -q "$work/keymap.json" > "$work/keymap.yaml"
          keymap -c "$work/config.yaml" draw --qmk-info-json "$work/info.json" "$work/keymap.yaml" > "$out/keymap.svg"
          render-keymap-pdf "$out/keymap.svg" "$out/keymap.pdf"
        '';
      };

      packages.keymap-pdf = pkgs.runCommand "keymap-pdf" { } ''
        mkdir $out
        ${lib.getExe self'.packages.render-keymap-pdf} ${../keymap.svg} $out/keymap.pdf
      '';

      checks.keymap-drawing =
        pkgs.runCommand "keymap-drawing-up-to-date"
          {
            src = lib.fileset.toSource {
              root = ../.;
              fileset = lib.fileset.unions [
                ../${target.keymapDir}/keymap.c
                ../keymap-drawer.yaml
                ../keymap.svg
              ];
            };
          }
          ''
            fresh=$TMPDIR/fresh
            mkdir -p $fresh
            cd $src
            ${lib.getExe self'.packages.draw-keymap} $fresh
            if ! cmp -s keymap.svg $fresh/keymap.svg; then
              echo "keymap.svg is stale; run 'just draw' and commit the result." >&2
              exit 1
            fi
            touch $out
          '';
    };
}
