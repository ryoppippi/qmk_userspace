{
  perSystem =
    { lib, pkgs, ... }:
    {
      # Wraps nix/scripts/<name>.nu like writeShellApplication: dependencies
      # on PATH, plus fixed flags and environment from the flake.
      _module.args.writeNuApplication =
        {
          name,
          runtimeInputs ? [ ],
          flags ? [ ],
          env ? { },
        }:
        pkgs.writers.writeNuBin name {
          makeWrapperArgs =
            lib.optionals (runtimeInputs != [ ]) [
              "--prefix"
              "PATH"
              ":"
              (lib.makeBinPath runtimeInputs)
            ]
            ++ lib.concatMap (flag: [
              "--add-flag"
              flag
            ]) flags
            ++ lib.concatLists (
              lib.mapAttrsToList (key: value: [
                "--set"
                key
                value
              ]) env
            );
        } (builtins.readFile ./scripts/${name}.nu);
    };
}
