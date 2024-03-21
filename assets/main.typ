#import "@preview/polylux:0.3.1": *
#import "@preview/cetz:0.2.1": canvas, plot, draw, tree

#import themes.simple: *

#set text(
  font: "Inria Sans"
)
#show raw: text.with(font: "JetBrains Mono")

#show: simple-theme.with(
  footer: [
    #grid(
      columns: (80%, 20%),
      [Tree Borrows],
      align(right)[#logic.logical-slide.display()],
    )
  ]
)

#show heading.where(level: 2): it => [
  #set text(fill: aqua.darken(50%))
  #it
]

#title-slide[
  = Tree Borrows

  Neven Villani #footnote[ENS Paris-Saclay] <ens>,
  Johannes Hostert #footnote[ETH Zürich] <eth>,
  Derek Dreyer #footnote[MPI-SWS Saarbrücken] <mpi>,
  Ralf Jung @eth

  #v(2em)

  Rust Verification Workshop

  2024-04-08
]

#slide[
  Placeholder: aliasing xor mutability visual
]

#slide[
  == Absence of aliasing allows optimizations

  #grid(
    columns: (50%, 50%),
  ```rs
  fn foo(x: &mut u64) {
      let val = *x;
      *x = 42;
      opaque();
      *x = val;
  }
  ```,
  ```rs
  fn foo(x: &mut u64) {


      opaque();

  }
  ```
  )
]

#slide[
  ```rs
  static mut X: u64 = 0;
  fn opaque() { println!("{}", unsafe { X }); }
  fn main() { foo(unsafe { &mut X }); }
  ```

  #line(length: 100%)

  #grid(
    columns: (50%, 50%),
  ```rs
  fn foo(x: &mut u64) {
      let val = *x;
      *x = 42;
      opaque();
      *x = val;
  }
  ```,
  ```rs
  fn foo(x: &mut u64) {


      opaque();

  }
  ```,
  ```

  > 42
  ```,
  ```

  > 0
  ```
  )
]

#slide[
  == It's not the optimization that is wrong, it's the code

  Tree Borrows states rules that code must obey.

  Code that violates these rules is excluded from the proof of correctness of optimizations.


  === Sounds familiar ?

  Stacked Borrows has the same purpose, and Tree Borrows is its successor.
]

#slide[
  === Track provenance of pointers

  - each pointer gets an *identifier* on creation, its "tag"
  - we use a *tree* to keep track of the relationships between tags

  === Track permissions of pointers

  - each tag is associated with a *state* that represents its permission
  - memory accesses *update* permissions based on the tag relationships
]

#let tag-tree(draw-node, data) = tree.tree(
  data,
  grow: 2,
  spread: 2,
  draw-node: (node, ..) => draw-node(node),
  draw-edge: (from, to, ..) => {
    let (a, b) = (from + ".center", to + ".center")
    draw.line((a, 0.8, b), (b, 0.8, a))
  }
)

#let draw-node-default(node) = {
    draw.circle((), radius: 0.8, stroke: black)
    draw.content((), node.content.content)
}
#let draw-node-highlight(check, node) = {
    let color = check(node.content.rel)
    draw.circle((), radius: 0.8, stroke: black, fill: if color != none { color } else { white })
    draw.content((), node.content.content)
}


#slide[
  #let structure = ((content: [], rel: "P"),
        ((content: [], rel: "P"),
          ((content: [], rel:  "C"),
           (content: [],  rel: "C"),
           ((content: [], rel:  "C"),
            (content: [], rel:  "C")
           ),
           (content: [], rel:  "C")
          ),
          ((content: [self], rel:  "T"),
           (content: [], rel:  "S"),
           ((content: [], rel:  "S"),
            ((content: [], rel:  "S"),
             (content: [], rel:  "S")
             )
            )
           )
        ),
        ((content: [], rel:  "C"),
          (content: [], rel:  "C"),
          ((content: [], rel:  "C"),
           (content: [], rel:  "C"),
           (content: [], rel:  "C")
          )
        )
      )

  #let child_color = blue.darken(-50%)
  #let foreign_color = red.darken(20%)
  #grid(
    columns: (70%, 30%),
    {
      only(1)[#canvas({
        tag-tree( (node) => { draw-node-highlight((rel) => if rel == "T" { child_color } else { none }, node) }, structure)
      })]
      only(2)[#canvas({
        tag-tree( (node) => { draw-node-highlight((rel) => if rel == "S" { child_color } else { none }, node) }, structure)
      })]
      only(3)[#canvas({
        tag-tree( (node) => { draw-node-highlight((rel) => if rel == "P" { foreign_color } else { none }, node) }, structure)
      })]
      only(4)[#canvas({
        tag-tree( (node) => { draw-node-highlight((rel) => if rel == "C" { foreign_color } else { none }, node) }, structure)
      })]

      only(5)[#canvas({
          tag-tree( (node) => { draw-node-highlight((rel) => if rel == "C" or rel == "P" { foreign_color } else if rel == "T" or rel == "S" { child_color } else { none }, node) }, structure)
      })]

    },
    [
      #text(fill: child_color)[self & strict children $->$ children]

      #text(fill: foreign_color)[parents & cousins \ $->$ foreign]
    ]
)
]

#slide[
  == Per-location permission

  - `Reserved` #sym.approx mutable reference (not yet written to)
  - `Active` #sym.approx mutable reference
  - `Frozen` #sym.approx shared reference
  - `Disabled` #sym.approx dead pointer

]

#slide[
  #canvas({
    draw.rect((0,0), (2,1), name: "res-box")
    draw.content("res-box.center", anchor: "center", `Res`)

    draw.rect((0,-2), (2,-1), name: "act-box")
    draw.content("act-box.center", anchor: "center", `Act`)

    draw.rect((0,-4), (2,-3), name: "frz-box")
    draw.content("frz-box.center", anchor: "center", `Frz`)

    draw.rect((2,-6), (4,-5), name: "dis-box")
    draw.content("dis-box.center", anchor: "center", `Dis`)
  })
]
