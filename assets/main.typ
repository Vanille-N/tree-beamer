#import "@preview/touying:0.6.1": *
#import "@preview/cetz:0.3.2"
#import "lib.typ": *
#import themes.university: *

#set text(font: "Inria Sans")

#let cetz-canvas = touying-reducer.with(reduce: cetz.canvas, cover: cetz.draw.hide.with(bounds: true))
#show: university-theme.with(
  aspect-ratio: "16-9",
  config-info(
    title: text(size: 39pt)[Verifying Parameterized Networks \
                            #text(size: 28pt)[Specified by] \
                            Vertex-Replacement Graph Grammars],
    author: [#underline[Neven Villani], Radu Iosif, Arnaud Sangnier],
    date: [2025-05-21; NETYS (Rabat)],
    institution: [Univ. Grenoble Alpes, Verimag],
  ),
  footer-a: self => [
    Neven Villani
  ],
  footer-b: self => {
    [Parameterized Networks Specified by VR Grammars]
  },
  footer-c: self => {
    context utils.slide-counter.display()
  },
)

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

#slide[
  #codebox(
  ```rs
  fn write_both(x: &mut i32, y: &mut i32) -> i32 {
    *x = 13;
    *y = 20;
    *x
  }
  ```)
]

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
  #codebox(cetz-canvas({
    let ctx = from-code(
      ```rs
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
        let val = write_both(x, y);
        println!("{val}")
      }
      ```
    )
    let (block, highlight, locate) = ctx
    block
    for loc in locate("unsafe") { highlight(..loc) }
  }))
]

== It's not the optimization that is wrong, it's the code

#slide[
  Tree Borrows enforces aliasing rules by adding *proof obligations* to ```rs unsafe``` blocks.

  Code that violates these rules is declared *Undefined Behavior*.

  #pause
  #aside[
    === Sounds familiar?

    *Stacked Borrows* has the same purpose, \
    Tree Borrows is its successor.
  ]
]

#section-slide[Stacked Borrows]

#slide[
  Use a *stack* to track permissions of pointers \
  $->$ ensures that borrows are well-bracketed.

  #table(columns: (1fr, 1fr), stroke: none)[
    #codebox(
      ```rs
      let mut root = 42;
      let ptr = addr_of_mut!(root);
      let x = unsafe { &mut *ptr };
      let y = unsafe { &mut *ptr };
      let val = write_both(x, y);
      ```
    )
  ][
    #align(center)[
      #table(align: center)[
        y / x
      ][
        ptr
      ][
        root
      ]
    ]
  ]
]

#slide[
  - detected several bugs
  - implemented in Miri $->$ included in many projects' CI

  *However...*
  - prohibits reordering reads
  - references are restricted to a static range
  - ignores two-phased borrows

  #aside[
    === In general

    Stacked Borrows is *too strict*, \
    and has some *unintuitive* rules.
  ]
]

#slide[
  #codebox(cetz-canvas({
    let ctx = from-code(
      ```rs

      let from = data.as_ptr();

      let to = data.as_mut_ptr();

      copy_nonoverlapping(from, to.add(1), 1);
      ```
    )
    let (block, highlight, locate) = ctx
    block
    for loc in locate("data") { highlight(..loc) }
    highlight(..locate("from").at(0))
    highlight(..locate("to").at(0))
  }))

  #placed(bottom + right)[
    #cetz-canvas({
      import cetz.draw: *
      rect((-2, 1.5), (6, -4.5), stroke: none)
      cetz.tree.tree((`data`, `from`, `to`),
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
  #pause
  #full-slide-overlay[
    The stack is *too rigid* to represent the exact relationship
  ]
]

== From Stacks to Trees

#slide(repeat: 2, self => [
  #cetz-canvas({
    import cetz.draw: *
    let self = utils.merge-dicts(self, config-methods(cover: utils.method-wrapper(hide.with(bounds: true))))
    let (uncover,) = utils.methods(self)
    let ctx = from-code(
      ```rs
      let mut root = 42;

      let ref1 = &mut root;

      let ref2 = &mut *ref1;

      let ref3 = &mut root;
      ```
    )
    let (block, highlight, locate, rel-to, start-of, end-of, line-col) = ctx
    block

    uncover("2", {
      highlight(..locate("root").at(0), color: green)
      let style = (mark: (end: ">"), stroke: (paint: orange, thickness: 3pt))
      for (from, to) in (
        (locate("ref1").at(0), locate("root").at(1)),
        (locate("ref2").at(0), locate("ref1").at(1)),
        (locate("ref3").at(0), locate("root").at(2))
      ) {
        highlight(..from)
        highlight(..to)
        line(line-col(..end-of(from), anchor: "north-east"),
            line-col(..start-of(to), anchor: "north-west"),
            ..style)
      }
    })
  })
  #placed(bottom + right, neutral: true)[
    #cetz-canvas({
      import cetz.draw: *
      rect((-2, 1.5), (6, -7.5), stroke: none)
      cetz.tree.tree((`root`, (`ref1`, `ref2`), `ref3`),
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
])

==
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

#section-slide[Evaluation]

#slide[
  === Design constraints
  - Allows optimizations \
    $->$ enough UB to rule out problematic patterns

  - Convenient for library writers \
    $->$ intuitive rules \
    $->$ permissive of standard patterns
]

/*

#let tag-tree(draw-node, data, ..style) = {
  let grow = style.named().at("grow", default: 2)
  let spread = style.named().at("spread", default: 2)
  tree.tree(
    data,
    grow: grow,
    spread: spread,
    name: "tags",
    draw-node: (node, ..) => draw-node(node),
    draw-edge: (from, to, ..) => {
      let (a, b) = (from + ".center", to + ".center")
      draw.line((a, 0.8, b), (b, 0.8, a))
    }
  )
}

#let draw-node-default(node) = {
    draw.circle((), radius: 0.8, stroke: black)
    draw.content((), node.content.content)
}
#let draw-node-highlight(check, node) = {
    let color = check(node.content.at("rel", default: ""))
    let fill = if color != none { color } else { white }
    draw.circle((), radius: 0.8, stroke: black, fill: fill)
    draw.content((), node.content.content)
}

#let state(x, y, name, label) = {
  let name = name + "-box"
  draw.rect((x, y), (x+4, y+1), name: name)
  draw.content(name + ".center", anchor: "center", label)
}

#let bezier-between-states(start, end, dir) = {
  let name = "arr-" + start + "-" + end
  let start = start + "-box"
  let end = end + "-box"
  draw.bezier(
    start + "." + dir,
    end + ".north",
    (start + "." + dir, "-|", end + ".north"),
    mark: (end: ">"),
    name: name,
  )
}

#let straight-down(start, end, dir, label, ..style) = {
  let name = "arr-" + start + "-" + end
  let start = start + "-box"
  let end = end + "-box"
  let sign = if dir == "west" { 1 } else { -1 }
  draw.line(
    start + ".south",
    end + ".north",
    mark: (end: ">"),
    name: name,
  )
  let text-color = style.named().at("text-color", default: gray)
  draw.content(
    (rel: (sign * 0.2, 0), to: name + ".mid"),
    anchor: dir,
    text(fill: text-color)[#label]
  )
}
#let self-loop(box, dir, label, ..style) = {
  let name = box + "-loop"
  let box = box + "-box"
  let sign = if dir == "east" { 1 } else { -1 }
  draw.bezier(
    box + "." + dir,
    box + "." + dir,
    (rel: (sign * 1.5, 1.5), to: box + "." + dir),
    (rel: (sign * 1.5, -1.5), to: box + "." + dir),
    name: name,
    mark: (end: ">"),
  )
  let text-color = style.named().at("text-color", default: gray)
  draw.content(
    (rel: (sign * 0.2, 0), to: name + ".mid"),
    anchor: if dir == "east" { "west" } else { "east" },
    text(fill: text-color)[#label]
  )
}

#let state-machine-normal = {
    state(0, 0, "res", `Reserved`)
    state(0, -3, "act", `Active`)
    state(0, -6, "frz", `Frozen`)
    state(3, -9, "dis", `Disabled`)

    bezier-between-states("res", "dis", "east")
    bezier-between-states("act", "dis", "east")
    bezier-between-states("frz", "dis", "east")
    draw.content(
      (rel: (0.7, -1.1), to: "arr-res-dis.ctrl-0"),
      anchor: "center", angle: -60deg,
      text(fill: foreign_color)[foreign write],
    )

    straight-down("res", "act", "east", [child write], text-color: child_color)
    straight-down("act", "frz", "east", [foreign read], text-color: foreign_color)

    self-loop("res", "west", [any read], text-color: mixed_color)
    self-loop("act", "west", [child r/w], text-color: child_color)
    self-loop("frz", "west", [any read], text-color: mixed_color)
    self-loop("dis", "west", [foreign r/w], text-color: foreign_color)
}

==
#slide[
  #align(right)[
    #let marker(to, ldist) = {
      draw.line(
        (rel: (-ldist - 1, 0), to: to + "-box.west"),
        (rel: (-ldist, 0), to: to + "-box.west"),
        mark: (end: "o"),
        name: to + "-line",
      )
    }
    #let rel-to-line(to, rel, anchor) = {
      (rel: rel, to: to + "-line." + anchor)
    }
    #let bounding-box = {
      draw.rect((rel: (5, 2), to: "res-box.center"), (rel: (-22.5, -10), to: "res-box.center"), stroke: none)
    }
    #alternatives[
      #canvas({
        state-machine-normal
        bounding-box
      })
    ][
      #canvas({
        state-machine-normal
        bounding-box
        marker("res", 5)
        marker("act", 5)
        draw.content(rel-to-line("res", (-0.5, 0), "start"), anchor: "east")[`&mut` not yet written to]
        draw.content(rel-to-line("act", (-0.5, 0), "start"), anchor: "east")[`&mut` already written]
        draw.line(
          rel-to-line("res", (-0.1, -0.5), "start"),
          rel-to-line("act", (-0.1, 0.5), "start"),
          mark: (end: ">"),
          name: "transform",
        )
        draw.content((rel: (-0.5, 0), to: "transform.mid"), anchor: "east")[write to it]
      })
    ][
      #canvas({
        state-machine-normal
        bounding-box
        marker("act", 5)
        marker("frz", 5)
        draw.content(rel-to-line("act", (-0.5, 0), "start"), anchor: "east")[exclusive access]
        draw.content(rel-to-line("frz", (-0.5, 0), "start"), anchor: "east")[shared access]
        draw.line(
          rel-to-line("act", (-0.1, -0.5), "start"),
          rel-to-line("frz", (-0.1, 0.5), "start"),
          mark: (end: ">"),
          name: "transform",
        )
        draw.content((rel: (-0.5, 0), to: "transform.mid"), anchor: "east")[other pointer gains access]
      })
    ][
      #canvas({
        state-machine-normal
        bounding-box
        marker("frz", 5)
        draw.content(rel-to-line("frz", (-0.5, 0), "start"), anchor: "east")[shared access]
        draw.bezier(
          (rel: (-0.1, -0.5), to: "frz-line.start"),
          (rel: (0.1, -0.5), to: "frz-line.start"),
          (rel: (-1.5, -2.5), to: "frz-line.start"),
          (rel: (1.5, -2.5), to: "frz-line.start"),
          mark: (end: ">"),
          name: "transform",
        )
        draw.content((rel: (-0.5, 0), to: "transform.mid"), anchor: "east")[any read-only operation]
      })
    ][
      #canvas({
        state-machine-normal
        bounding-box
        marker("frz", 5)
        marker("dis", 8)
        draw.content(rel-to-line("frz", (-0.5, 0), "start"), anchor: "east")[shared access]
        draw.content(rel-to-line("dis", (-0.5, 0), "start"), anchor: "east")[no access]
        draw.line(
          rel-to-line("frz", (-0.1, -0.5), "start"),
          rel-to-line("dis", (-0.1, 0.5), "start"),
          mark: (end: ">"),
          name: "transform",
        )
        draw.content((rel: (-0.5, 0), to: "transform.mid"), anchor: "east")[other pointer gains exclusive access]
      })
    ]
  ]
]

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
          #let executing-loc(i, content) = canvas({
            let y = 1 - 0.86 * i
            rect-if-show-layout((1, 1.3), (-3, -3.8))
            draw.line((0, y), (1, y), name: "line", mark: (end: "o"))
            let content = text(size: 20pt)[#content]
            draw.content((rel: (-0.2, 0), to: "line.start"), anchor: "east")[#content]
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
        let content = text(fill: gray.darken(30%), size: 13pt)[old: #content]
        draw.content((rel: (1, 0.5), to: "tags." + anchor), anchor: "south-west")[#content]
      }
      #let current-state(anchor, content) = {
        draw.content((rel: (0.8, -0.1), to: "tags." + anchor), anchor: "north-west")[#content]
      }
      #let accessed-tag(anchor, content) = {
        draw.content((rel: (-4, 0.1), to: "tags." + anchor), anchor: "south-west")[#content]
        draw.line((rel: (-4, -0.1), to: "tags." + anchor),
                  (rel: (-1, -0.1), to: "tags." + anchor), mark: (end: "o"))
      }
      #let transition-summary(anchor, content, ..style) = {
        let text-color = style.named().at("text-color", default: gray)
        let content = text(fill: text-color, size: 13pt)[#content]
        draw.content((rel: (1.7, 0), to: "tags." + anchor), anchor: "south-west")[#content]
      }
      #let bounding-box = rect-if-show-layout(
        (rel: (-6.2, -2.8), to: "tags.0"),
        (rel: (4.5, 0.8), to: "tags.0")
      )

      #v(2em)

      #scale(130%)[
      #alternatives(repeat-last: true)[][#align(top + right)[#canvas({
        tag-tree((node) => draw-node-highlight((rel) => none, node),
          (
            (content: [`X`], rel: ""),
          )
        )
        current-state("0")[`Active`]
        accessed-tag("0")[Alloc]
        transition-summary("0", text-color: alloc_color)[new]
        bounding-box
      })]][#align(top + right)[#canvas({
        tag-tree((node) => draw-node-highlight((rel) => none, node),
          (
            (content: [`X`], rel: ""),
              (content: [`y`], rel: ""),
          )
        )
        previous-state("0")[Active]
        current-state("0")[`Active`]
        current-state("0-0")[`Reserved`]
        accessed-tag("0-0")[Borrow]
        transition-summary("0", text-color: child_color)[$arrow.b$child read]
        transition-summary("0-0", text-color: alloc_color)[new]
        bounding-box
      })]][#align(top + right)[#canvas({
        tag-tree((node) => draw-node-highlight(standard_color_picker, node),
          (
            (content: [`X`], rel: ""),
              (content: [`y`], rel: ""),
          )
        )
        previous-state("0")[Active]
        previous-state("0-0")[Reserved]
        current-state("0")[`Active`]
        current-state("0-0")[`Reserved`]
        accessed-tag("0-0")[Read]
        transition-summary("0", text-color: child_color)[$arrow.b$child read]
        transition-summary("0-0", text-color: child_color)[$arrow.b$child read]
        bounding-box
      })]][#align(top + right)[#canvas({
        tag-tree((node) => draw-node-highlight(standard_color_picker, node),
          (
            (content: [`X`], rel: ""),
              (content: [`y`], rel: ""),
          )
        )
        previous-state("0")[Active]
        previous-state("0-0")[Reserved]
        current-state("0")[`Active`]
        current-state("0-0")[`Active`]
        accessed-tag("0-0")[Write]
        transition-summary("0", text-color: child_color)[$arrow.b$child write]
        transition-summary("0-0", text-color: child_color)[$arrow.b$child write]
        bounding-box
      })]][#align(top + right)[#canvas({
        tag-tree((node) => draw-node-highlight(standard_color_picker, node),
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
      })]][#align(top + right)[#canvas({
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

     layout[#only((2,3,4,5,6,7,8))[#scale(90%)[#canvas({state-machine-normal})]]],
  )
  #only(8)[#full-slide-overlay[
    - Exclusively owned ```rs &mut``` is `Active`
    - Transitions from `Active` detect \
      violations of uniqueness
  ]]
]

#focus-slide[
  Raw pointers
]

#slide[
  #grid(
    columns: (5%, 60%, 25%),
    layout[],
    layout[
      #grid(
        columns: (30%, 20%),
        [
          #let executing-loc(i, content) = canvas({
            let y = 0.75 - 0.86 * i
            rect-if-show-layout((1, 1), (-3.6, -3))
            draw.line((0, y), (1, y), name: "line", mark: (end: "o"))
            let content = text(size: 20pt)[#content]
            draw.content((rel: (-0.2, 0), to: "line.start"), anchor: "east")[#content]
          })
          #alternatives(repeat-last: true)[
                      ][#executing-loc(0, [Alloc `x`])
                      ][#executing-loc(1, [Raw `r`])
                      ][#executing-loc(2, [Write `x`])
                      ][#executing-loc(3, [Write `r`])
                      ]
        ],
        text(size: 22pt)[
        #alternatives(repeat-last: true)[```rs
          let mut x = 0u64;
          let r = addr_of_mut!(x);
          x = 42; // x and r should be interchangeable
          r.write(50);
          ```
        ][```rs
          let mut x = 0u64;
          let r = addr_of_mut!(x);
          x = 42;
          r.write(50);
          ```
        ]

      ])

      #let previous-state(anchor, content) = {
        let content = text(fill: gray.darken(30%), size: 11pt)[old: #content]
        draw.content((rel: (0.85, 0.4), to: "tags." + anchor), anchor: "south-west")[#content]
      }
      #let current-state(anchor, content) = {
        let content = text(size: 21pt)[#content]
        draw.content((rel: (0.8, -0.1), to: "tags." + anchor), anchor: "north-west")[#content]
      }
      #let accessed-tag(anchor, content) = {
        let content = text(size: 16pt)[#content]
        draw.content((rel: (-3, 0.1), to: "tags." + anchor), anchor: "south-west")[#content]
        draw.line((rel: (-3, -0.1), to: "tags." + anchor),
                  (rel: (-1, -0.1), to: "tags." + anchor), mark: (end: "o"))
      }
      #let transition-summary(anchor, content, ..style) = {
        let text-color = style.named().at("text-color", default: gray)
        let content = text(fill: text-color, size: 11pt)[#content]
        draw.content((rel: (1.7, 0), to: "tags." + anchor), anchor: "south-west")[#content]
      }
      #let bounding-box = rect-if-show-layout(
        (rel: (-6.5, -4), to: "tags.0"),
        (rel: (7.2, 0.8), to: "tags.0"),
      )

      #v(2em)
      #scale(130%)[
      #alternatives(repeat-last: true)[
      ][#align(top + right)[#canvas({
        tag-tree((node) => draw-node-highlight(standard_color_picker, node),
          (
            (content: [`x`], rel: ""),
          ),
          spread: 7,
          grow: 3,
        )
        current-state("0")[`Active`]
        accessed-tag("0")[Alloc]
        transition-summary("0", text-color: alloc_color)[new]
        bounding-box
      })]][#align(top + right)[#canvas({
        tag-tree((node) => draw-node-highlight(standard_color_picker, node),
          (
            (content: [`x`,`r`], rel: ""),
          ),
          spread: 7,
          grow: 3,
        )
        previous-state("0")[Active]
        current-state("0")[`Active`]
        accessed-tag("0")[Raw]
        bounding-box
      })]][#align(top + right)[#canvas({
        tag-tree((node) => draw-node-highlight(standard_color_picker, node),
          (
            (content: [`x`,`r`], rel: ""),
          ),
          spread: 7,
          grow: 3,
        )
        previous-state("0")[Active]
        current-state("0")[`Active`]
        accessed-tag("0")[Write]
        transition-summary("0", text-color: child_color)[$arrow.b$child write]
        bounding-box
      })]]]
   ],
   layout[#only((2,3,4,5,6))[#scale(80%)[#canvas({state-machine-normal})]]],
  )

  #only(6)[
    #full-slide-overlay[
      - Raw pointers inherit tag \ (and permissions with it)
      - Same approach for interior mutability
    ]
  ]
]


#focus-slide[
  All mutable references are two-phase borrows
]

#slide[
  #grid(
    columns: (5%, 60%, 25%),
    layout[],
    layout[
      #grid(
        columns: (30%, 20%),
        [
          #let executing-loc(i, content) = canvas({
            let y = 0.75 - 0.86 * i
            rect-if-show-layout((1, 1), (-3.6, -3))
            draw.line((0, y), (1, y), name: "line", mark: (end: "o"))
            let content = text(size: 20pt)[#content]
            draw.content((rel: (-0.2, 0), to: "line.start"), anchor: "east")[#content]
          })
          #alternatives(repeat-last: true)[
                      ][
                      ][#executing-loc(0, [Alloc `x`])
                      ][#executing-loc(1, [Borrow `y`])
                      ][#executing-loc(2, [Borrow `z`])
                      ][#executing-loc(3, [Read `z`])
                      ][#executing-loc(4, [Write `y`])
                      ]
        ],
        text(size: 22pt)[
        #alternatives(repeat-last: true)[```rs
          let mut x = 0u64;
          let y = &*addr_of!(x);
          let z = &mut x;  // Create mutable reference
          let v = read(y);
          write(z, 42);    // Use it mutably

          ```
        ][```rs
          let mut x = 0u64;
          let y = &*addr_of!(x);
          let z = &mut x;
          let v = read(y); // Read accesses still allowed
          write(z, 42);

          ```
        ][```rs
          let mut x = 0u64;
          let y = &*addr_of!(x);
          let z = &mut x;
          let v = read(y);
          write(z, 42);
          ```
        ]
      ])

      #v(2em)
      #let previous-state(anchor, content) = {
        let content = text(fill: gray.darken(30%), size: 11pt)[old: #content]
        draw.content((rel: (0.85, 0.4), to: "tags." + anchor), anchor: "south-west")[#content]
      }
      #let current-state(anchor, content) = {
        let content = text(size: 21pt)[#content]
        draw.content((rel: (0.8, -0.1), to: "tags." + anchor), anchor: "north-west")[#content]
      }
      #let accessed-tag(anchor, content) = {
        let content = text(size: 16pt)[#content]
        draw.content((rel: (-3, 0.1), to: "tags." + anchor), anchor: "south-west")[#content]
        draw.line((rel: (-3, -0.1), to: "tags." + anchor),
                  (rel: (-1, -0.1), to: "tags." + anchor), mark: (end: "o"))
      }
      #let transition-summary(anchor, content, ..style) = {
        let text-color = style.named().at("text-color", default: gray)
        let content = text(fill: text-color, size: 11pt)[#content]
        draw.content((rel: (1.5, 0), to: "tags." + anchor), anchor: "south-west")[#content]
      }
      #let bounding-box = rect-if-show-layout(
        (rel: (-6.5, -4), to: "tags.0"),
        (rel: (7.6, 0.8), to: "tags.0"),
      )

      #scale(130%)[
      #alternatives(repeat-last: true)[][
      ][#align(top + right)[#canvas({
        tag-tree((node) => draw-node-highlight(standard_color_picker, node),
          (
            (content: [`x`], rel: ""),
          ),
          spread: 7,
          grow: 3,
        )
        current-state("0")[`Active`]
        accessed-tag("0")[Alloc]
        transition-summary("0", text-color: alloc_color)[new]
        bounding-box
      })]][#align(top + right)[#canvas({
        tag-tree((node) => draw-node-highlight(standard_color_picker, node),
          (
            (content: [`x`], rel: ""),
              (content: [`y`], rel: ""),
          ),
          spread: 7,
          grow: 3,
        )
        previous-state("0")[Active]
        current-state("0")[`Active`]
        current-state("0-0")[`Frozen`]
        accessed-tag("0-0")[Borrow]
        transition-summary("0", text-color: child_color)[$arrow.b$child read]
        transition-summary("0-0", text-color: alloc_color)[new]
        bounding-box
      })]][#align(top + right)[#canvas({
        tag-tree((node) => draw-node-highlight(standard_color_picker, node),
          (
            (content: [`x`], rel: ""),
              (content: [`y`], rel: ""),
              (content: [`z`], rel: ""),
          ),
          spread: 7,
          grow: 3,
        )
        previous-state("0")[Active]
        previous-state("0-0")[Frozen]
        current-state("0")[`Active`]
        current-state("0-0")[`Frozen`]
        current-state("0-1")[`Reserved`]
        accessed-tag("0-1")[Borrow]
        transition-summary("0", text-color: child_color)[$arrow.b$child read]
        transition-summary("0-0", text-color: foreign_color)[$arrow.b$foreign read]
        transition-summary("0-1", text-color: alloc_color)[new]
        bounding-box
      })]][#align(top + right)[#canvas({
        tag-tree((node) => draw-node-highlight(standard_color_picker, node),
          (
            (content: [`x`], rel: ""),
              (content: [`y`], rel: ""),
              (content: [`z`], rel: ""),
          ),
          spread: 7,
          grow: 3,
        )
        previous-state("0")[Active]
        previous-state("0-0")[Frozen]
        previous-state("0-1")[Reserved]
        current-state("0")[`Active`]
        current-state("0-0")[`Frozen`]
        current-state("0-1")[`Reserved`]
        accessed-tag("0-0")[Read]
        transition-summary("0", text-color: child_color)[$arrow.b$child read]
        transition-summary("0-0", text-color: child_color)[$arrow.b$child read]
        transition-summary("0-1", text-color: foreign_color)[$arrow.b$foreign read]
        bounding-box
      })]][#align(top + right)[#canvas({
        tag-tree((node) => draw-node-highlight(standard_color_picker, node),
          (
            (content: [`x`], rel: ""),
              (content: [`y`], rel: ""),
              (content: [`z`], rel: ""),
          ),
          spread: 7,
          grow: 3,
        )
        previous-state("0")[Active]
        previous-state("0-0")[Frozen]
        previous-state("0-1")[Reserved]
        current-state("0")[`Active`]
        current-state("0-0")[`Disabled`]
        current-state("0-1")[`Active`]
        accessed-tag("0-1")[Write]
        transition-summary("0", text-color: child_color)[$arrow.b$child write]
        transition-summary("0-0", text-color: foreign_color)[$arrow.b$foreign write]
        transition-summary("0-1", text-color: child_color)[$arrow.b$child write]
        bounding-box
      })]]
    ]
   ],
   layout[#only((3,4,5,6,7,8))[#scale(80%)[#canvas({state-machine-normal})]]],
  )
  #only(8)[
    #full-slide-overlay[
      - ```rs &mut``` starts `Reserved`
      - `Reserved` tolerates all read accesses
      - Tree structure makes this possible
    ]
  ]
]

#focus-slide[
  Conclusion
]

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


