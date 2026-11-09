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

      # Every compile and link runs in this environment: pkgs.qmk propagates
      # the Python QMK's make needs, and the avr-gcc wrapper reads its flags
      # from the environment, so replaying a command anywhere else could
      # produce a different hex. Hardening flags only bloat AVR firmware.
      toolchain = {
        nativeBuildInputs = [
          avrGcc
          pkgs.qmk
        ];
        hardeningDisable = [ "all" ];
      };

      # nixpkgs' cc-wrapper forces frame pointers on every target; on AVR that
      # pins a register pair and grows the firmware, and QMK never asks for it.
      avrGcc = pkgs.pkgsCross.avr.buildPackages.gcc.overrideAttrs (old: {
        postFixup = (old.postFixup or "") + ''
          sed -i '/omit-frame-pointer/d' $out/nix-support/cc-cflags-before
        '';
      });

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
