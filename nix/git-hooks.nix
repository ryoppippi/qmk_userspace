{
  perSystem =
    {
      config,
      lib,
      pkgs,
      self',
      ...
    }:
    {
      pre-commit = {
        # Formatting and the drawing are verified by checks.treefmt and
        # checks.keymap-drawing; running the hooks again in a sandbox would
        # only duplicate them.
        check.enable = false;
        settings = {
          package = pkgs.prek;
          hooks = {
            treefmt = {
              enable = true;
              name = "treefmt";
              entry = "${lib.getExe config.treefmt.build.wrapper} --no-cache";
              files = ".*";
              pass_filenames = true;
              priority = 0;
            };
            draw-keymap = {
              enable = true;
              name = "draw-keymap";
              entry = lib.getExe self'.packages.draw-keymap;
              files = "(keymap\\.c|keymap-drawer\\.yaml)$";
              pass_filenames = false;
              priority = 10;
            };
          };
        };
      };
    };
}
