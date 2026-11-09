# Compiles keymap.c against the objects from build-objects and links the
# firmware, replaying the commands QMK's make used.
def main [
    keymap: path # keymap.c
    hex: path # where to write the firmware
    --objects: path # the qmk-objects store path
] {
    let commands = open ($objects | path join commands.json)
    let work = mktemp --directory
    let retarget = {|argv|
        $argv
        | str replace --all $commands.introspection ($work | path join keymap_introspection)
        | str replace --all $commands.elf ($work | path join firmware)
    }

    cd $commands.directory
    let compile = do $retarget $commands.compile
    run-external ...$compile "-UKEYMAP_C" $'-DKEYMAP_C="($keymap)"'
    run-external ...(do $retarget $commands.link)
    run-external ...(do $retarget $commands.objcopy)

    let firmware = $work | path join firmware.hex
    let size = ^avr-size --target=ihex $firmware | detect columns | get 0.dec | into int
    print $"firmware size: ($size)/($commands.max_size)"
    if $size > $commands.max_size {
        error make {msg: "the firmware is too large"}
    }
    mkdir ($hex | path dirname)
    cp $firmware $hex
    rm --recursive $work
}
