let
  keymap = "ryoppippi";
  mkTarget = keyboard: keymapDir: {
    inherit keyboard keymap keymapDir;
    hexName = "${builtins.replaceStrings [ "/" ] [ "_" ] keyboard}_${keymap}.hex";
  };
in
{
  _module.args.targets = {
    claw44 = mkTarget "dailycraft/claw44/rev1" "keyboards/dailycraft/claw44/keymaps/${keymap}";
    wings42 = mkTarget "dailycraft/wings42/rev2" "keyboards/dailycraft/wings42/keymaps/${keymap}";
  };
}
