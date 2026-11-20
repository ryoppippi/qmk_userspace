{
  inputs,
  lib,
  targets,
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
      # Drop this once https://github.com/NixOS/nixpkgs/issues/585479 is fixed.
      avrGcc = pkgs.pkgsCross.avr.buildPackages.gcc.overrideAttrs (old: {
        postFixup = (old.postFixup or "") + ''
          sed -i '/omit-frame-pointer/d' $out/nix-support/cc-cflags-before
        '';
      });

      record = writeNuApplication { name = "record"; };
      link-keymap = writeNuApplication {
        name = "link-keymap";
      };

      perTarget =
        name: target:
        let
          # Only what this keyboard's build reads, so editing another
          # keyboard's keymap leaves it cached.
          userspace = lib.fileset.unions [
            ../users
            ../${target.keymapDir}
            ../qmk.json
          ];
          keymapC = ../${target.keymapDir}/keymap.c;

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

          # Everything except keymap.c, so it stays cached while only the
          # keymap changes.
          qmkObjects =
            pkgs.runCommand "${name}-qmk-objects"
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

          firmware = pkgs.runCommand "${name}-firmware" toolchain ''
            ${lib.getExe link-keymap} ${keymapC} $out/${target.hexName} --objects=${qmkObjects}
          '';
        in
        {
          packages = {
            "${name}-qmk-objects" = qmkObjects;
            ${name} = firmware;
          };

          # The replay above must keep producing exactly what QMK's own build
          # does; a QMK update that changes its build steps fails here.
          checks."${name}-firmware-matches-qmk" =
            pkgs.runCommand "${name}-firmware-matches-qmk"
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
                cmp $TMPDIR/build/${target.hexName} ${firmware}/${target.hexName}
                touch $out
              '';

          apps."flash-${name}" = {
            type = "app";
            program = toString (
              pkgs.writeShellScript "flash-${name}" ''
                export QMK_HOME=${inputs.qmk_firmware}
                exec ${lib.getExe pkgs.qmk} flash ${firmware}/${target.hexName}
              ''
            );
          };
        };

      outputs = lib.mapAttrsToList perTarget targets;
    in
    {
      packages = lib.mergeAttrsList (map (o: o.packages) outputs) // {
        default = pkgs.symlinkJoin {
          name = "firmware";
          paths = map (name: self'.packages.${name}) (lib.attrNames targets);
        };
      };
      checks = lib.mergeAttrsList (map (o: o.checks) outputs);
      apps = lib.mergeAttrsList (map (o: o.apps) outputs);
    };
}
