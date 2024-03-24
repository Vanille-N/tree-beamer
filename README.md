# Beamer for Tree Borrows

by Neven Villani

Slides and sources for presentations of Tree Borrows.

This branch is specific to the presentation of Tree Borrows to be given
at the Toccata meetup in December 2023 at the LMF. Other branches may
contain material not presented here.

Related:
- [Tree Borrows by Example](https://perso.crans.org/vanille/treebor/)
- [Implementation](https://github.com/rust-lang/miri/tree/master/src/borrow_tracker/tree_borrows)
- [The model in detail](https://github.com/Vanille-N/tree-borrows)


## Pre-rendered PDF

A precompiled PDF for this branch can be found on
[my homepage](https://perso.crans.org/vanille/share/satge/arpe/etaps.pdf).

## Building the beamer from source

You can clone this repository and compile from source to have the latest version.
Requires:
- `typst` (0.10.0, tested 2024-03-24)

From the root directory, execute `$ ./run.sh compile`.

Source files will be fetched from `assets/` and compiled into `build/`.
The resulting pdf is `build/main.pdf`.

If anything fails to compile, feel free to open an issue.


## Related resources

See `literature.bib` for complementary sources, and in particular
- [An example-oriented introduction to Tree Borrows](https://perso.crans.org/vanille/treebor)
- [An in-depth view of the Tree Borrows model](https://github.com/Vanille-N/tree-borrows)


## Licensing

Licensed under Creative Commons CC-BY-SA.
Any distribution or modification of this work is allowed,
in compiled (PDF, executable) form, source code (Rust, TeX, Markdown), or both.
Cite original work, preserve attribution and license, and document changes.

See LICENSE.txt or
[creativecommons.org](https://creativecommons.org/licenses/by-sa/4.0/)
