{
  inputs,
  lib,
  target,
  ...
}:
{
  perSystem =
    { pkgs, self', ... }:
    let
      fontPath = "${pkgs.ibm-plex}/share/fonts/opentype";
    in
    {
      packages.draw-keymap = pkgs.writeShellApplication {
        name = "draw-keymap";
        runtimeInputs = [
          pkgs.qmk
          pkgs.keymap-drawer
          pkgs.yq-go
          pkgs.typst
          pkgs.pkgsCross.avr.buildPackages.gcc
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
          keymap -c "$work/config.yaml" draw --qmk-info-json "$work/info.json" "$work/keymap.yaml" > "$work/keymap.svg"

          # Typst only sees the pinned IBM Plex fonts and a fixed timestamp,
          # so the PDF is byte-identical on every machine, which
          # checks.keymap-drawing relies on.
          printf '#set page(width: auto, height: auto, margin: 16pt)\n#image("keymap.svg")\n' > "$work/keymap.typ"
          SOURCE_DATE_EPOCH=0 typst compile \
            --root "$work" --font-path ${fontPath} --ignore-system-fonts --ignore-embedded-fonts \
            "$work/keymap.typ" "$out/keymap.pdf"
          cp "$work/keymap.svg" "$out/keymap.svg"
        '';
      };

      checks.keymap-drawing =
        pkgs.runCommand "keymap-drawing-up-to-date"
          {
            src = lib.fileset.toSource {
              root = ../.;
              fileset = lib.fileset.unions [
                ../${target.keymapDir}/keymap.c
                ../keymap-drawer.yaml
                ../keymap.svg
                ../keymap.pdf
              ];
            };
          }
          ''
            fresh=$TMPDIR/fresh
            mkdir -p $fresh
            cd $src
            ${lib.getExe self'.packages.draw-keymap} $fresh
            for file in keymap.svg keymap.pdf; do
              if ! cmp -s $file $fresh/$file; then
                echo "$file is stale; run 'just draw' and commit the result." >&2
                exit 1
              fi
            done
            touch $out
          '';
    };
}
