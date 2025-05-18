SOURCE := "assets/main.typ"
TARGET := "build/main.pdf"

mk_build_dir:
    mkdir -p $(dirname {{TARGET}})

typst cmd: mk_build_dir
    typst {{cmd}} {{SOURCE}} {{TARGET}} --root=. --font-path=fonts/

zathura:
    zathura {{TARGET}}

evince:
    evince {{TARGET}}

compile: (typst "compile")
watch: (typst "watch")
