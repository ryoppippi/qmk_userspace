# Runs a toolchain command after saving its full argv as JSON in $env.RECORDER_LOG.
def --wrapped main [
    tool: string # the command make would have run, such as avr-gcc
    ...args: string
] {
    let real = which $tool | get 0.path
    {
        argv: [$real ...$args]
    }
    | to json --raw
    | save ($env.RECORDER_LOG | path join $"(random uuid).json")
    exec $real ...$args
}
