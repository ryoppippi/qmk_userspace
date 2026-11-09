{
  inputs,
  lib,
  target,
  ...
}:
{
  perSystem =
    {
      pkgs,
      self',
      writeNuApplication,
      ...
    }:
    let
      userspace = lib.fileset.unions [
        ../keyboards
        ../layouts
        ../users
        ../qmk.json
      ];
      keymapC = ../${target.keymapDir}/keymap.c;

      # Every compile and link runs with pkgs.qmk as an input: it propagates
      # the Python QMK's make needs, and its presence switches on the avr-gcc
      # wrapper's extra flags, so replaying a command anywhere else would
      # produce a different hex.
      toolchain.nativeBuildInputs = [ pkgs.qmk ];

      record = writeNuApplication { name = "record"; };
      build-objects = writeNuApplication {
        name = "build-objects";
        runtimeInputs = [ record ];
        flags = [
          "--qmk-home=${inputs.qmk_firmware}"
          "--keyboard=${target.keyboard}"
          "--keymap=${target.keymap}"
          "--keymap-dir=${target.keymapDir}"
        ];
      };
      link-keymap = writeNuApplication {
        name = "link-keymap";
      };

      # Everything except keymap.c, so it stays cached while only the keymap
      # changes.
      qmkObjects =
        pkgs.runCommand "${target.keymap}-qmk-objects"
          (
            toolchain
            // {
              src = lib.fileset.toSource {
                root = ../.;
                fileset = lib.fileset.difference userspace keymapC;
              };
            }
          )
          ''
            cp -r --no-preserve=mode $src userspace
            cd userspace
            ${lib.getExe build-objects} $out --jobs=$NIX_BUILD_CORES
          '';
    in
    {
      packages.qmk-objects = qmkObjects;

      packages.default = pkgs.runCommand "${target.keymap}-claw44-firmware" toolchain ''
        ${lib.getExe link-keymap} ${keymapC} $out/${target.hexName} --objects=${qmkObjects}
      '';

      # The replay above must keep producing exactly what QMK's own build
      # does; a QMK update that changes its build steps fails here.
      checks.firmware-matches-qmk =
        pkgs.runCommand "firmware-matches-qmk"
          (
            toolchain
            // {
              src = lib.fileset.toSource {
                root = ../.;
                fileset = userspace;
              };
            }
          )
          ''
            export HOME=$TMPDIR
            make -C ${inputs.qmk_firmware} ${target.keyboard}:${target.keymap} \
              QMK_USERSPACE=$src BUILD_DIR=$TMPDIR/build SKIP_GIT=yes -j$NIX_BUILD_CORES
            cmp $TMPDIR/build/${target.hexName} ${self'.packages.default}/${target.hexName}
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
