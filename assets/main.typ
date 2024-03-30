#import "@preview/polylux:0.3.1": *
#import "@preview/cetz:0.2.1": canvas, plot, draw, tree

#import themes.simple: *

#set text(font: "Inria Sans")
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
  #set text(fill: aqua.darken(30%))
  #it
]
#show heading.where(level: 3): it => [
  #set text(fill: aqua.darken(50%))
  #it
]

#title-slide[
  = Tree Borrows

  Neven Villani #footnote[ENS Paris-Saclay, Université Paris-Saclay] <ens>,
  Johannes Hostert #footnote[ETH Zürich] <eth>,
  Derek Dreyer #footnote[MPI-SWS Saarbrücken] <mpi>,
  Ralf Jung @eth

  #v(2em)

  Rust Verification Workshop

  2024-04-08
]

#slide[
  == Strong guarantees for references

  #align(center)[
    #canvas({
      draw.circle((0, 0), radius: 2.5, stroke: (paint: red, thickness: 5pt), name: "circ")
      draw.line("circ.south-west", "circ.north-east", stroke: (paint: red, thickness: 5pt))
      draw.content((0, 0))[
        #align(center)[
        aliasing \
          & \
        mutability
      ]]
    })
  ]

  ```rs &mut``` $->$ mutation, no aliasing

  ```rs &``` $->$ aliasing, no mutation #footnote[for non-interior-mutable types]
]

#slide[
  == Absence of aliasing + mutability allows optimizations

  #alternatives[```rs
    fn foo(y: &mut u64) {
        let val = *y;
        *y = 42;

        *y = val;
    }
    ```][```rs
    fn foo(y: &mut u64) {
        let val = *y;
      //*y = 42;

        *y = val;
    }
    ```][```rs
    fn foo(y: &mut u64) {
        let val = *y;
      //*y = 42;

      //*y = val;
    }
    ```][```rs
    fn foo(y: &mut u64) {
      //let val = *y;
      //*y = 42;

      //*y = val;
    }
    ```]
    #only(5)[#grid(columns: (35%, 15%, 40%),
    ```rs
    fn foo(y: &mut u64) {
        let val = *y;
        *y = 42;

        *y = val;
    }
    ```,
    align(horizon)[$==>^"optimized"$],
    ```rs
    fn foo(y: &mut u64) {
      //let val = *y;
      //*y = 42;

      //*y = val;
    }
    ```
    )]
    #only(6)[#grid(columns: (35%, 15%, 40%),
    ```rs
    fn foo(y: &mut u64) {
        let val = *y;
        *y = 42;
        opaque();
        *y = val;
    }
    ```,
    align(horizon)[$==>^"optimized"$],
    ```rs
    fn foo(y: &mut u64) {
      //let val = *y;
      //*y = 42;
        opaque();
      //*y = val;
    }
    ```
    )]
]

#slide[
  #alternatives[```rs






    fn foo(y: &mut u64) {
        let val = *y;
        *y = 42;
        opaque();
        *y = val
    }
    ```][```rs
    static mut X: u64 = 0;





    fn foo(y: &mut u64) {
        let val = *y;
        *y = 42;
        opaque();
        *y = val
    }
    ```][```rs
    static mut X: u64 = 0;

    fn main() {
        foo(unsafe { &mut X });
    }

    fn foo(y: &mut u64) {
        let val = *y;
        *y = 42;
        opaque();
        *y = val
    }
    ```][```rs
    static mut X: u64 = 0;

    fn main() {
        foo(unsafe { &mut X });
    }

    fn foo(y: &mut u64) {
        let val = *y;
        *y = 42;
        println!("{}", unsafe { X }); // prints 42
        *y = val
    }
    ```][```rs
    static mut X: u64 = 0;

    fn main() {
        foo(unsafe { &mut X });
    }

    fn foo(y: &mut u64) {
      //let val = *y;
      //*y = 42;
        println!("{}", unsafe { X }); // prints 0
      //*y = val
    }
    ```][```rs
    static mut X: u64 = 0;

    fn main() {
        foo(unsafe { &mut X });
    }

    fn foo(y: &mut u64) {
      //let val = *y;
      //*y = 42;
        println!("{}", unsafe { X }); // prints 0
      //*y = val
    }
    ```]

  #only(6)[
    #place(center + bottom)[
      #box(fill: color.mix(red.darken(-40%), gray).darken(-60%), inset: 12pt, radius: 12pt)[
        #align(left)[
          Optimization *changes observable behavior*... \
          is the optimization incorrect ?
        ]
      ]
    ]
  ]
]

#slide[
  == It's not the optimization that is wrong, it's the code

  Tree Borrows adds proof obligations to ```rs unsafe``` blocks.

  Code that violates these rules is declared *Undefined Behavior*
  and ruled out from the proof of correctness of optimizations.

  #pause
  #align(center)[
    #box(fill: color.mix(aqua.darken(-40%), gray).darken(-20%), inset: 12pt, radius: 12pt)[
      #align(left)[
        === Sounds familiar ?

        *Stacked Borrows* has the same purpose, \
        Tree Borrows is its successor.
      ]
    ]
  ]
]

#slide[
  == Stacked Borrows

  Adds *extra state* to the abstract machine to track provenance. \
  Distinguishes pointers to the same location with an *identifier*.

  #pause
  Uses a *stack* to enforce that borrows are well-parenthesized. \
  The stack associates each pointer to its current *permission*.

  #pause
  Accesses to pointers *update* the stack structure and the permissions.
]

#slide[
  However Stacked Borrows...

  - does not handle 2-phase borrows
    #pause
    ```rs
    vec.push(vec.len())
    ```
  #pause

  - forbids common ```rs unsafe``` patterns
    #pause
    ```rs
    let from = data.as_ptr();
    // SB inserts an implicit write, killing the raw pointer
    let to = data.as_mut_ptr().add(1);
    std::ptr::copy_nonoverlapping(from, to, 1);
    ```

  #pause
  #align(center)[
    #box(fill: color.mix(aqua.darken(-40%), gray).darken(-20%), inset: 12pt, radius: 12pt)[
      #align(left)[
        Both of these restrictions come from the stack requirement.
      ]
    ]
  ]
]

#slide[
  == Stacked Borrows $arrow.squiggly$ Tree Borrows

  Remove the simplifying assumption of a stack, use a *tree* instead.

  #pause
  This allows
  - more accurate tracking of pointer ancestry
  - more fine-grained permissions

  #pause
  Resulting in
  - accurate handling of 2-phase borrows
  - more patterns permitted
  - simpler rules, fewer exceptions
]

#slide[
  === Aliasing model
  - defines which pointers are valid, for which ranges of memory, and in which order they can be accessed
  - *dynamic check* of uniqueness of ```rs &mut``` and immutability of ```rs &```

  #pause

  === Design constraints
  - strict enough that interesting *optimizations* are possible \
    $->$ _formalized in Coq, ongoing work to prove correctness_
  #pause
  - permissive enough that *existing libraries* are correct \
    $->$ _implemented in the Miri interpreter, checked against `std`_
]

#slide[
  == Key design elements
  #v(-1.2em)

  === Per-location
  - *disjoint* accesses do not interfere

  #pause

  === Track provenance of pointers
  - each pointer gets an *identifier* on creation
  - we use a *tree* to keep track of the relationships between tags

  #pause

  === Track permissions of pointers
  - each tag is associated with a *state* that represents its permission
  - accesses *update* permissions based on tag relationships
]

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

#let dim(c) = color.mix(c, gray)
#let strict_color = blue.darken(10%)
#let self_color = blue.darken(-50%)
#let parent_color = red.darken(-50%)
#let cousin_color = red.darken(10%)
#let child_color = dim(blue.darken(-20%))
#let foreign_color = dim(red.darken(-20%))
#let mixed_color = dim(purple.darken(-40%))
#let alloc_color = dim(green.darken(50%))
#let standard_color_picker(rel) = {
  if rel == "T" { self_color }
  else if rel == "S" { strict_color }
  else if rel == "P" { parent_color }
  else if rel == "C" { cousin_color }
  else { none }
}
#let standard_color_picker_restrict(..r) = (rel) => if rel in r.pos() { standard_color_picker(rel) } else { none }

#focus-slide[
  = Tracking relationships
]

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
        tag-tree( (node) => { draw-node-highlight(standard_color_picker_restrict("T", "S"), node) }, structure)
      })]
      only(4)[#canvas({
        tag-tree( (node) => { draw-node-highlight(standard_color_picker_restrict("P"), node) }, structure)
      })]
      only(5)[#canvas({
        tag-tree( (node) => { draw-node-highlight(standard_color_picker_restrict("C"), node) }, structure)
      })]
      only(6)[#canvas({
        tag-tree( (node) => { draw-node-highlight(standard_color_picker_restrict("P", "C"), node) }, structure)
      })]


      only(7)[#canvas({
          tag-tree( (node) => { draw-node-highlight(standard_color_picker, node) }, structure)
      })]
      only(8)[#canvas({
          tag-tree( (node) => { draw-node-highlight((rel) => if rel == "H" { alloc_color } else { none }, node) },
          ((content: [], rel: ""),
            ((content: [], rel: ""),
              ((content: [], rel:  ""),
               (content: [],  rel: ""),
               ((content: [], rel:  ""),
                (content: [], rel:  "")
               ),
               (content: [], rel:  "")
              ),
              ((content: [self], rel:  ""),
               (content: [], rel:  ""),
               ((content: [], rel:  ""),
                ((content: [], rel:  ""),
                 (content: [], rel:  "")
                 )
                ),
                (content: [new], rel: "H"),
               )
            ),
            ((content: [], rel:  ""),
              (content: [], rel:  ""),
              ((content: [], rel:  ""),
               (content: [], rel:  ""),
               (content: [], rel:  "")
              )
            )
          )
        )
      })]


    },
    [
      #only((1,2,3,7))[
        #text(fill: self_color)[self] & #text(fill: strict_color)[strict children] \
        #text(fill: child_color)[$->$ children]
      ]

      #only((4,5,6,7))[
        #text(fill: parent_color)[parents] & #text(fill: cousin_color)[cousins] \
        #text(fill: foreign_color)[$->$ foreign]
      ]

      #only(8)[
        #align(center)[
          #text(fill: alloc_color)[reborrows] \
          create \
          #text(fill: child_color)[children]
        ]
      ]
    ]
)
]

#focus-slide[
  = State machine
]

#slide[
  == Per-location permission

  After creation each pointer experiences a sequence of \
  child/foreign read/write accesses and gains/loses permissions \
  in consequence

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

#let state-machine-normal = {
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

    self-loop("res", "west", [any read], text-color: mixed_color)
    self-loop("act", "west", [child r/w], text-color: child_color)
    self-loop("frz", "west", [any read], text-color: mixed_color)
    self-loop("dis", "west", [foreign r/w], text-color: foreign_color)
}

#let state-machine-protect = {
    state(0, 0, "res", `Res`)
    state(0, -3, "act", `Act`)
    state(0, -6, "frz", `Frz`)
    state(3, -1, "con", `Con`)
    draw.rect((3, -9), (5, -8), stroke: none)

    bezier-between-states("res", "con", "east")
    draw.content(
      (rel: (0.9, 0.7), to: "arr-res-con.ctrl-0"),
      anchor: "center", angle: -10deg,
      text(fill: foreign_color)[foreign read],
    )

    straight-down("res", "act", "east", [child write], text-color: child_color)

    self-loop("res", "west", [child read], text-color: child_color)
    self-loop("act", "west", [child r/w], text-color: child_color)
    self-loop("frz", "west", [any read], text-color: mixed_color)
    self-loop("con", "east", [any read], text-color: mixed_color)
}


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
      draw.rect((rel: (5, 2), to: "res-box.center"), (rel: (-22, -10), to: "res-box.center"), stroke: none)
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
  = First example contains UB
]

#let Accepted = box(text(fill: green)[*Accepted*], stroke: green, inset: 7pt)
#let Rejected = box(text(fill: red)[*Rejected*], stroke: red, inset: 7pt)

#slide[
  #grid(
    columns: (10%, 45%, 30%),
    [],
    [
      #grid(
        columns: (35%, 20%),
        [
          #let executing-loc(i, content) = canvas({
            let y = 0.75 - 0.74 * i
            draw.rect((1, 1), (-3, -3.4), stroke: none)
            draw.line((0, y), (1, y), name: "line", mark: (end: ">"))
            let content = text(size: 20pt)[#content]
            draw.content((rel: (-0.2, 0), to: "line.start"), anchor: "east")[#content]
          })
          #alternatives[
                      ][#executing-loc(0, [Alloc `X`])
                      ][#executing-loc(1, [Borrow `y`])
                      ][#executing-loc(2, [Read `y`])
                      ][#executing-loc(3, [Write `y`])
                      ][#executing-loc(4, [Read `X`])
                      ][#executing-loc(5, [Write `y`])
                      ]
        ],
        text(size: 19pt)[
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
        ]])

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
                  (rel: (-1, -0.1), to: "tags." + anchor), mark: (end: ">"))
      }
      #let transition-summary(anchor, content, ..style) = {
        let text-color = style.named().at("text-color", default: gray)
        let content = text(fill: text-color, size: 13pt)[#content]
        draw.content((rel: (1, 0), to: "tags." + anchor), anchor: "south-west")[#content]
      }
      #let bounding-box = draw.rect((rel: (-6, -2.8), to: "tags.0"), (rel: (6, 0.8), to: "tags.0"), stroke: none)

      #scale(130%)[
      #alternatives[][#align(top + right)[#canvas({
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
        transition-summary("0", text-color: child_color)[+child read]
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
        transition-summary("0", text-color: child_color)[+child read]
        transition-summary("0-0", text-color: child_color)[+child read]
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
        transition-summary("0", text-color: child_color)[+child write]
        transition-summary("0-0", text-color: child_color)[+child write]
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
        transition-summary("0", text-color: child_color)[+child read]
        transition-summary("0-0", text-color: foreign_color)[+foreign read]
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
        transition-summary("0", text-color: child_color)[+child write]
        transition-summary("0-0", text-color: child_color)[+child write]
        bounding-box
      })]]]
     ],

     only((2,3,4,5,6,7))[#scale(70%)[#canvas({state-machine-normal})]],
  )
]

#focus-slide[
  = Two-phase borrows
]

#slide[
  #grid(
    columns: (5%, 60%, 25%),
    [],
    [
      #grid(
        columns: (30%, 20%),
        [
          #let executing-loc(i, content) = canvas({
            let y = 0.75 - 0.74 * i
            draw.rect((1, 1), (-3.6, -2.7), stroke: none)
            draw.line((0, y), (1, y), name: "line", mark: (end: ">"))
            let content = text(size: 20pt)[#content]
            draw.content((rel: (-0.2, 0), to: "line.start"), anchor: "east")[#content]
          })
          #alternatives[
                      ][
                      ][#executing-loc(0, [Alloc `x`])
                      ][#executing-loc(1, [Borrow `y`])
                      ][#executing-loc(2, [Borrow `z`])
                      ][#executing-loc(3, [Read `z`])
                      ][#executing-loc(4, [Write `y`])
                      ]
        ],
        text(size: 19pt)[
        #alternatives(repeat-last: true)[```rs
          let mut x = 0u64;
          let y = &mut x; // Create mutable reference
          let z = &x;
          read_only(z);
          mutate(y);      // Use it mutably

          ```
        ][```rs
          let mut x = 0u64;
          let y = &mut x;
          let z = &x;     // << Two-phase borrowed,
          read_only(z);   // << read access allowed
          mutate(y);

          ```
        ][```rs
          let mut x = 0u64;
          let y = &mut x;
          let z = &x;
          read_only(z);
          mutate(y);
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
                  (rel: (-1, -0.1), to: "tags." + anchor), mark: (end: ">"))
      }
      #let transition-summary(anchor, content, ..style) = {
        let text-color = style.named().at("text-color", default: gray)
        let content = text(fill: text-color, size: 11pt)[#content]
        draw.content((rel: (0.85, 0), to: "tags." + anchor), anchor: "south-west")[#content]
      }
      #let bounding-box = draw.rect(
        (rel: (-6.5, -4), to: "tags.0"),
        (rel: (7.2, 0.8), to: "tags.0"),
        stroke: none
      )

      #scale(130%)[
      #alternatives[][
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
        current-state("0-0")[`Reserved`]
        accessed-tag("0-0")[Borrow]
        transition-summary("0", text-color: child_color)[+child read]
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
        previous-state("0-0")[Reserved]
        current-state("0")[`Active`]
        current-state("0-0")[`Reserved`]
        current-state("0-1")[`Frozen`]
        accessed-tag("0-1")[Borrow]
        transition-summary("0", text-color: child_color)[+child read]
        transition-summary("0-0", text-color: foreign_color)[+foreign read]
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
        previous-state("0-0")[Reserved]
        previous-state("0-1")[Frozen]
        current-state("0")[`Active`]
        current-state("0-0")[`Reserved`]
        current-state("0-1")[`Frozen`]
        accessed-tag("0-1")[Read]
        transition-summary("0", text-color: child_color)[+child read]
        transition-summary("0-0", text-color: foreign_color)[+foreign read]
        transition-summary("0-1", text-color: child_color)[+child read]
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
        previous-state("0-0")[Reserved]
        previous-state("0-1")[Frozen]
        current-state("0")[`Active`]
        current-state("0-0")[`Active`]
        current-state("0-1")[`Disabled`]
        accessed-tag("0-0")[Write]
        transition-summary("0", text-color: child_color)[+child write]
        transition-summary("0-0", text-color: child_color)[+child write]
        transition-summary("0-1", text-color: foreign_color)[+foreign write]
        bounding-box
      })]]
    ]
   ],
   only((3,4,5,6,7))[#scale(70%)[#canvas({state-machine-normal})]],
  )
]

#focus-slide[
  = Conclusion
]

#slide[
  #align(horizon)[
    *Features:*
    - fine-grained 2-phase borrows
    - simple handling of raw pointers and interior mutability
    - common patterns forbidden by Stacked Borrows now allowed
    *Learn more:* #link("https://perso.crans.org/vanille/treebor")[`https://perso.crans.org/vanille/treebor/`]
    - stronger guarantees for function arguments (protectors)
    - no range restriction on reborrow
    *Try it out:* #link("https://github.com/rust-lang/miri")[`https://github.com/rust-lang/miri`]
    - use the flag `-Zmiri-tree-borrows`
    - report any surprises
  ]
]

#slide[
  #grid(
    columns: (45%, 50%),
    [*Default*],
    [*Protected*],
    canvas({state-machine-normal}),
    canvas({state-machine-protect}),
  )
]


