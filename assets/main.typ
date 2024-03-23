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
  fn foo(y: &mut u64) {
      let val = *y;
      *x = 42;
      opaque();
      *y = val;
  }
  ```,
  ```rs
  fn foo(y: &mut u64) {


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
  name: "tags",
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
    let color = check(node.content.at("rel", default: ""))
    let fill = if color != none { color } else { white }
    draw.circle((), radius: 0.8, stroke: black, fill: fill)
    draw.content((), node.content.content)
}

#let strict_color = blue.darken(10%)
#let self_color = blue.darken(-50%)
#let parent_color = red.darken(-50%)
#let cousin_color = red.darken(10%)
#let child_color = blue.darken(-20%)
#let foreign_color = red.darken(-20%)
#let standard_color_picker(rel) = {
  if rel == "T" { self_color }
  else if rel == "S" { strict_color }
  else if rel == "P" { parent_color }
  else if rel == "C" { cousin_color }
  else { none }
}
#let standard_color_picker_restrict(r) = (rel) => if rel == r { standard_color_picker(rel) } else { none }

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

    #grid(
    columns: (70%, 30%),
    {
      only(1)[#canvas({
        tag-tree( (node) => { draw-node-highlight(standard_color_picker_restrict("T"), node) }, structure)
      })]
      only(2)[#canvas({
        tag-tree( (node) => { draw-node-highlight(standard_color_picker_restrict("S"), node) }, structure)
      })]
      only(3)[#canvas({
        tag-tree( (node) => { draw-node-highlight(standard_color_picker_restrict("P"), node) }, structure)
      })]
      only(4)[#canvas({
        tag-tree( (node) => { draw-node-highlight(standard_color_picker_restrict("C"), node) }, structure)
      })]

      only(5)[#canvas({
          tag-tree( (node) => { draw-node-highlight(standard_color_picker, node) }, structure)
      })]

    },
    [
      #only((1,2,5))[
        #text(fill: self_color)[self] & #text(fill: strict_color)[strict children] \
        #text(fill: child_color)[$->$ children]
      ]

      #only((3,4,5))[
        #text(fill: parent_color)[parents] & #text(fill: cousin_color)[cousins] \
        #text(fill: foreign_color)[$->$ foreign]
      ]
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

#let state(x, y, name, label) = {
  let name = name + "-box"
  draw.rect((x, y), (x+2, y+1), name: name)
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

#let state-machine-normal = canvas({
    state(0, 0, "res", `Res`)
    state(0, -3, "act", `Act`)
    state(0, -6, "frz", `Frz`)
    state(3, -9, "dis", `Dis`)

    bezier-between-states("res", "dis", "east")
    bezier-between-states("act", "dis", "east")
    bezier-between-states("frz", "dis", "east")
    draw.content(
      (rel: (0.5, -0.5), to: "arr-res-dis.ctrl-0"),
      anchor: "center", angle: -45deg,
      text(fill: foreign_color)[foreign write],
    )

    straight-down("res", "act", "east", [child write], text-color: child_color)
    straight-down("act", "frz", "east", [foreign read], text-color: foreign_color)

    self-loop("res", "west", [any read])
    self-loop("act", "west", [child r/w], text-color: child_color)
    self-loop("frz", "west", [any read])
    self-loop("dis", "west", [foreign r/w], text-color: foreign_color)
})

#let state-machine-protect = canvas({
    state(0, 0, "res", `Res`)
    state(0, -3, "act", `Act`)
    state(0, -6, "frz", `Frz`)
    state(3, -3, "con", `Con`)
    draw.rect((3, -9), (5, -8), stroke: none)

    bezier-between-states("res", "con", "east")
    draw.content(
      (rel: (0.9, -0.5), to: "arr-res-con.ctrl-0"),
      anchor: "center", angle: -45deg,
      text(fill: foreign_color)[foreign read],
    )

    straight-down("res", "act", "east", [child write])

    self-loop("res", "west", [any read])
    self-loop("act", "west", [child r/w], text-color: child_color)
    self-loop("frz", "west", [any read])
    self-loop("con", "east", [any read])
})


#slide[
  #grid(
    columns: (45%, 50%),
    [*Default*],
    [*Protected*],
    state-machine-normal,
    state-machine-protect,
  )
]

#slide[
  #grid(
    columns: (10%, 45%, 30%),
    [],
    [
      #scale(80%)[
        #alternatives[```rs
          static mut X = 0;






          ```
        ][```rs
          static mut X = 0;
          let y = &mut X;





          ```
        ][```rs
          static mut X = 0;
          let y = &mut X;
          let val = *y;




          ```
        ][```rs
          static mut X = 0;
          let y = &mut X;
          let val = *y;
          *y = 42;



          ```
        ][```rs
          static mut X = 0;
          let y = &mut X;
          let val = *y;
          *y = 42;
          print!(X);


          ```
        ][```rs
          static mut X = 0;
          let y = &mut X;
          let val = *y;
          *y = 42;
          print!(X);
          *y = val;

          ```
        ]
      ]

      #let current-state(anchor, content) = {
        draw.content((rel: (0.8, -0.1), to: "tags." + anchor), anchor: "north-west")[#content]
      }
      #let accessed-tag(anchor, content) = {
        draw.content((rel: (-4, 0.1), to: "tags." + anchor), anchor: "south-west")[#content]
        draw.line((rel: (-4, -0.1), to: "tags." + anchor),
                  (rel: (-1, -0.1), to: "tags." + anchor), mark: (end: ">"))
      }
      #let transition-summary(anchor, content, ..style) = {
        let text-color = style.named().at("text-color", default: gray)
        let content = text(fill: text-color, size: 13pt)[#content]
        draw.content((rel: (1, 0.2), to: "tags." + anchor), anchor: "south-west")[#content]
      }

      #scale(130%)[
      #alternatives[#align(top + right)[#canvas({
        tag-tree((node) => draw-node-highlight((rel) => none, node),
          (
            (content: [`X`], rel: ""),
          )
        )
        current-state("0")[`Active`` `` `` `]
        accessed-tag("0")[Alloc]
        transition-summary("0", text-color: green.darken(50%))[`new`]
      })]][#align(top + right)[#canvas({
        tag-tree((node) => draw-node-highlight((rel) => none, node),
          (
            (content: [`X`], rel: ""),
              (content: [`y`], rel: ""),
          )
        )
        current-state("0")[`Active`]
        current-state("0-0")[`Reserved`]
        accessed-tag("0-0")[Retag]
        transition-summary("0", text-color: gray)[`noop`]
        transition-summary("0-0", text-color: green.darken(50%))[`new`]
      })]][#align(top + right)[#canvas({
        tag-tree((node) => draw-node-highlight(standard_color_picker, node),
          (
            (content: [`X`], rel: ""),
              (content: [`y`], rel: ""),
          )
        )
        current-state("0")[`Active`]
        current-state("0-0")[`Reserved`]
        accessed-tag("0-0")[Read]
        transition-summary("0", text-color: gray)[`noop`]
        transition-summary("0-0", text-color: gray)[`noop`]
      })]][#align(top + right)[#canvas({
        tag-tree((node) => draw-node-highlight(standard_color_picker, node),
          (
            (content: [`X`], rel: ""),
              (content: [`y`], rel: ""),
          )
        )
        current-state("0")[`Active`` `` `` `]
        current-state("0-0")[`Active`]
        accessed-tag("0-0")[Write]
        transition-summary("0", text-color: gray)[`noop`]
        transition-summary("0-0", text-color: child_color)[`Res -> Act`]
      })]][#align(top + right)[#canvas({
        tag-tree((node) => draw-node-highlight(standard_color_picker, node),
          (
            (content: [`X`], rel: ""),
              (content: [`y`], rel: ""),
          )
        )
        accessed-tag("0")[Read]
        current-state("0")[`Active`` `` `` `]
        current-state("0-0")[`Frozen`]
        transition-summary("0", text-color: gray)[`noop`]
        transition-summary("0-0", text-color: foreign_color)[`Act -> Frz`]
      })]][#align(top + right)[#canvas({
        tag-tree((node) => draw-node-highlight(standard_color_picker, node),
          (
            (content: [`X`], rel: ""),
              (content: [`y`], rel: ""),
          )
        )
        current-state("0")[`Active`` `` `` `]
        current-state("0-0")[]
        accessed-tag("0-0")[Write $arrow.zigzag$]
        transition-summary("0", text-color: gray)[`noop`]
        transition-summary("0-0", text-color: child_color)[`Frz ->`]
      })]]]
     ],

    scale(90%)[#state-machine-normal]
  )
]
