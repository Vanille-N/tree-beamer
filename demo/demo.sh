cargo-miri() {
    echo "Miri flags: use Tree Borrows"
    echo -e "     \033[1;34m\$ export MIRIFLAGS='-Zmiri-tree-borrows'\033[0m"
    echo ""
    export MIRIFLAGS='-Zmiri-tree-borrows'

    echo "Run in miri"
    echo -e "     \033[1;34m\$ cargo +miri miri run\033[0m"
    echo ""
    cargo +miri miri run
}

cargo-run() {
    echo "Run natively"
    echo -e "     \033[1;34m\$ cargo run\033[0m"
    echo ""
    cargo run
}

"$@"
