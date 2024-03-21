#! /usr/bin/env bash

SOURCE=assets/main.typ
TARGET=build/main.pdf

pdfview() { zathura "$1"; }
terminal() { alacritty --command "$@"; }
typstc() { typst $1 "$SOURCE" "$TARGET"; }

print_help() {
    echo "USAGE:"
    echo "       $0 watch               run typst watch           (alias 'w')"
    echo "       $0 compile             run typst compile         (alias 'c')"
    echo "       $0 zathura             open beamer with viewer   (alias 'z')"
    echo "       $0 help                print help message        (alias 'h')"
    echo "       $0 edit                open with text editor     (alias 'e')"
}


if [ -z $1 ]; then
    ("")
    echo "No command provided.";
    print_help;
    exit 1;
fi

while true; do
    case $1 in
        ("") exit 0;;
        ("zathura"|"z")
            typstc compile;
            pdfview $TARGET &
            ;;
        ("watch"|"w")
            typstc watch
            ;;
        ("edit"|"e")
            terminal "$EDITOR" -- "$PWD/$SOURCE" &
            ;;
        ("compile"|"c")
            typstc compile;
            ;;
        ("help"|"h")
            print_help;
            exit 0;
            ;;
        (*) echo "Invalid command $1";
            print_help;
            exit 1;
            ;;
    esac
    shift
done
