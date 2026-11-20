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
      drawingsDir = "drawings";

      drawKeymap =
        name: target:
        writeNuApplication {
          name = "draw-keymap";
          runtimeInputs = [
            pkgs.qmk
            pkgs.keymap-drawer
            pkgs.pkgsCross.avr.buildPackages.gcc
            self'.packages.render-keymap-pdf
          ];
          flags = [
            "--name=${name}"
            "--keyboard=${target.keyboard}"
            "--keymap=${target.keymap}"
            "--keymap-dir=${target.keymapDir}"
          ];
          env.QMK_HOME = "${inputs.qmk_firmware}";
        };

      drawers = lib.mapAttrs drawKeymap targets;
    in
    {
      # Typst only sees the pinned IBM Plex fonts and a fixed timestamp. The
      # PDF still differs between x86_64 and aarch64 (text is outlined with
      # floating-point maths), so it is a build artefact rather than a
      # tracked file; only the SVG is compared in checks.keymap-drawing.
      packages.render-keymap-pdf = writeNuApplication {
        name = "render-keymap-pdf";
        runtimeInputs = [ pkgs.typst ];
        flags = [ "--font-path=${pkgs.ibm-plex}/share/fonts/opentype" ];
      };

      packages.draw-keymap = pkgs.writeShellApplication {
        name = "draw-keymap";
        text = lib.concatMapStringsSep "\n" (drawer: "${lib.getExe drawer} ${drawingsDir}") (
          lib.attrValues drawers
        );
      };

      packages.keymap-pdf = pkgs.runCommand "keymap-pdf" { } (
        ''
          mkdir $out
        ''
        + lib.concatMapStringsSep "\n" (
          name:
          "${lib.getExe self'.packages.render-keymap-pdf} ${../${drawingsDir}/${name}.svg} $out/keymap-${name}.pdf"
        ) (lib.attrNames targets)
      );

      checks.keymap-drawing =
        pkgs.runCommand "keymap-drawing-up-to-date"
          {
            src = lib.fileset.toSource {
              root = ../.;
              fileset = lib.fileset.unions (
                [
                  ../users
                  ../keymap-drawer.yaml
                  ../${drawingsDir}
                ]
                ++ lib.mapAttrsToList (_: target: ../${target.keymapDir}) targets
              );
            };
          }
          ''
            mkdir $TMPDIR/fresh
            cd $src
            ${lib.concatMapStringsSep "\n" (drawer: "${lib.getExe drawer} $TMPDIR/fresh") (
              lib.attrValues drawers
            )}
            for name in ${lib.escapeShellArgs (lib.attrNames targets)}; do
              if ! cmp -s ${drawingsDir}/$name.svg $TMPDIR/fresh/$name.svg; then
                echo "${drawingsDir}/$name.svg is stale; run 'just draw' and commit the result." >&2
                exit 1
              fi
            done
            touch $out
          '';
    };
}
