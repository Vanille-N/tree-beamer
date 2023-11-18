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

A precompiled PDF is not yet available for this branch.
It will soon be on [my homepage](https://perso.crans.org/vanille/share/satge/arpe).

## Building the beamer from source

You can clone this repository and compile from source to have the latest version.
Requires:
- `latexmk` (tested 2023-05-27 with version 4.79)
- `pdflatex` (tested 2023-05-27 with version 3.141592653-2.6-1.40.25)

From the root directory, execute `$ make`.

Source files will be fetched from `src/` into `build/`, compiled locally
inside `build/`, and the beamer `main.pdf` will be moved back to the root directory.
To delete all build artifacts, run either `$ rm -rf build/` or `$ make clean`.
See `Makefile` for details.

If anything fails to compile, feel free to open an issue.

## Running the code examples shown in the talk

All code snippets are in `examples/`, with documentation and miri integration.
See details in the folder's README.

## Contents

- Figures and graphs are in `img/`.
- LaTeX sources for the slides in `src/`
    * `main.tex` is the root file,
    * `head-*` are header files,
    * `rustlistings.sty` is a syntax highlighter for Rust code listings provided by Ralf Jung
    * actual contents of the presentation are in `intro.tex`, `structure.tex`,
      `rules.tex`, `opts.tex`, `evaluation.tex`.
- Executable examples in `examples/`
    * `demo/rw-elim` illustrates the example executed during the talk.
    * for other examples see the `examples/README.md`


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
