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
    date: datetime(year: 2025, month: 6, day: 19),
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

== Rust's type system enables powerful optimizations

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
      patch(locate("*x").at(1), ```rs 13 // formerly *x: one fewer load from memory```)
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
  Can use *unchecked operations* to do *low-level manipulations*
  ```rs
  unsafe {
    // Code within this block can effectively
    // bypass some parts of the typechecker.
    ...
  }
  ```

  #v(1.5cm)

  Within ```rs unsafe``` it is *the programmer's responsibility* to check
  - that pointers are non-null
  - that memory is initialized
  - ...
  #place(bottom + right)[
    #cetz-canvas({
      cetz.decorations.brace((0,2), (0,-2), name: "path", stroke: red.darken(30%))
      cetz.draw.content("path", anchor: "west", padding: 1cm)[
        #text(fill: red.darken(30%))[violations trigger UB]
      ]
    })
  ]
]

== Why have Undefined Behavior (UB) in a language?

#slide[
  Code that contains UB can have *any behavior*.

  #v(2cm)

  Relevance for optimizations: \
  allowed to change the behavior of programs that contain UB.

  #v(2cm)
  #pause

  Too little UB $->$ weak optimizations

  Too much UB $->$ hard to write correct programs
]

== What if ```rs unsafe``` code is misused ?

#slide(repeat: 5, self => [
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
        println!("{}", write_both(x, y)); // prints 20
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
    uncover("5", {
      patch(locate("*x").at(1))[```rs 13```]
      patch(locate("// prints 20").at(0))[```rs // prints 13```]
    })
    uncover("4,5", {
      highlight(..locate("*x").at(1))
      highlight(..locate("20").at(1))
    })
  }))
])


== Not the compiler's responsibility

#slide[
  #v(1cm)
  Within ```rs unsafe``` it is *the programmer's responsibility* to check
    - #text(fill: gray)[that pointers are non-null]
    - #text(fill: gray)[that memory is initialized]
    - compliance with aliasing rules#h(-3mm)#box[#super[#strong[#tcolor(red)[#rotate(30deg)[NEW!]]]]]
  #v(3cm)
  #place(right + horizon, dy: -3cm)[
    #cetz-canvas({
      cetz.decorations.brace((0,2), (0,-2), name: "path", stroke: red.darken(30%))
      cetz.draw.content("path", anchor: "west", padding: 1cm)[
        #text(fill: red.darken(30%))[violations trigger UB]
      ]
    })
  ]


  *Tree Borrows (TB):* defines those aliasing rules

  #pause
  #full-slide-overlay[
    === Sounds familiar?

    *Stacked Borrows* has the same purpose, \
    Tree Borrows is its successor.
  ]
]

#section-slide[Stacked Borrows (SB)]

#slide(repeat: 10, self => [
  In safe Rust, the Borrow Checker makes borrows well-bracketed. \
  Stacked Borrows extends the well-bracketedness to ```rs unsafe```.

  #table(columns: (1fr, 1fr), stroke: none)[
    #codebox(cetz-canvas({
      import cetz.draw: *
      let ctx = from-code(```rs
        let mut root = 42;
        let ptr = &raw mut root;
        let x = unsafe { &mut *ptr };
        let y = unsafe { &mut *ptr };
        // inline write_both(x, y):
        *x = 13;
        ```, self: self)
      let (block, uncover, highlight-lines, line-col, locate, start-of) = ctx
      block
      for (idx,i) in (0,1,1,2,3,3,3,5).enumerate() {
        uncover(str(idx + 2), {
          highlight-lines(i)
        })
      }
      uncover("10", {
        highlight-lines(5, color: red)
        content(line-col(6, 15))[#strong[#text(fill: red.transparentize(30%), size: 90pt)[UB!]]]
      })
    }))
    Desired outcome: UB
  ][
    #align(center)[
      #align(center)[
        #cetz-canvas({
          import cetz.draw: *
          let self = utils.merge-dicts(self, config-methods(cover: utils.method-wrapper(hide.with(bounds: true))))
          let (uncover,) = utils.methods(self)
          uncover("2,3", content((0,0.15), anchor: "south", sb-stack[`root`]))
          uncover("4,7", content((0,0), anchor: "south", sb-stack[`root`][`ptr`]))
          uncover("5,6", content((0,0), anchor: "south", sb-stack[`root`][`ptr`][`x`]))
          uncover("8,9,10", content((0,-0.15), anchor: "south", sb-stack[`root`][`ptr`][`y`]))
          rect(stroke: none, (-2,-0.5), (2,4.5))
        })
      ]
      #align(left)[
        #alternatives[][
          - new stack at `root`
        ][
          - #sym.checkmark `root` is at the top
        ][
          - #sym.checkmark `root` is at the top
          - push `ptr`
        ][
          - #sym.checkmark `ptr` is at the top
          - push `x`
        ][
          - pop until `ptr` is at the top
        ][
          - pop until `ptr` is at the top
        ][
          - pop until `ptr` is at the top
          - push `y`
        ][
          - search for `x`
        ][
          #tcolor(red)[Can't use `x` if it is not in the stack]
        ]
      ]
    ]
  ]
])

#slide(repeat: 5, [
  SB was *implemented* in Miri (official interpreter and UB detector) \
  $->$ included in many projects' CI \
  $->$ several bugs detected (e.g. in stdlib)

  #v(1cm)


   #let img(num, dx: 0cm, dy: 0cm, alpha: 0deg, size: 100%) = {
    place(center + horizon, dx: dx, dy: dy,
      rotate(alpha,
        scale(size,
          rect(inset: 0.5pt,
            //hide(
              image("sb-issue-"+str(num)+".png")
            //)
          )
        )
      )
    )
  }

  // Too strict
  #uncover("4-")[
  #img(10, dy: -5.7cm, dx: -6cm, size: 60%)
  #img(8, dy: -4cm, dx: 5cm, size: 60%)
  #img(7, dy: -2.5cm, dx: -8cm, size: 60%)
  #img(3, dy: -0.5cm, dx: 8cm, alpha: 5deg, size: 60%)
  #img(11, dy: 0.6cm, dx: -6.5cm, alpha: 2deg, size: 60%)
  ]

  // Open questions
  #uncover("3-")[
  #img(13, dy: 3.8cm, dx: -7cm, alpha: -3deg, size: 60%)
  #img(9, dy: 2.7cm, dx: 8cm, alpha: 5deg, size: 60%)
  ]

  // Confusing
  #uncover("2-")[
  #img(5, dy: 6.8cm, dx: -3cm, alpha: 2deg, size: 60%)
  #img(4, dy: 5.8cm, dx: 8cm, size: 60%)
  #img(2, dy: 9cm, dx: -6cm, alpha: -2deg, size: 60%)
  #img(1, dy: 9cm, dx: 8cm, alpha: 5deg, size: 60%)
  ]

  #uncover("5-")[
  #full-slide-overlay(dim: false)[
  *Anecdotal evidence supported by data:*
  - analysis of 30 000 libraries
  - 6000+ tests have aliasing UB under Stacked Borrows
  ]
  ]
])

== Tree Borrows allows much more code

#slide[
  Tree Borrows uses a *tree* instead of a stack to track borrows
  #v(2cm)
  Out of 30 000 most downloaded libraries, \
  *$>50%$ fewer tests* with aliasing UB when using Tree Borrows \

  #v(2cm)
  #pause
  fixes known technical limitations of SB, \
  incl. 2-phase borrows, extern types, *pointer offsets*
]

#section-slide[From Stacks to Trees]

#slide(repeat: 9, composer: (15cm, auto), self => [
  #let (uncover,) = utils.methods(self)
  #codebox(cetz-canvas({
    import cetz.draw: *
    let ctx = from-code(```rs
      let mut root = vec!['a','b','c'];
      let x0 = &raw mut root[0];
      let x2 = &raw mut root[2];

      // Scenario 1
      unsafe { *x0.add(1) = 'z'; }
      ```, self: self)
    let (block, uncover, highlight-lines, patch-line) = ctx
    block
    uncover("-4", patch-line(4)[``])
    uncover("-4", patch-line(5)[``])
    uncover("7,8", patch-line(4)[```rs // Scenario 2```])
    uncover("7,8", patch-line(5)[```rs unsafe { *x2.sub(1) = 'z'; }```])
    uncover("9", patch-line(4)[```rs // Scenario 1 or 2```])
    uncover("9", patch-line(5)[```rs unsafe { *??? = 'z'; }```])
    for (i,idxs) in ((0,),(1,),(2,)).enumerate() {
      uncover(i+2, { highlight-lines(..idxs) })
    }
    uncover("5,7", highlight-lines(5, color: red))
    uncover("6,8,9", highlight-lines(5))
  }))
  #uncover("5-")[
  Desired outcome: not UB
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
          content(rel("v"+str(idx)+".center", 0.5, -0.7))[#text(size: 30pt, fill: green.darken(-30%))[`'b'`]]
          content(rel("v"+str(idx)+".center", -0.5, 0.7))[#text(size: 30pt)[`[1]`]]
        }
        uncover("2-", {
          let idx = 0
          rect((3*idx, 0), (3*idx+3, 3), name: "v"+str(idx), fill: white)
          content(rel("v"+str(idx)+".center", 0.5, -0.7))[#text(size: 30pt, fill: green.darken(-30%))[`'a'`]]
          content(rel("v"+str(idx)+".center", -0.5, 0.7))[#text(size: 30pt)[`[0]`]]
        })
        uncover("2-", {
          let idx = 2
          rect((3*idx, 0), (3*idx+3, 3), name: "v"+str(idx), fill: white)
          content(rel("v"+str(idx)+".center", 0.5, -0.7))[#text(size: 30pt, fill: green.darken(-30%))[`'c'`]]
          content(rel("v"+str(idx)+".center", -0.5, 0.7))[#text(size: 30pt)[`[2]`]]
        })
        uncover("5-", {
          let idx = 1
          rect((3*idx, 0), (3*idx+3, 3), name: "v"+str(idx), fill: white)
          content(rel("v"+str(idx)+".center", 0.5, -0.7))[#text(size: 30pt, fill: green.darken(-30%))[`'z'`]]
          content(rel("v"+str(idx)+".center", -0.5, 0.7))[#text(size: 30pt)[`[1]`]]
        })
        line("v0.west", rel((), -1, 0), mark: (start: ">"), name: "ptr_v")
        content("ptr_v.end", anchor: "east", padding: 1mm, name: "v")[`root`]
      })
      uncover("3-", {
        line("v0.south", rel((), 0, -2), mark: (start: ">"), name: "ptr_0")
        content("ptr_0.end", anchor: "north", padding: 1mm, name: "x0")[`x0`]
             })
      uncover("4-", {
        line("v2.south", rel((), 0, -2), mark: (start: ">"), name: "ptr_2")
        content("ptr_2.end", anchor: "north", padding: 1mm, name: "x2")[`x2`]
      })
      uncover("5,6,9", { line("v1.south", "ptr_0.end", mark: (start: ">")) })
      uncover("7,8,9", { line("v1.south", "ptr_2.end", mark: (start: ">")) })

      // Show all the stacks
      uncover("2", {
        content(rel("v0", 0, -6.5))[#sb-stack[`root`]]
      })
      uncover("2-3", {
        content(rel("v2", 0, -6.5))[#sb-stack[`root`]]
      })
      uncover("3-", {
        content(rel("v0", 0, -6))[#sb-stack[`root`][`x0`]]
      })
      uncover("4-", {
        content(rel("v2", 0, -6))[#sb-stack[`root`][`x2`]]
      })
      uncover("2-5,7,9", {
        content(rel("v1", 0, -6.5))[#sb-stack[`root`]]
      })
      uncover("6", {
        content(rel("v1", 0, -6))[#sb-stack[`root`][`x0`]]
      })
      uncover("8", {
        content(rel("v1", 0, -6))[#sb-stack[`root`][`x2`]]
      })

      // Dim the stacks at indexes 0 and 2 when we focus on 1
      uncover("5-", {
        rect(rel("v0", -1.5, -4.5), rel((), 3, -3), fill: white.transparentize(30%), stroke: none)
        rect(rel("v2", -1.5, -4.5), rel((), 3, -3), fill: white.transparentize(30%), stroke: none)
      })

      uncover("9", {
        rect(rel("v1", 0, -4.9), rel((), -1.5, -1), name: "both1")
        rect(rel("v1", 0, -4.9), rel((), 1.5, -1), name: "both2")
        content("both1.center")[```rs x0```]
        content("both2.center")[```rs x2```]
      })
    })
  ]
])

#slide(repeat: 7, composer: (15cm, auto), self => [
  #let (uncover,) = utils.methods(self)
  #codebox(cetz-canvas({
    import cetz.draw: *
    let ctx = from-code(```rs
      let mut root = vec!['a','b','c'];
      let x0 = &raw mut root[0];
      let x2 = &raw mut root[2];

      // Scenario 1
      unsafe { *x0.add(1) = 'z' };
      ```, self: self)
    let (block, uncover, highlight-lines, patch-line) = ctx
    block
    uncover("-5", patch-line(4)[``])
    uncover("-5", patch-line(5)[``])
    uncover("7", patch-line(4)[```rs // Scenario 2```])
    uncover("7", patch-line(5)[```rs unsafe { *x2.sub(1) = 'z'; }```])
    for (i,idxs) in ((0,),(1,),(2,)).enumerate() {
      uncover(i+2, { highlight-lines(..idxs) })
    }
    uncover("6,7", highlight-lines(5))
  }))
  Desired outcome: not UB
], self => [
  #align(center)[
    #cetz-canvas({
      import cetz.draw: *
      let self = utils.merge-dicts(self, config-methods(cover: utils.method-wrapper(hide.with(bounds: true))))
      let (uncover,) = utils.methods(self)
      uncover("2-", {
        for idx in range(3) {
          rect((3*idx, 0), (3*idx+3, 3), name: "v"+str(idx))
        }
        uncover("2-", {
          let idx = 1
          rect((3*idx, 0), (3*idx+3, 3), name: "v"+str(idx), fill: white)
          content(rel("v"+str(idx)+".center", 0.5, -0.7))[#text(size: 30pt, fill: green.darken(-30%))[`'b'`]]
          content(rel("v"+str(idx)+".center", -0.5, 0.7))[#text(size: 30pt)[`[1]`]]
        })
        uncover("2-", {
          let idx = 0
          rect((3*idx, 0), (3*idx+3, 3), name: "v"+str(idx), fill: white)
          content(rel("v"+str(idx)+".center", 0.5, -0.7))[#text(size: 30pt, fill: green.darken(-30%))[`'a'`]]
          content(rel("v"+str(idx)+".center", -0.5, 0.7))[#text(size: 30pt)[`[0]`]]
        })
        uncover("2-", {
          let idx = 2
          rect((3*idx, 0), (3*idx+3, 3), name: "v"+str(idx), fill: white)
          content(rel("v"+str(idx)+".center", 0.5, -0.7))[#text(size: 30pt, fill: green.darken(-30%))[`'c'`]]
          content(rel("v"+str(idx)+".center", -0.5, 0.7))[#text(size: 30pt)[`[2]`]]
        })
        uncover("6-", {
          let idx = 1
          rect((3*idx, 0), (3*idx+3, 3), name: "v"+str(idx), fill: white)
          content(rel("v"+str(idx)+".center", 0.5, -0.7))[#text(size: 30pt, fill: green.darken(-30%))[`'z'`]]
          content(rel("v"+str(idx)+".center", -0.5, 0.7))[#text(size: 30pt)[`[1]`]]
        })
        line("v0.west", rel((), -1, 0), mark: (start: ">"), name: "ptr_v")
        content("ptr_v.end", anchor: "east", padding: 1mm, name: "v")[`root`]
      })
      uncover("3-", {
        line("v0.south", rel((), 0, -2), mark: (start: ">"), name: "ptr_0")
        content("ptr_0.end", anchor: "north", padding: 1mm, name: "x0")[`x0`]
      })
      uncover("4-", {
        line("v2.south", rel((), 0, -2), mark: (start: ">"), name: "ptr_2")
        content("ptr_2.end", anchor: "north", padding: 1mm, name: "x2")[`x2`]
      })
      uncover("6", line("v1.south", "ptr_0.end", mark: (start: ">")))
      uncover("7", line("v1.south", "ptr_2.end", mark: (start: ">")))
    })
    #cetz-canvas({
      import cetz.draw: *
      let self = utils.merge-dicts(self, config-methods(cover: utils.method-wrapper(hide.with(bounds: true))))
      let (uncover,) = utils.methods(self)
      rect(stroke: none, (-6.8,-6), (4,1))
      uncover("2", tb.draw-tree((`root`)))
      uncover("3", tb.draw-tree((`root`, `x0`)))
      let permbox(color, symbol) = {
        textrect(inset: 0pt, width: 7mm, height: 6mm, stroke: none,
          text(size: 28pt, fill: color, symbol)
        )
      }
      let unique = permbox(green)[#sym.checkmark]
      let reserved = permbox(blue)[?]
      let disabled = permbox(red)[#sym.crossmark.heavy]
      uncover("5-", {
        content(rel("tree.0", -1.1, 0), anchor: "south-east", {
          table(columns: 3, align: center + horizon)[#unique][#unique][#unique]
        })
      })
      // Addition of a sibling moves everything
      set-origin((-2,0))
      uncover("4-", tb.draw-tree((`root`, `x0`, `x2`)))
      uncover("5", {
        content(rel("tree.0-0", -1.1, 0), anchor: "south-east", {
          table(columns: 3, align: center + horizon)[#unique][#reserved][#disabled]
        })
      })
      uncover("5", {
        content(rel("tree.0-1", 1.1, 0), anchor: "south-west", {
          table(columns: 3, align: center + horizon)[#disabled][#reserved][#unique]
        })
      })
      uncover("6", {
        content(rel("tree.0-0", -1.1, 0), anchor: "south-east", {
          table(columns: 3, align: center + horizon)[#unique][#unique][#disabled]
        })
      })
      uncover("6", {
        content(rel("tree.0-1", 1.1, 0), anchor: "south-west", {
          table(columns: 3, align: center + horizon)[#disabled][#disabled][#unique]
        })
      })
      uncover("7", {
        content(rel("tree.0-0", -1.1, 0), anchor: "south-east", {
          table(columns: 3, align: center + horizon)[#unique][#disabled][#disabled]
        })
      })
      uncover("7", {
        content(rel("tree.0-1", 1.1, 0), anchor: "south-west", {
          table(columns: 3, align: center + horizon)[#disabled][#unique][#unique]
        })
      })
    })
  ]
])


== A second look at the motivating example

#slide(repeat: 7, self => [
    #codebox(cetz-canvas({
      import cetz.draw: *
      let ctx = from-code(```rs
        let mut root = 42;
        let ptr = &raw mut root;
        let x = unsafe { &mut *ptr };
        let y = unsafe { &mut *ptr };
        // inline write_both(x, y):
        *x = 13;
        *y = 20;
        ```, self: self)
      let (block, uncover, highlight-lines, line-col, locate, start-of) = ctx
      block
      for (idx,i) in (0,1,2,3,5).enumerate() {
        uncover(str(idx + 2), {
          highlight-lines(i)
        })
      }
      uncover("7", {
        highlight-lines(6, color: red)
        content(line-col(6, 15))[#strong[#text(fill: red.transparentize(30%), size: 90pt)[UB!]]]
      })
    }))
    Desired outcome: UB
], self => [
    #cetz-canvas({
      import cetz.draw: *
      let self = utils.merge-dicts(self, config-methods(cover: utils.method-wrapper(hide.with(bounds: true))))
      let (uncover,) = utils.methods(self)
      rect(stroke: none, (-6.8,-6), (4,1))

      let permbox(color, symbol) = {
        textrect(inset: 0pt, width: 7mm, height: 6mm, stroke: none,
          text(size: 28pt, fill: color, symbol)
        )
      }
      let unique = permbox(green)[#sym.checkmark]
      let reserved = permbox(blue)[?]
      let disabled = permbox(red)[#sym.crossmark.heavy]

      uncover("2", tb.draw-tree((`root`)))
      uncover("3", tb.draw-tree((`root`, `ptr`)))
      uncover("4", tb.draw-tree((`root`, (`ptr`, `x`))))

      uncover("2-", {
        content(rel("tree.0", -1.1, 0), anchor: "south-east", {
          table(columns: 1, align: center + horizon)[#unique]
        })
      })
      uncover("3-5", {
        content(rel("tree.0-0", -1.1, 0), anchor: "south-east", {
          table(columns: 1, align: center + horizon)[#reserved]
        })
      })
      uncover("4", {
        content(rel("tree.0-0-0", -1.1, 0), anchor: "south-east", {
          table(columns: 1, align: center + horizon)[#reserved]
        })
      })

      set-origin((-2,0))
      uncover("5-", tb.draw-tree((`root`, (`ptr`, `x`, `y`))))
      uncover("5", {
        content(rel("tree.0-0-0", -1.1, 0), anchor: "south-east", {
          table(columns: 1, align: center + horizon)[#reserved]
        })
        content(rel("tree.0-0-1", 1.1, 0), anchor: "south-west", {
          table(columns: 1, align: center + horizon)[#reserved]
        })
      })
      uncover("6,7", {
        content(rel("tree.0-0", -1.1, 0), anchor: "south-east", {
          table(columns: 1, align: center + horizon)[#unique]
        })
        content(rel("tree.0-0-0", -1.1, 0), anchor: "south-east", {
          table(columns: 1, align: center + horizon)[#unique]
        })
        content(rel("tree.0-0-1", 1.1, 0), anchor: "south-west", {
          table(columns: 1, align: center + horizon)[#disabled]
        })
      })
    })

])

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
    )
    ...
]

== It should be possible to write ```rs unsafe``` code free of UB

#slide[
  i.e. UB should be predictable and not too common
  #v(1cm)

  *50% fewer tests have aliasing UB according to Tree Borrows* \
  Only 31 ($<0.01%$) tests are regressions, all easily fixable. \
  (Out of 30 000 libraries, 400 000+ working tests)

  #v(1cm)


  #text(fill: gray.darken(30%))[
  _"Tree Borrows accepts more real-world programs that
  call foreign functions than Stacked Borrows due to differences
  in handling pointer arithmetic."_ \
  #text(size: 20pt)[
  A Study of Undefined Behavior Across Foreign Function Boundaries in Rust Libraries,
  by I. McCormack, J. Sunshine, J. Aldrich
  \@ ICSE'25
  ]
  ]

]

#focus-slide[Conclusion]

==

#slide[
  #let shorturl = "play.rust-lang.org"
  #let longurl = "https://play.rust-lang.org/?version=stable&mode=debug&edition=2024&gist=b2b0cb067b73b987f071fe90e10d06bf"
  *Try it out: available in Miri* \ \
  Rust Playground supports TB \
  (#text(size: 24pt)[#raw(shorturl)])
  #image("playground.png", width: 11cm)
  #place(right + horizon)[#line(start: (100%, 0%), end: (100%, 100%), stroke: gray)]
][
  #let url = "plf.inf.ethz.ch/research/pldi25-tree-borrows.html"
  *Learn more:*
  #table(columns: (70%, auto), align: horizon, stroke: none)[
    #text(size: 20pt)[#raw(url)]
  ][
    #qr-code(url, width: 100%)
  ]

  #line(length: 100%, stroke: gray)

  #v(5mm)
  *Get involved:*
  #v(5mm)
  Postdoc positions available \
  #text(size: 20pt)[
    \@ ETH Zurich #h(1cm) #raw("ralf.jung" + "@inf.ethz.ch") \
    \@ MPI-SWS #h(1cm) #raw("dreyer" + "@mpi-sws.org")
  ]
]

