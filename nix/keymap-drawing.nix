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

      packages.draw-keymap = writeNuApplication {
        name = "draw-keymap";
        runtimeInputs = [
          pkgs.qmk
          pkgs.keymap-drawer
          pkgs.pkgsCross.avr.buildPackages.gcc
          self'.packages.render-keymap-pdf
        ];
        flags = [
          "--keyboard=${target.keyboard}"
          "--keymap=${target.keymap}"
          "--keymap-dir=${target.keymapDir}"
        ];
        env.QMK_HOME = "${inputs.qmk_firmware}";
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
            mkdir $TMPDIR/fresh
            cd $src
            ${lib.getExe self'.packages.draw-keymap} $TMPDIR/fresh
            if ! cmp -s keymap.svg $TMPDIR/fresh/keymap.svg; then
              echo "keymap.svg is stale; run 'just draw' and commit the result." >&2
              exit 1
            fi
            touch $out
          '';
    };
}
