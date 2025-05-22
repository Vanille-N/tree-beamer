#import "@preview/touying:0.6.1": *
#import "@preview/cetz:0.3.2"
#import "lib.typ": *
#import "tb.typ"
#import themes.university: *

#set text(font: "Inria Sans")

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

// Notes
//
// Start with code (concrete)
// Slide 3: unsafe more prominent, be clear that unsafe is the issue
// Consider choosing examples from the intro of the paper
// SB examples are a little too complex... should SB be mentioned this early ?
//    This is the gap, it's important to talk about SB's issues.
// A slide on the positive impact of SB (impl in miri, included in CI, detect bugs)
//    Then overview of the main complaints.
//
// "Design constraints" goes right before the evaluation section
//    Reverse the causality:
//      - we want optimizations => enough UB => proof
//      - we want libraries => enough accepted code => crater
//
// Smoother transition to explaining the relationships
//   Right after motivating the tree
//   pick a concrete example
//
// To introduce the state machine, go through an example step by step.
//    Example 6 from the paper.
//
// Raw pointers nope.
//
// At some point, explain briefly how we solve SB's three issues (one slide).
//    can't explain all of them, but I'll show one of them in detail.
//    the one that motivates the tree.
//
// Add evaluation
//    It deserves time.
//
// Examples should not need protectors
// Start with Example 1, probably.
//
// Example 5 introduces the tree
// Example 6 introduces the state machine
// Example 7 is 1 again
// Probably no further than that.
//
// TB in the playground
// update the QR code to the paper website.

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

== Strong guarantees for references

#slide[
  #align(center)[
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

  ```rs &mut``` $->$ mutation, no aliasing

  ```rs &``` $->$ aliasing, no mutation
]

== Unfortunately there is ```rs unsafe```

#slide[
  ```rs unsafe``` code can *bypass typechecks* for the purpose
  of implementing low-level manipulations

  ...but what happens when ```rs unsafe``` code violates an invariant
  that optimizations depend on ?
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
        let ptr = addr_of_mut!(root);
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
      highlight-lines(9, 10, color: yellow)
    })
  }))
])


== The optimization is valid, it's the code that's wrong

#slide[
  Tree Borrows enforces aliasing rules by *proof obligations* on ```rs unsafe```.

  Within ```rs unsafe``` blocks you must already guarantee that...
  - pointers are non-null
  - memory is initialized
  - ...
  #pause
  - the reborrows comply with Tree Borrows#h(-3mm)#box[#super[#strong[#tcolor(red)[#rotate(30deg)[NEW!]]]]]


  #meanwhile
  Code that violates these rules is declared *Undefined Behavior*.

  #pause
  #pause
  #full-slide-overlay[
    === Sounds familiar?

    *Stacked Borrows* has the same purpose, \
    Tree Borrows is its successor.
  ]
]

#section-slide[Stacked Borrows]

#slide(repeat: 7, self => [
  Use a *stack* to track permissions of pointers \
  $->$ ensures that borrows are well-bracketed.

  #table(columns: (1fr, 1fr), stroke: none)[
    #codebox(cetz-canvas({
      import cetz.draw: *
      let ctx = from-code(```rs
        let mut root = 42;
        let ptr = addr_of_mut!(root);
        let x = unsafe { &mut *ptr };
        let y = unsafe { &mut *ptr };
        let val = write_both(x, y);
        ```, self: self)
      let (block, uncover, highlight-lines, line-col, locate, start-of) = ctx
      block
      for i in range(5) {
        uncover(str(i+2), {
          highlight-lines(i, color: yellow)
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
  - several bugs detected (stdlib and other libraries)
  - implemented in Miri $->$ included in many projects' CI

  #pause
  *However...*
  - prohibits reordering reads
  - references are restricted to a static range
  - ignores two-phased borrows

  #pause
  #aside[
    === In general

    Stacked Borrows is *too strict*, \
    and has some *unintuitive* rules.
  ]
]

#section-slide[From Stacks to Trees]

#slide(repeat: 3, [
  #codebox(cetz-canvas({
    let ctx = from-code(
      ```rs
      let ptr1 = root.as_ptr();
      let ptr2 = root.as_mut_ptr();
      ```
    )
    let (block, highlight, locate) = ctx
    block
    for loc in locate("root") { highlight(..loc) }
    highlight(..locate("ptr1").at(0))
    highlight(..locate("ptr2").at(0))
  }))

  #table(columns: (1fr, 1fr), stroke: none)[#align(center + bottom)[
    #sb-stack[root][ptr2]
    #uncover("2-")[
      #place[#line(start: (20%, 0%), end: (80%, -20%), stroke: (paint: red, thickness: 3pt))]
      #place[#line(start: (80%, 0%), end: (20%, -20%), stroke: (paint: red, thickness: 3pt))]
    ]
  ]][#align(center + bottom)[
    #uncover("2-")[#sb-stack[root][ptr1][ptr2]]
    #uncover("3")[
      #place[#line(start: (20%, 0%), end: (80%, -30%), stroke: (paint: red, thickness: 3pt))]
      #place[#line(start: (80%, 0%), end: (20%, -30%), stroke: (paint: red, thickness: 3pt))]
    ]
  ]]
], self => [
  #let (uncover,) = utils.methods(self)
  #uncover("3")[
  #placed(center, neutral: true)[
    #cetz-canvas({
      import cetz.draw: *
      rect((-2, 1.5), (6, -4.5), stroke: none)
      cetz.tree.tree((`root`, `ptr1`, `ptr2`),
        spread: 4,
        grow: 3,
        draw-node: (node, ..) => {
          circle((), radius: 1, stroke: black)
          content((), node.content)
        },
        draw-edge: (from, to, ..) => {
          let (a, b) = (from + ".center", to + ".center")
          line((a, 1, b), (b, 1, a))
        }
      )
    })
  ]
  ]
])

== Relative positions in the tree

#slide(repeat: 6, self => [
  #codebox(cetz-canvas({
    import cetz.draw: *
    let ctx = from-code(```rs
      let mut root = 42;
      let ref1 = &mut root;
      let ref2 = &mut *ref1;
      let ref3 = &mut root;
      ```, self: self)
    let (block, highlight, locate, rel-to, start-of, end-of, line-col, uncover, highlight-lines) = ctx
    block
    for i in range(4) {
      uncover(str(i+2), { highlight-lines(i) })
    }
    uncover("6", highlight(..locate("ref1").at(0), color: green))
  }))
], self => [
  #let (alternatives, uncover, only) = utils.methods(self)
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
          arrow-in-tree("tree.0-0", "tree.0-1", name: "cousin")
          content("cousin.mid", anchor: "north-west", padding: 2mm, angle: -30deg)[#tcolor(green)[cousin]]
        })
        uncover("6", {
          circle("tree.0-0", fill: tb.c.child.transparentize(60%))
          circle("tree.0-0-0", fill: tb.c.child.transparentize(60%))
          circle("tree.0", fill: tb.c.foreign.transparentize(60%))
          circle("tree.0-1", fill: tb.c.foreign.transparentize(60%))
          content(rel("tree.0-0-0", 0, -2), anchor: "north-west")[#tcolor(tb.c.child)[child accesses]]
          content(rel("tree.0", 0, 2), anchor: "south")[#tcolor(tb.c.foreign)[foreign accesses]]
        })
      })
    })
  ]
])

#section-slide[The TB state machine]

#slide[
  #codebox(
  ```rs
  let mut root = 42;
  let x = &mut root;
  *x += 1;
  root = 0
  ```
  )
]

#slide[
  #cetz-canvas({
    tb.state-machine-normal()
  })
]

#section-slide[Evaluation]

== Design constraints

#slide[
  - Allows optimizations \
    $->$ enough UB to rule out problematic patterns \
    $->$ which optimizations are gained/lost compared to SB?
    #pause
    #tcolor(red)[Mechanized proof of optimizations (Rocq + Simuliris)]

  #meanwhile
  - Convenient for library writers \
    $->$ intuitive rules \
    $->$ permissive of standard patterns \
    #pause
    #tcolor(red)[Implementation in Miri] \
    #tcolor(red)[Execute top libraries of `crates.io`] \
    #tcolor(red)[Community feedback]
]

== Empirical evaluation

#slide[
  "How much less UB is there in Tree Borrows
  compared to Stacked Borrows?"

  #pause
  We must
  - count cases of UB that are specifically due to TB/SB
  - only among crates that actually work

  #pause
  Solution
  - 3 Miri runs
    - Filter
    - Stacked Borrows
    - Tree Borrows
]

== Interpretation

#slide[
  #let diamond(upper: [], left: (), right: (), inner: ()) = {
    let fill-cells = (:)
    let inner_rot = ()
    for (i, line) in inner.enumerate() {
      let line_rot = ()
      for (j, cell) in line.enumerate() {
        let (fill, content) = cell
        fill-cells.insert(str(i)+"_"+str(j), fill)
        line_rot.push(
          rotate(-45deg, reflow: true, content)
        )
      }
      inner_rot.push(line_rot)
    }
    let right_rot = right.map(x => rotate(-90deg, reflow: true, x))
    rotate(45deg, reflow: true,
      table(
        fill: (x,y) => {
          let true-x = x + if right.len() > 0 { -1 } else { 0 }
          let true-y = y + if left.len() > 0 { -1 } else { 0 }
          fill-cells.at(str(true-y)+"_"+str(true-x), default: none)
        },
        inset: 1mm,
        align: center + horizon,
        columns: right.len() + 1,
        ..{
          if right_rot.len() > 0 {
            (rotate(-45deg, reflow: true, upper), ..right_rot)
          } else {
            ()
          }
        },
        ..{
          if left.len() > 0 {
            left.zip(inner_rot).flatten()
          } else {
            inner_rot.flatten()
          }
        }
      )
    )
  }

  #let regress(t) = (fill: red.darken(-30%), content: t)
  #let progress(t) = (fill: green.darken(-30%), content: t)
  #let same = (fill: gray.darken(-50%), content: [=])
  #let bad = (fill: gray, content: [$bot$])

  #v(-1cm)
  #diamond(
    upper: [TB | SB],
    right: ([Crash], [UB], [Bor], [Time], [Pass]),
    left: ([Crash], [UB], [Bor], [Time], [Pass]),
    inner: (
      (same, bad, bad, bad, bad),
      (bad, same, bad, bad, bad),
      (bad, bad, same, progress[time], regress[bor]),
      (bad, bad, regress[time], same, regress[time]),
      (bad, bad, progress[bor], progress[time], same)
    ),
  )
  #place(top + right)[
    #align(left)[
    #box(diamond(inner: ((same,),))) Status quo \
    #box(diamond(inner: ((bad,),))) Unexploitable \
    #box(diamond(inner: ((regress[X],),))) Regressions \
    #box(diamond(inner: ((progress[X],),))) Improvements
    ]
  ]
]

== Results over 10 000 top crates (674 748 tests)

#slide[
  - Borrow
    - regressions: 31 ($<1%$)
    - borrow improvements: 3564 of 6568 ($54%$)
  Overall: $-54%$\
  *Fixes more than half of cases of borrowing UB*

  #pause
  - Time
    - regressions: 438
    - improvements: 51
  Overall: $+0.5%$\
  *Ongoing work on performance*
]


/*
#focus-slide[
  First example contains UB
]

#let Rejected = box(text(fill: red)[*UB*], stroke: red, inset: 7pt)

#slide[
  #grid(
    columns: (55%, 45%),
    layout[
      #grid(
        columns: (30%, 70%),
        layout[
          #let executing-loc(i, content) = cetz.canvas({
            import cetz.draw: *
            let y = 1 - 0.86 * i
            line((0, y), (1, y), name: "line", mark: (end: "o"))
            let inner = text(size: 20pt)[#content]
            content((rel: (-0.2, 0), to: "line.start"), anchor: "east")[#inner]
          })
          #alternatives(repeat-last: true)[
                      ][#executing-loc(0, [Alloc `X`])
                      ][#executing-loc(1, [Borrow `y`])
                      ][#executing-loc(2, [Read `y`])
                      ][#executing-loc(3, [Write `y`])
                      ][#executing-loc(4, [Read `X`])
                      ][#executing-loc(5, [Write `y`])
                      ]
        ],
        layout[#text(size: 22pt)[
        #alternatives(repeat-last: true)[```rs
          static mut X = 0;
          let y = &mut X;
          let val = *y;
          *y = 42;
          print!(X); // read access violates uniqueness of y
          *y = val;

          ```
        ][```rs
          static mut X = 0;
          let y = &mut X;
          let val = *y;
          *y = 42;
          print!(X);
          *y = val;

          ```
        ]]]
      )

      #let previous-state(anchor, content) = {
        import cetz.draw: *
        let content = text(fill: gray.darken(30%), size: 13pt)[old: #content]
        content((rel: (1, 0.5), to: "tags." + anchor), anchor: "south-west")[#content]
      }
      #let current-state(anchor, content) = {
        import cetz.draw: *
        content((rel: (0.8, -0.1), to: "tags." + anchor), anchor: "north-west")[#content]
      }
      #let accessed-tag(anchor, content) = {
        import cetz.draw: *
        content((rel: (-4, 0.1), to: "tags." + anchor), anchor: "south-west")[#content]
        line((rel: (-4, -0.1), to: "tags." + anchor),
                  (rel: (-1, -0.1), to: "tags." + anchor), mark: (end: "o"))
      }
      #let transition-summary(anchor, content, ..style) = {
        import cetz.draw: *
        let text-color = style.named().at("text-color", default: gray)
        let content = text(fill: text-color, size: 13pt)[#content]
        content((rel: (1.7, 0), to: "tags." + anchor), anchor: "south-west")[#content]
      }
      #let bounding-box = rect-if-show-layout(
        (rel: (-6.2, -2.8), to: "tags.0"),
        (rel: (4.5, 0.8), to: "tags.0")
      )

      #v(2em)

      #scale(130%)[
      #alternatives(repeat-last: true)[][#align(top + right)[#cetz.canvas({
        tb.draw-tree(
          (
            `X`,
          )
        )
        //current-state("0")[`Active`]
        //accessed-tag("0")[Alloc]
        //transition-summary("0", text-color: alloc_color)[new]
        bounding-box
      })]][#align(top + right)[#cetz.canvas({
        tb.draw-tree(
          (
            `X`,
              `y`
          )
        )
        //previous-state("0")[Active]
        //current-state("0")[`Active`]
        //current-state("0-0")[`Reserved`]
        //accessed-tag("0-0")[Borrow]
        //transition-summary("0", text-color: child_color)[$arrow.b$child read]
        //transition-summary("0-0", text-color: alloc_color)[new]
        bounding-box
      })]][#align(top + right)[#cetz.canvas({
        tb.draw-tree(
          (
            `X`,
              `y`
          )
        )
        //previous-state("0")[Active]
        //previous-state("0-0")[Reserved]
        //current-state("0")[`Active`]
        //current-state("0-0")[`Reserved`]
        //accessed-tag("0-0")[Read]
        //transition-summary("0", text-color: child_color)[$arrow.b$child read]
        //transition-summary("0-0", text-color: child_color)[$arrow.b$child read]
        bounding-box
      })]][#align(top + right)[#cetz.canvas({
        tb.draw-tree(
          (
            (content: [`X`], rel: ""),
              (content: [`y`], rel: ""),
          )
        )
        //previous-state("0")[Active]
        //previous-state("0-0")[Reserved]
        //current-state("0")[`Active`]
        //current-state("0-0")[`Active`]
        //accessed-tag("0-0")[Write]
        //transition-summary("0", text-color: child_color)[$arrow.b$child write]
        //transition-summary("0-0", text-color: child_color)[$arrow.b$child write]
        bounding-box
      })]][#align(top + right)[#cetz.canvas({
        tb.draw-tree(
          (
            (content: [`X`], rel: ""),
              (content: [`y`], rel: ""),
          )
        )
        previous-state("0")[Active]
        accessed-tag("0")[Read]
        previous-state("0-0")[Active]
        current-state("0")[`Active`]
        current-state("0-0")[`Frozen`]
        transition-summary("0", text-color: child_color)[$arrow.b$child read]
        transition-summary("0-0", text-color: foreign_color)[$arrow.b$foreign read]
        bounding-box
      })]][#align(top + right)[#cetz.canvas({
        tag-tree((node) => draw-node-highlight(standard_color_picker, node),
          (
            (content: [`X`], rel: ""),
              (content: [`y`], rel: ""),
          )
        )
        previous-state("0")[Active]
        previous-state("0-0")[Frozen]
        current-state("0")[`Active`]
        current-state("0-0")[#Rejected]
        accessed-tag("0-0")[Write]
        transition-summary("0", text-color: child_color)[$arrow.b$child write]
        transition-summary("0-0", text-color: child_color)[$arrow.b$child write]
        bounding-box
      })]]]
     ],

     layout[#only((2,3,4,5,6,7,8))[#scale(90%)[#cetz.canvas({state-machine-normal})]]],
  )
  #only(8)[#full-slide-overlay[
    - Exclusively owned ```rs &mut``` is `Active`
    - Transitions from `Active` detect \
      violations of uniqueness
  ]]
]
*/

/*
#slide[
  #align(horizon)[
    *Learn more:* \
    #link("https://perso.crans.org/vanille/treebor")[`https://perso.crans.org/vanille/treebor/`]
    - protectors on function arguments
    - no range restriction on reborrow

    #v(2em)

    *Try it out:* \
    #link("https://github.com/rust-lang/miri")[`https://github.com/rust-lang/miri`]
    - use the flag `-Zmiri-tree-borrows`
    - *test* your unsafe code, *report* any surprises!

    //#place(top + right)[#image("qr-treebor.png", width: 20%)]
    //#place(bottom + right)[#image("qr-miri.png", width: 20%)]
  ]
]
*/


