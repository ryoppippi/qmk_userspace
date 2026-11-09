# Renders the keymap SVG to PDF with only the given fonts, so the result does
# not depend on what the host has installed.
def main [svg: path, pdf: path, --font-path: path] {
    let work = mktemp --directory
    cp $svg ($work | path join keymap.svg)
    "#set page(width: auto, height: auto, margin: 16pt)\n#image(\"keymap.svg\")\n"
    | save ($work | path join keymap.typ)
    with-env { SOURCE_DATE_EPOCH: "0" } {
        (
            ^typst compile --root $work --font-path $font_path
            --ignore-system-fonts --ignore-embedded-fonts
            ($work | path join keymap.typ) $pdf
        )
    }
    rm --recursive $work
}
