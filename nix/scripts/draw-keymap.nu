# Draws <name>.svg and <name>.pdf from keymap.c with keymap-drawer.
def main [
    output: path = "." # directory to write <name>.svg and <name>.pdf into
    --name: string
    --keyboard: string
    --keymap: string
    --keymap-dir: string # relative to the userspace
] {
    let work = mktemp --directory
    let empty_header = $work | path join empty.h
    touch $empty_header

    # Expand the keymap's own macros without pulling in QMK headers, so
    # keycodes stay readable for keymap-drawer. KEYMAP_DRAWER hides layout
    # macros a keymap defines itself, which keymap-drawer must see by name.
    let source = (
        ^avr-gcc -E -P -DKEYMAP_DRAWER $'-DQMK_KEYBOARD_H="($empty_header)"'
        $'-I(["users" $keymap] | path join)' ($keymap_dir | path join keymap.c)
    )

    # keymap-drawer only understands numeric layers in LT(), so map the layer
    # enum to its indices and reuse its names as titles.
    let layers = $source
    | lines
    | skip until { $in =~ 'enum layer_number' }
    | take until { $in =~ '};' }
    | parse --regex '^\s*_(?<name>[A-Z0-9_]+)'
    | get name
    let keymap_c = $work | path join keymap.c
    $layers
    | enumerate
    | reduce --fold $source {|layer source|
        $source | str replace --all $"\(_($layer.item)," $"\(($layer.index),"
    }
    | save $keymap_c

    # Written as JSON, which keymap-drawer reads as YAML: Nushell's YAML
    # output leaves values such as `=` unquoted.
    let config = $work | path join config.json
    ^keymap dump-config
    | from yaml
    | merge deep --strategy overwrite (open keymap-drawer.yaml)
    | to json
    | save $config

    with-env { HOME: $work } {
        let keymap_json = $work | path join keymap.json
        let info_json = $work | path join info.json
        let keymap_yaml = $work | path join keymap.yaml
        ^qmk c2json --no-cpp -kb $keyboard -km $keymap $keymap_c | save $keymap_json
        # layouts.json describes the keys of a keymap's own layout macro.
        let layouts = $keymap_dir | path join layouts.json
        let extra_layouts = if ($layouts | path exists) { open $layouts } else { {} }
        ^qmk info -kb $keyboard -f json
        | from json
        | merge deep { layouts: $extra_layouts }
        | to json
        | save $info_json
        let titles = $layers | each { str lowercase | str capitalize }
        ^keymap -c $config parse -c 12 -l ...$titles -q $keymap_json | save $keymap_yaml
        ^keymap -c $config draw --qmk-info-json $info_json $keymap_yaml
        | save --force ($output | path join $"($name).svg")
    }

    render-keymap-pdf ($output | path join $"($name).svg") ($output | path join $"($name).pdf")
    rm --recursive $work
}
