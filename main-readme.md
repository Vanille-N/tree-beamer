# Beamer for Tree Borrows

Slides and sources for presentations of Tree Borrows.

Written by Neven Villani.

With feedback from Johannes Hostert, Derek Dreyer, Ralf Jung, and various spectators.

---

**You are reading the most recent version**

This branch is specific to the presentation of Tree Borrows
that was given at PLDI in Seoul (June 2025).
Other branches may contain material not presented here.

You may also consult
- the now published [paper](https://dl.acm.org/doi/10.1145/3735592),
- the [livestream](https://www.youtube.com/live/YhXlZp45HLs?si=_ZMYNXK2WRwJRLuJ&t=21467)
  of this presentation (around 5:57:00),
- a written [explanation](https://perso.crans.org/vanille/treebor/) of Tree Borrows,
- a [precompiled](https://perso.crans.org/vanille/share/satge/arpe/pldi.pdf)
  version of this beamer.

---

## Building the beamer from source

You can clone this repository and compile from source to have the latest version.
Requires:
- a recent version of `typst` (tested on 2025-06-18 with typst 0.13.1)

From the root directory, execute the following:
```
$ typst compile assets/main.typ build/main.pdf  --root=. --font-path=fonts/`.
```

Source files will be fetched from `assets/` and compiled into `build/`.
The resulting pdf is `build/main.pdf`.

If anything fails to compile, feel free to open an issue.

## Licensing

Licensed under Creative Commons CC-BY-SA.
Any distribution or modification of this work is allowed,
in compiled (PDF, executable) form, source code (Rust, TeX, Markdown, Typst), or both.
Cite original work, preserve attribution and license, and document changes.

See LICENSE.txt or [creativecommons.org](https://creativecommons.org/licenses/by-sa/4.0/)
