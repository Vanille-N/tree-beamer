# Beamer for Tree Borrows

by Neven Villani

Slides and sources for the presentation of Tree Borrows at the
[RFMIG](https://www.eventbrite.com/o/rust-formal-methods-interest-group-34404947509)
(_Rust Formal Methods Interest Group_) session of Monday, May 29th 2023 (7PM CEST).


## Pre-rendered PDF

A PDF version of the slides can be downloaded from
[my homepage](https://perso.crans.org/vanille/share/satge/arpe/rfmig.pdf),
but it is not guaranteed to be up to date with recent changes to the source
code.

It also does not include executable examples (see `demo/`).


## Building from source

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


## Contents

- Figures and graphs are in `img/`.
- LaTeX sources for the slides in `src/`
    * `main.tex` is the root file,
    * `head-*` are header files,
    * `rustlistings.sty` is a syntax highlighter for Rust code listings provided by Ralf Jung
    * actual contents of the presentation are in `intro.tex`, `structure.tex`,
      `rules.tex`, `opts.tex`, `evaluation.tex`.
- Executable examples:
    * `demo` illustrates an example of UB shown in the talk.
        See details in the documentation and README of `demo`.


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
