#import "@preview/touying:0.6.1": *
#import "@preview/cetz:0.3.2"
#import "@preview/cades:0.3.0": qr-code
#import "lib.typ": *
#import "tb.typ"
#import themes.university: *

#let global-font = "Inria Sans"
#set text(font: global-font)

#let cetz-canvas = touying-reducer.with(reduce: cetz.canvas, cover: cetz.draw.hide.with(bounds: true))

#show: university-theme.with(
  aspect-ratio: "16-9",
  config-info(
    title: [Tree Borrows],
    author: [
      #underline[Neven Villani], #footnote[Univ. Grenoble Alpes, Verimag] <ens>
      Johannes Hostert, #footnote[ETH Zurich] <eth>
      Derek Dreyer, #footnote[MPI-SWS] <mpi>
      Ralf Jung @eth
    ],
    date: datetime(year: 2025, month: 6, day: 21),
    institution: [PLDI'25],
  ),
  footer-a: self => {
    [Neven Villani]
  },
  footer-b: self => {
    [Tree Borrows]
  },
  footer-c: self => {
    context utils.slide-counter.display()
  },
)

#let section-slide(title) = focus-slide[
  = #title
]

#title-slide()

#let point-to-code = (mark: (end: ">"), stroke: (paint: orange, thickness: 3pt))
#let annotate-code(t) = text(fill: orange)[#t]

#let sb-stack(..cols) = {
  table(columns: 1, inset: 2.5mm, align: center, ..cols.pos().rev(), [#v(-4.5mm)], [#v(-4.5mm)])
}

#let split(a, b, fraction: 0.5) = table(columns: (fraction * 1fr, (1 - fraction) * 1fr), stroke: none, align: left)[#a][#b]

#let tcolor(c, t) = text(fill: c)[#t]

== A typical optimization

#slide(repeat: 4, self => [
  #codebox(cetz-canvas({
    import cetz.draw: *
    let ctx = from-code(```rs
      fn write_both(x: &mut i32, y: &mut i32) -> i32 {

        *x = 13;

        *y = 20;

        *x

      }
      ```, self: self)
    let (block, locate, patch, uncover, highlight, end-of, start-of, rel-to, line-col) = ctx
    block
    uncover("2-3", {
      // Point to both &mut
      let (mut1, mut2) = locate("&mut i32")
      highlight(..mut1)
      highlight(..mut2)
      let pt1 = rel-to(end-of(mut1), 1, 0)
      let pt2 = rel-to(start-of(mut2), 1, 0)
      let pt = rel-to(pt1, 1, 3)
      line(line-col(..pt), line-col(..pt1, anchor: "north"), ..point-to-code)
      line(line-col(..pt), line-col(..pt2, anchor: "north"), ..point-to-code)
      content(line-col(..pt, anchor: "south"))[#annotate-code[mutable thus disjoint]]
      // Point to *y
      let val = locate("*y").at(0)
      let pt1 = rel-to(end-of(val), 0, 1)
      let pt = rel-to(pt1, 2, 5)
      highlight(..val)
      line(line-col(..pt), line-col(..pt1, anchor: "south-east"), ..point-to-code)
      content(line-col(..pt), anchor: "north-west")[#annotate-code[`*x` is unchanged]]
    })
    uncover("3", {
      // Point to 13
      let val = locate("13").at(0)
      let pt1 = rel-to(end-of(val), 0, 1)
      let pt = rel-to(pt1, 2, 5)
      highlight(..val)
      line(line-col(..pt), line-col(..pt1, anchor: "south-east"), ..point-to-code)
      content(line-col(..pt), anchor: "north-west")[#annotate-code[`*x` has known value]]
            // Point to *x
      let val = locate("*x").at(1)
      let pt1 = rel-to(end-of(val), 0, 1)
      let pt = rel-to(pt1, 2, 5)
      highlight(..val)
      line(line-col(..pt), line-col(..pt1, anchor: "south-east"), ..point-to-code)
      content(line-col(..pt), anchor: "north-west")[#annotate-code[always returns `13`]]
    })
    uncover("4", {
      patch(locate("*x").at(1), ```rs 13```)
    })
  }))
])

== Type-level guarantees for references

#slide[
  #align(center)[
    #scale(150%, reflow: true)[
    #cetz-canvas({
      import cetz.draw: *
      circle((0, 0), radius: 2.5, stroke: (paint: red, thickness: 5pt), name: "circ")
      line("circ.south-west", "circ.north-east", stroke: (paint: red, thickness: 5pt))
      content((0, 0))[
        #align(center)[
        aliasing \
          & \
        mutability
      ]]
    })
    ]
  ]

  #align(center)[
    #scale(130%)[$
      #text[```rs &mut```] & -> #text(font: global-font)[mutation, no aliasing] \
      #text[```rs &```] & -> #text(font: global-font)[aliasing, no mutation]
    $]
  ]
]

== Escape hatch: ```rs unsafe```

#slide[
  ```rs
  unsafe {
    // Code within this block has relaxed typechecking
    ...
  }
  ```

  - can *bypass typechecks*
  - necessary for *low-level manipulations*
  - within ```rs unsafe``` it is *the programmer's responsibility* to check
    - that pointers are non-null
    - that memory is initialized
    - ...

  What if ```rs unsafe``` code violates an invariant required for optimizations ?
]

#slide(repeat: 3, self => [
  #codebox(cetz-canvas({
    let ctx = from-code(```rs
      fn write_both(x: &mut i32, y: &mut i32) -> i32 {
        *x = 13;
        *y = 20;
        *x
      }

      fn main() {
        let mut root = 42;
        let ptr = &raw mut root;
        let x = unsafe { &mut *ptr };
        let y = unsafe { &mut *ptr };
        println!("{}", write_both(x, y));
      }```, self: self)
    let (block, highlight, locate, highlight-lines, uncover, patch) = ctx
    block
    uncover("2", {
      highlight-lines((0,5))
      highlight(..locate("write_both(x, y)").at(0))
    })
    uncover("3", {
      highlight-lines(9, 10)
    })
  }))
])


== The optimization is valid, it's the code that's wrong

#slide[
  - within ```rs unsafe``` it is *the programmer's responsibility* to check
    - that pointers are non-null
    - that memory is initialized
    - ...
    - compliance with Tree Borrows#h(-3mm)#box[#super[#strong[#tcolor(red)[#rotate(30deg)[NEW!]]]]]
  #v(3cm)

  $->$ new *proof obligations* on ```rs unsafe``` blocks \
  $->$ violation of these rules results in *Undefined Behavior*

  #pause
  #full-slide-overlay[
    === Sounds familiar?

    *Stacked Borrows* has the same purpose, \
    Tree Borrows is its successor.
  ]
]

#section-slide[Stacked Borrows]

#slide(repeat: 7, self => [
  A *stack* is a natural way to track reborrows \
  because mutable references are *well-bracketed*.
  

  #table(columns: (1fr, 1fr), stroke: none)[
    #codebox(cetz-canvas({
      import cetz.draw: *
      let ctx = from-code(```rs
        let mut root = 42;
        let ptr = &raw mut root;
        let x = unsafe { &mut *ptr };
        let y = unsafe { &mut *ptr };
        let val = write_both(x, y);
        ```, self: self)
      let (block, uncover, highlight-lines, line-col, locate, start-of) = ctx
      block
      for i in range(5) {
        uncover(str(i+2), {
          highlight-lines(i)
        })
      }
      uncover("7", {
        highlight-lines(4, color: red)
        content(line-col(3, 15))[#strong[#text(fill: red.transparentize(30%), size: 90pt)[UB!]]]
      })
    }))
  ][
    #align(center)[
      #split(fraction: 0.3)[
        #align(center)[
          #sb-stack[
            #uncover("2-")[`root`]
          ][
            #uncover("3-")[`ptr`]
          ][
            #v(6mm)
            #only("4")[#v(-6mm) `x`]
            #only("5-7")[#v(-6mm) `y`]
          ]
        ]
      ][
        #alternatives[][
          - new stack at `root`
        ][
          - pop until `root`
          - push `ptr`
        ][
          - pop until `ptr`
          - push `x`
        ][
          - pop until `ptr`
          - push `y`
        ][
          - search for `x`
          - search for `y`
        ][
          #tcolor(red)[#strong[#tcolor(red)[UB:]] cannot use `x` when it is not in the stack]
        ]
      ]
    ]
  ]
])

#slide[
  SB was *implemented* in Miri \
  $->$ included in many projects' CI \
  $->$ several bugs detected (e.g. in stdlib)

  #pause
  *However...*
  - #alternatives[references have static range][*references have static range*]
  - ignores two-phased borrows
  - prohibits reordering reads
]

#section-slide[From Stacks to Trees]

#slide(repeat: 6, self => [
  #let (uncover,) = utils.methods(self)
  #codebox(cetz-canvas({
    import cetz.draw: *
    let ctx = from-code(```rs
      let mut v = vec![0, 1, 2];
      let x0 = &raw mut v[0];
      let x2 = &raw mut v[2];
      ...
      ```, self: self)
    let (block, uncover, highlight-lines) = ctx
    block
    for i in range(3) {
      uncover(i+2, { highlight-lines(i) })
    }
  }))
  #uncover("5-")[
    What stack at offset `1` ?
    #align(center)[
      #table(columns: 5, stroke: none, inset: 5mm, align: bottom)[
        #sb-stack[`v`]
      ][
        #sb-stack[`v`][`x0`]
      ][
        #sb-stack[`v`][`x0`][`x2`]
      ][
        #sb-stack[`v`][`x2`][`x0`]
      ][
        #sb-stack[`v`][`x2`]
      ]
    ]
    #place(center + horizon, dx: -3mm, dy: -4mm)[
      #line(start: (5%, 40%), end: (70%, 70%), stroke: (paint: red.transparentize(30%), thickness: 5pt))
    ]
    #place(center + horizon, dx: -3mm, dy: -4mm)[
      #line(start: (5%, 70%), end: (70%, 40%), stroke: (paint: red.transparentize(30%), thickness: 5pt))
    ]
  ]
], self => [
  #align(center)[
    #cetz-canvas({
      import cetz.draw: *
      let self = utils.merge-dicts(self, config-methods(cover: utils.method-wrapper(hide.with(bounds: true))))
      let (uncover,) = utils.methods(self)
      uncover("2-", {
        for idx in range(3) {
          rect((3*idx, 0), (3*idx+3, 3), name: "v"+str(idx))
          content("v"+str(idx)+".center")[#text(size: 60pt)[#raw(str(idx))]]
        }
        line("v0.west", rel((), -1, 0), mark: (start: ">"), name: "ptr_v")
        content("ptr_v.end", anchor: "east", padding: 1mm, name: "v")[`v`]
      })
      uncover("3-", {
        line("v0.south", rel((), 0, -1), mark: (start: ">"), name: "ptr_0")
        content("ptr_0.end", anchor: "north", padding: 1mm, name: "x0")[`x0`]
        content(rel("ptr_0", 0, -3))[#sb-stack[`v`][`x0`]]
      })
      uncover("4-", {
        line("v2.south", rel((), 0, -1), mark: (start: ">"), name: "ptr_2")
        content("ptr_2.end", anchor: "north", padding: 1mm, name: "x2")[`x2`]
        content(rel("ptr_2", 0, -3))[#sb-stack[`v`][`x2`]]
      })
      uncover("5-", {
        content(rel("v1", 0, -5))[#text(size: 60pt)[?]]
      })

      uncover("6-", {
        set-origin(rel("v1", -2, 6))
        tb.draw-tree((`v`, `x0`, `x2`))
      })
    })
  ]
])

== Relative positions in the tree

#slide(repeat: 10, self => [
  #codebox(cetz-canvas({
    import cetz.draw: *
    let ctx = from-code(```rs
      let mut root = 42;
      let ref1 = &mut root;
      let ref2 = &mut *ref1;
      let ref3 = &mut root;

      let val = *ref2;
      let val = *ref3;
      *ref1 = 36;
      root = 13;
      ```, self: self)
    let (block, highlight, locate, rel-to, start-of, end-of, line-col, uncover, highlight-lines, patch, patch-line) = ctx
    block
    for i in range(4) {
      uncover(str(i+2), { highlight-lines(i) })
    }
    uncover("6-", highlight(..locate("ref1").at(0), color: green))
    uncover("-6", { patch-line(5)[] })
    uncover("-7", { patch-line(6)[] })
    uncover("-8", { patch-line(7)[] })
    uncover("-9", { patch-line(8)[] })
    uncover("7-", {
      highlight-lines(5, color: tb.c.local)
    })
    uncover("8-", {
      highlight-lines(6, color: tb.c.foreign)
    })
    uncover("9-", {
      highlight-lines(7, color: tb.c.local)
    })
    uncover("10-", {
      highlight-lines(8, color: tb.c.foreign)
    })
  }))
], self => [
  #let (alternatives, uncover, only) = utils.methods(self)
  #uncover("2-")[
  #placed(center, neutral: true)[
    #import cetz.draw: *
    #let bounding-box(orig) = cetz.draw.rect(stroke: none, rel(orig, -5, 3), rel((), 10, -12))
    #let arrow-in-tree(start, end, name: none) = {
      line((start, 1, end), (end, 1, start), stroke: (paint: green, thickness: 3pt, dash: "dashed"), mark: (end: ">"), name: name,)
    }
    #cetz-canvas({
      let self = utils.merge-dicts(self, config-methods(cover: utils.method-wrapper(hide.with(bounds: true))))
      let (uncover,) = utils.methods(self)
      bounding-box((0,0))
      uncover("2", {
        tb.draw-tree((`root`,))
      })
      uncover("3", {
        tb.draw-tree((`root`, `ref1`))
        arrow-in-tree("tree.0-0", "tree.0", name: "parent")
        content("parent.mid", anchor: "east", padding: 2mm)[#tcolor(green)[parent]] 
      })
      uncover("4", {
        tb.draw-tree((`root`, (`ref1`, `ref2`)))
        arrow-in-tree("tree.0-0", "tree.0-0-0", name: "child")
        content("child.mid", anchor: "east", padding: 2mm)[#tcolor(green)[child]]
      })
      uncover("5-", {
        set-origin((-2,0))
        tb.draw-tree((`root`, (`ref1`, `ref2`), `ref3`))
        uncover("5", {
          arrow-in-tree("tree.0-0", "tree.0-1", name: "sibling")
          content("sibling.mid", anchor: "north-west", padding: 2mm, angle: -30deg)[#tcolor(green)[sibling]]
        })
        uncover("6-", {
          circle("tree.0-0", fill: tb.c.local.transparentize(60%))
          circle("tree.0-0-0", fill: tb.c.local.transparentize(60%))
          circle("tree.0", fill: tb.c.foreign.transparentize(60%))
          circle("tree.0-1", fill: tb.c.foreign.transparentize(60%))
          content(rel("tree.0-0-0", 0, -2), anchor: "north-west")[#tcolor(tb.c.local)[local accesses]]
          content(rel("tree.0", 0, 2), anchor: "south")[#tcolor(tb.c.foreign)[foreign accesses]]
        })
      })
    })
  ]
  ]
])

#section-slide[Permissions]

#slide(repeat: 7, self => [
  #let (uncover, alternatives) = utils.methods(self)
  #uncover("2-")[
    #codebox(cetz-canvas({
      let ctx = from-code(```rs
        let mut root = 42;
        let x = &mut root;
        let v = *x;
        *x = v + 1;
        let w = root;
        root = 0
        ```, self: self)
      let (block, uncover, highlight-lines) = ctx
      block
      uncover("3", highlight-lines(0, 1))
      uncover("4", highlight-lines(2, color: tb.c.local))
      uncover("5", highlight-lines(3, color: tb.c.local))
      uncover("6", highlight-lines(4, color: tb.c.foreign))
      uncover("7", highlight-lines(5, color: tb.c.foreign))
    }))
    #uncover("3-")[
      #placed(right, neutral: true)[
        #cetz-canvas({
          import cetz.draw: *
          tb.draw-tree((`root`, `x`))
          circle("tree.0-0", fill: tb.c.local.transparentize(60%))
          circle("tree.0", fill: tb.c.foreign.transparentize(60%))
        })
      ]
    ]
    #alternatives[][][`x`: Reserved (r/w)][`x`: Reserved (r/w)][`x`: Unique (r/w)][`x`: Frozen (r)][`x`: Disabled]
  ]
], self => [
  #align(center)[
    #cetz-canvas({
      tb.state-machine-normal()
    })
  ]
])

== Addressing Stacked Borrows' limitations

#slide[
  - references have static range \
    #tcolor(red)[$->$ tree structure]
  - ignores two-phased borrows \
    #tcolor(red)[$->$ Reserved]
  - prohibits reordering reads \
    #tcolor(red)[$->$ Frozen]
][
  #align(center)[
    #cetz-canvas({
      tb.state-machine-normal()
    })
  ]
]


#section-slide[Evaluation]

== TB should enable desired optimizations

#slide[
  i.e. have enough UB to rule out problematic patterns

  #v(1cm)

  - formalized in Rocq (+Simuliris)
  - a selection of optimizations proven
    #list(marker: $checkmark$,
      [delete read through ```rs &mut``` or ```rs &```],
      [insert read through ```rs &``` in function],
      [move read down for ```rs &mut``` or ```rs &``` in function],
      [move write up for Unique ```rs &mut``` in function],
    )
    ...
]

== It should be possible to write ```rs unsafe``` code free of UB

#slide[
  i.e. UB should be predictable and not too common
  #v(1cm)

  - implemented in Miri
  - tested against 30 000 most downloaded crates on `crates.io`
    - 400 000+ working tests
    - measure how many have UB from Stacked / Tree Borrows

  #pause
  #v(1.5cm)

  *Tree Borrows reduces aliasing-related UB by over 50%*

  Only 31 tests are regressions, all easily fixable.
]

#focus-slide[Conclusion]

==

#slide[
  #let shorturl = "play.rust-lang.org"
  #let longurl = "https://play.rust-lang.org/?version=stable&mode=debug&edition=2024&gist=b2b0cb067b73b987f071fe90e10d06bf"
  *Try it out:* #text(size: 24pt)[#raw(shorturl)]
  #image("playground.png")
  #v(5cm)
  #place(bottom + left)[#qr-code(longurl, width: 30%)]
][
  #let url = "plf.inf.ethz.ch/research/pldi25-tree-borrows.html"
  *Learn more:* \ #text(size: 24pt)[#raw(url)]
  - dynamic ranges
  - raw pointers
  - interior mutability
  #v(5cm)
  #place(bottom + right)[#qr-code(url, width: 30%)]
]

