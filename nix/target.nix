let
  keyboard = "dailycraft/claw44/rev1";
  keymap = "ryoppippi";
in
{
  _module.args.target = {
    inherit keyboard keymap;
    keymapDir = "keyboards/dailycraft/claw44/keymaps/${keymap}";
    hexName = "${builtins.replaceStrings [ "/" ] [ "_" ] keyboard}_${keymap}.hex";
  };
}
