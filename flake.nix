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
          ];
          QMK_HOME = qmk_firmware;
        };
      });
    };
}
