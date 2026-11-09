# Builds QMK's objects against a stub keymap.c and records the commands that
# compile and link the keymap, so later builds can skip QMK's make.
def main [
    output: path # becomes the qmk-objects store path
    --qmk-home: path
    --keyboard: string
    --keymap: string
    --keymap-dir: string # relative to the userspace
    --jobs: int = 1
] {
    let name = $"($keyboard | str replace --all '/' '_')_($keymap)"
    let userspace = $output | path join userspace
    let build = $output | path join build
    let objects = $build | path join $"obj_($name)"
    let log = mktemp --directory

    mkdir $output
    cp --recursive . $userspace
    "#include QMK_KEYBOARD_H\nconst uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {{{0}}};\n"
    | save ($userspace | path join $keymap_dir keymap.c)

    with-env { HOME: (mktemp --directory) RECORDER_LOG: $log } {
        (
            ^make -C $qmk_home $"($keyboard):($keymap)"
            $"QMK_USERSPACE=($userspace)" $"BUILD_DIR=($build)" SKIP_GIT=yes $"-j($jobs)"
            CC_PREFIX=record "OBJCOPY=record avr-objcopy"
        ) o+e>| tee { save ($log | path join make.txt) }
    }

    let calls = glob ($log | path join '*.json') | each { open $in | get argv }
    let introspection = $objects | path join quantum keymap_introspection
    let elf = $build | path join $name
    let is_link = {|argv| ($argv | first | str ends-with avr-gcc) and ($"($elf).elf" in $argv) }
    let is_objcopy = {|argv| ($argv | first | str ends-with avr-objcopy) and ("ihex" in $argv) }
    let max_size = open ($log | path join make.txt)
    | parse --regex 'The firmware size is fine - \d+/(?<max>\d+)'
    | get 0.max
    | into int

    {
        directory: $qmk_home
        introspection: $introspection
        elf: $elf
        compile: (pick compile $calls { "quantum/keymap_introspection.c" in $in })
        link: (pick link $calls $is_link)
        objcopy: (pick objcopy $calls $is_objcopy)
        max_size: $max_size
    }
    | save ($output | path join commands.json)

    [
        $"($elf).*"
        $"($introspection).*"
        ($userspace | path join '*.hex')
    ]
    | each { glob $in }
    | flatten
    | each { rm $in }
    | ignore
}

# The one recorded call matching the predicate.
def pick [step: string, calls: list<list<string>>, predicate: closure]: nothing -> list<string> {
    let matches = $calls | where $predicate
    if ($matches | length) != 1 {
        error make {msg: $"expected one ($step) call from make, found ($matches | length)"}
    }
    $matches | first
}
