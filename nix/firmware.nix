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
      userspace = lib.fileset.unions [
        ../keyboards
        ../layouts
        ../users
        ../qmk.json
      ];
      keymapC = ../${target.keymapDir}/keymap.c;
      buildName = lib.removeSuffix ".hex" target.hexName;

      qmkMake = userspaceDir: buildDir: ''
        export HOME=$TMPDIR
        make -C ${inputs.qmk_firmware} ${target.keyboard}:${target.keymap} \
          QMK_USERSPACE=${userspaceDir} BUILD_DIR=${buildDir} SKIP_GIT=yes -j$NIX_BUILD_CORES
      '';

      # Records each toolchain call so the keymap can later be compiled and
      # linked without going through QMK's make.
      recorder = pkgs.writeShellScript "record" ''
        name=$(basename "$0")
        real=$(PATH=''${PATH#"$RECORDER_BIN:"} command -v "$name")
        { printf '%q ' "$real" "$@"; printf '\n'; } > "$(mktemp "$RECORDER_LOG/XXXXXX")"
        exec "$real" "$@"
      '';

      # Everything except keymap.c: QMK's objects, built against a stub keymap,
      # plus the exact compile, link and objcopy commands make used.
      qmkObjects = pkgs.stdenvNoCC.mkDerivation {
        name = "${target.keymap}-qmk-objects";
        src = lib.fileset.toSource {
          root = ../.;
          fileset = lib.fileset.difference userspace keymapC;
        };
        nativeBuildInputs = [
          pkgs.qmk
          pkgs.ripgrep
        ];

        buildPhase = ''
          runHook preBuild
          mkdir -p $out
          cp -r . $out/userspace
          printf '#include QMK_KEYBOARD_H\nconst uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {{{0}}};\n' \
            > $out/userspace/${target.keymapDir}/keymap.c

          export RECORDER_BIN=$TMPDIR/bin RECORDER_LOG=$TMPDIR/log
          mkdir -p $RECORDER_BIN $RECORDER_LOG
          ln -s ${recorder} $RECORDER_BIN/avr-gcc
          ln -s ${recorder} $RECORDER_BIN/avr-objcopy
          export PATH=$RECORDER_BIN:$PATH
          {
            ${qmkMake "$out/userspace" "$out/build"}
          } 2>&1 | tee $TMPDIR/make.log

          pick() {
            local files
            mapfile -t files < <(rg -l "$@" $RECORDER_LOG)
            if [ ''${#files[@]} -ne 1 ]; then
              echo "expected one toolchain call matching $*, found ''${#files[@]}" >&2
              exit 1
            fi
            cat "''${files[0]}"
          }
          {
            echo "compile=($(pick -F quantum/keymap_introspection.c))"
            echo "link=($(pick -F -- "--output $out/build/${buildName}.elf"))"
            echo "objcopy=($(pick -F -- '-O ihex'))"
            echo "max_size=$(sed -n 's|.*The firmware size is fine - [0-9]*/\([0-9]*\).*|\1|p' $TMPDIR/make.log)"
          } > $out/commands.sh
          grep -q '^max_size=[0-9]' $out/commands.sh

          rm -f $out/build/${buildName}.* $out/build/obj_${buildName}/quantum/keymap_introspection.* $out/userspace/*.hex
          runHook postBuild
        '';
        dontInstall = true;
      };
    in
    {
      packages.qmk-objects = qmkObjects;

      # Only keymap.c is compiled here; the rest comes from qmk-objects, which
      # stays cached until QMK, config.h or rules.mk change.
      packages.default =
        pkgs.runCommand "${target.keymap}-claw44-firmware" { nativeBuildInputs = [ pkgs.qmk ]; }
          ''
            source ${qmkObjects}/commands.sh
            stale=${qmkObjects}/build/obj_${buildName}/quantum/keymap_introspection
            elf=${qmkObjects}/build/${buildName}
            work=$TMPDIR/${buildName}

            cd ${inputs.qmk_firmware}
            "''${compile[@]//"$stale"/"$work"}" -UKEYMAP_C -DKEYMAP_C=\"${keymapC}\"
            link=("''${link[@]//"$stale"/"$work"}")
            "''${link[@]//"$elf"/"$work"}"
            objcopy=("''${objcopy[@]//"$elf"/"$work"}")
            "''${objcopy[@]}"

            size=$(avr-size --target=ihex $work.hex | awk 'NR == 2 { print $4 }')
            echo "firmware size: $size/$max_size"
            if [ "$size" -gt "$max_size" ]; then
              echo "firmware is too large" >&2
              exit 1
            fi
            install -Dm644 $work.hex $out/${target.hexName}
          '';

      # The shortcut above must keep producing exactly what QMK's own build
      # does; a QMK update that changes its build steps fails here.
      checks.firmware-matches-qmk =
        pkgs.runCommand "firmware-matches-qmk"
          {
            src = lib.fileset.toSource {
              root = ../.;
              fileset = userspace;
            };
            nativeBuildInputs = [ pkgs.qmk ];
          }
          ''
            cp -r --no-preserve=mode $src userspace
            cd userspace
            ${qmkMake "$PWD" "$TMPDIR/build"}
            cmp ${target.hexName} ${self'.packages.default}/${target.hexName}
            touch $out
          '';

      apps.flash = {
        type = "app";
        program = toString (
          pkgs.writeShellScript "flash" ''
            export QMK_HOME=${inputs.qmk_firmware}
            exec ${lib.getExe pkgs.qmk} flash ${self'.packages.default}/${target.hexName}
          ''
        );
      };
    };
}
