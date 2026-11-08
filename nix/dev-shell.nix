{ inputs, ... }:
{
  perSystem =
    { config, pkgs, ... }:
    {
      devShells.default = pkgs.mkShellNoCC {
        packages = [
          pkgs.qmk
          pkgs.just
        ]
        ++ config.pre-commit.settings.enabledPackages;
        QMK_HOME = inputs.qmk_firmware;
        shellHook = config.pre-commit.shellHook;
      };
    };
}
