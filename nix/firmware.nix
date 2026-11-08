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
      packages.default = pkgs.stdenvNoCC.mkDerivation {
        name = "${target.keymap}-claw44-firmware";
        src = lib.fileset.toSource {
          root = ../.;
          fileset = lib.fileset.unions [
            ../keyboards
            ../layouts
            ../users
            ../qmk.json
          ];
        };

        nativeBuildInputs = [ pkgs.qmk ];

        buildPhase = ''
          runHook preBuild
          export HOME=$TMPDIR
          cp -r --no-preserve=mode ${inputs.qmk_firmware} $TMPDIR/qmk_firmware
          make -C $TMPDIR/qmk_firmware ${target.keyboard}:${target.keymap} \
            QMK_USERSPACE=$PWD SKIP_GIT=yes -j$NIX_BUILD_CORES
          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          install -Dm644 ${target.hexName} -t $out
          runHook postInstall
        '';
      };

      checks.firmware = self'.packages.default;

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
