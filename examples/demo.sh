#! /bin/bash

# Runner for demo
# by Neven Villani

# Run code with Miri + Tree Borrows
cmd_miri_tb() {
    echo "Miri flags: use Tree Borrows"
    echo -e "     \033[1;34m\$ export MIRIFLAGS='-Zmiri-tree-borrows'\033[0m"
    echo ""
    export MIRIFLAGS='-Zmiri-tag-gc=0 -Zmiri-tree-borrows'

    echo "Run in miri"
    echo -e "     \033[1;34m\$ cargo +miri miri test\033[0m"
    echo ""
    cargo +miri miri test
}

# Run code with Miri + Stacked Borrows
cmd_miri_sb() {
    echo "Miri flags: use Stacked Borrows"
    echo -e "     \033[1;34m\$ export MIRIFLAGS=''\033[0m"
    echo ""
    export MIRIFLAGS='-Zmiri-tag-gc=0'

    echo "Run in miri"
    echo -e "     \033[1;34m\$ cargo +miri miri test\033[0m"
    echo ""
    cargo +miri miri test
}

# Run code with Rustc
cmd_test() {
    echo "Run natively"
    echo -e "     \033[1;34m\$ cargo test\033[0m"
    echo ""
    cargo test
}

print_help() {
    echo "Usage: \$ $0 <CMD> [-- <EXTRA>]"
    echo "Available commands for <CMD>:"
    echo "   tb        execute miri with tree borrows"
    echo "   sb        execute miri with stacked borrows"
    echo "   test      execute natively"
    echo ""
    echo "Contents of <EXTRA> are passed at the end"
}

# Main
case "$1" in
    ('test') cmd_test;;
    ('tb') cmd_miri_tb;;
    ('sb') cmd_miri_sb;;
    (*)
        echo "Did not expect argument '$1'"
        print_help
        exit 1
        ;;
esac
