{
  perSystem =
    { lib, pkgs, ... }:
    {
      treefmt = {
        projectRootFile = "flake.nix";

        programs = {
          clang-format.enable = true;
          deadnix.enable = true;
          nixfmt.enable = true;
          statix.enable = true;
        };

        # Rendered by draw-keymap; formatting it would make the staleness
        # check report a diff that the generator never wrote.
        settings.global.excludes = [ "keymap.svg" ];

        settings.formatter = {
          deadnix.priority = 1;
          statix.priority = 2;
          nixfmt.priority = 3;
          oxfmt = {
            command = lib.getExe pkgs.oxfmt;
            options = [ "--no-error-on-unmatched-pattern" ];
            includes = [
              "*.md"
              "*.json"
              "*.yaml"
              "*.yml"
            ];
          };
          actionlint = {
            command = lib.getExe pkgs.actionlint;
            includes = [ ".github/workflows/*.yaml" ];
          };
        };
      };
    };
}
