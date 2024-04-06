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

// Set this to true to print some bounding boxes and layout lines to help align content.
#let show-layout-boundaries = false
#let rect-if-show-layout(ul, br) = {
  draw.rect(ul, br, stroke: if show-layout-boundaries { black } else { none })
}
#let box-if-show-layout(c) = {
  rect(
    inset: 0pt,
    fill: if show-layout-boundaries { green.darken(-50%) } else { none },
    stroke: none,
  )[#c]
}
#let layout(c) = box-if-show-layout(c)


#let full-slide-overlay(c) = {
  place(center + horizon)[
    #rect(width: 120%, height: 101%, fill: white.transparentize(20%))
  ]
  place(center + horizon)[
    #box(fill: color.mix(aqua.darken(-40%), gray).darken(-20%), inset: 12pt, radius: 12pt)[
      #text(size: 40pt)[
        #align(left)[#c]
      ]
    ]
  ]
}



#title-slide[
  = Tree Borrows

  #underline[Neven Villani], #footnote[ENS Paris-Saclay, Université Paris-Saclay] <ens>
  Johannes Hostert, #footnote[ETH Zürich] <eth>
  Derek Dreyer, #footnote[MPI-SWS Saarbrücken] <mpi>
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

  // Some blank to align the code with the next slide
  ```



  ```
  #v(0.52em)
  #grid(columns: (40%, 15%, 35%),
    alternatives[][][][][```rs
      fn foo(y: &mut u64) {
          let val = *y;
          *y = 42;

          *y = val;
      }
      ```][```rs
      fn foo(y: &mut u64) {
          let val = *y;
          *y = 42;
          opaque();
          *y = val;
      }
      ```],
      align(horizon)[#alternatives[][][][][$==>^"optimized"$][$==>^"optimized"$]],
      alternatives[```rs
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
        ```][```rs
        fn foo(y: &mut u64) {
          //let val = *y;
          //*y = 42;

          //*y = val;
        }
        ```][```rs
        fn foo(y: &mut u64) {
          //let val = *y;
          //*y = 42;
            opaque();
          //*y = val;
        }
        ```]
  )
]

#slide[
  #layout[#alternatives[```rs






    fn foo(y: &mut u64) {
        let val = *y;
        *y = 42;
        opaque();
        *y = val;
    }
    ```][```rs
    static mut X: u64 = 0;





    fn foo(y: &mut u64) {
        let val = *y;
        *y = 42;
        opaque();
        *y = val;
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
        *y = val;
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
        *y = val;
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
      //*y = val;
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
      //*y = val;
    }
    ```]]

  #only(6)[
    #place(center + bottom)[
      #box(fill: color.mix(red.darken(-40%), gray).darken(-60%), inset: 12pt, radius: 12pt)[
        #align(left)[
          Optimization *changes observable behavior*... \
          Is the optimization incorrect?
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
        === Sounds familiar?

        *Stacked Borrows* has the same purpose, \
        Tree Borrows is its successor.
      ]
    ]
  ]
]

#slide[
  == Stacked Borrows

  Adds *extra state* to the abstract machine to track provenance.
  Distinguishes pointers to the same location with a *tag*. \

  #pause
  Uses a *stack* to store permissions. \
  Enforces that borrows are well-bracketed.
]

#slide[
  However, Stacked Borrows...

  - does not handle two-phase borrows (gives up on any optimization)
    #pause
    ```rs
        vec.push(vec[0]);
    //  ^^^ 1. implicit &mut in function arguments
    //           ^^^^^^ 2. read-only operation before function
    //                     entry does not invalidate the &mut
    ```
  #pause

  - forbids common ```rs unsafe``` patterns (declared UB)
    #pause
    ```rs
    let from = data.as_ptr();
    // SB inserts an implicit write, killing the raw pointer
    let to = data.as_mut_ptr();
    std::ptr::copy_nonoverlapping(from, to.add(1), 1); // UB
    ```

  #pause
  #place(bottom)[
    #canvas({
      draw.rect((0, 0), (25, 6), stroke: none)
      draw.rect((0, 0), (25, 4), stroke: none,
        fill: white.transparentize(30%))
      draw.content((3.196, 3.45), name: "text-from")[`from`]
      draw.content((6.158, 3.45), name: "text-data1")[`data`]
      draw.content((2.77, 1.5), name: "text-to")[`to`]
      draw.content((5.31, 1.5), name: "text-data2")[`data`]
    })
  ]
  #place(bottom + right)[
    #box(radius: 10pt, fill: blue.darken(-70%))[
      #canvas({
        draw.rect((-2, 1.5), (6, -4.5), stroke: none)
        tree.tree((`data`, `from`, `to`),
          spread: 4,
          grow: 3,
          draw-node: (node, ..) => {
            draw.circle((), radius: 1, stroke: black)
            draw.content((), node.content)
          },
          draw-edge: (from, to, ..) => {
            let (a, b) = (from + ".center", to + ".center")
            draw.line((a, 1, b), (b, 1, a))
          }
        )
      })
   ]
  ]

  #pause
  #full-slide-overlay[
    The stack is too rigid to represent the exact relationship
  ]
]

#slide[
  == Stacked Borrows $arrow.squiggly$ Tree Borrows

  Stack is not precise enough. \

  Use a *tree* instead
  $->$ accurate tracking of pointer ancestry

  #pause
  Results in
  - accurate handling of two-phase borrows
  - more permitted patterns
  - simpler rules, fewer exceptions
]

#slide[
  === Design constraints
  ==== Enough UB
  - strict enough that interesting *optimizations* are possible \
    $->$ guided by desirable optimizations, and expected UB \
    $->$ _formalized in Coq, ongoing work to prove correctness_ \

  #pause

  ==== Not too much
  - permissive enough that *existing libraries* are correct \
    $->$ guided by common patterns, complaints about Stacked Borrows \
    $->$ _implemented in the Miri interpreter, checked against libraries_
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
#let strict_color = blue.darken(-50%)
#let self_color = blue.darken(5%)
#let parent_color = red.darken(10%)
#let cousin_color = red.darken(-50%)
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
  #let structure = (
    (content: [], rel: "P"),
        ((content: [], rel: "P"),
            ((content: [], rel:  "C"),
                (content: [],  rel: "C"),
                ((content: [], rel:  "C"),
                    (content: [], rel:  "C")
                ),
                (content: [], rel:  "C")
            ),
            ((content: [self], rel:  "T"),
                ((content: [], rel:  "S"),
                    (content: [], rel: "S")
                ),
                ((content: [], rel:  "S"),
                    ((content: [], rel:  "S"),
                          (content: [], rel:  "S")
                    )
                ),
                (content: [], rel: "S"),
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
    layout[#{
      alternatives[#canvas({
          tag-tree(
            (node) => {
              draw-node-highlight((rel) => if rel == "H" { alloc_color } else { none }, node)
            },
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
                       ((content: [], rel:  ""),
                          (content: [], rel: "")
                       ),
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
      })][#canvas({
        tag-tree( (node) => { draw-node-highlight(standard_color_picker_restrict("T"), node) }, structure)
      })][#canvas({
        tag-tree( (node) => { draw-node-highlight(standard_color_picker_restrict("S"), node) }, structure)
      })][#canvas({
        tag-tree( (node) => { draw-node-highlight(standard_color_picker_restrict("T", "S"), node) }, structure)
      })][#canvas({
        tag-tree( (node) => { draw-node-highlight(standard_color_picker_restrict("P"), node) }, structure)
      })][#canvas({
        tag-tree( (node) => { draw-node-highlight(standard_color_picker_restrict("C"), node) }, structure)
      })][#canvas({
        tag-tree( (node) => { draw-node-highlight(standard_color_picker_restrict("P", "C"), node) }, structure)
      })][#canvas({
          tag-tree( (node) => { draw-node-highlight(standard_color_picker, node) }, structure)
      })]
    }],
    layout[
      #only(1)[
        #align(center)[
          #text(fill: alloc_color)[reborrows] \
          create \
          #text(fill: child_color)[immediate children]
        ]

        #v(1em)

        ```rs
        let new = &*self;
        ```
      ]

      #only((2,3,4,8))[
        #text(fill: self_color)[self] & #text(fill: strict_color)[strict children] \
        #text(fill: child_color)[$->$ children]
      ]

      #only((5,6,7,8))[
        #text(fill: parent_color)[parents] & #text(fill: cousin_color)[cousins] \
        #text(fill: foreign_color)[$->$ foreign]
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
]

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
  = First example contains UB
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
  = Raw pointers
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
  = All mutable references are two-phase borrows
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
  = Conclusion
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

    #place(top + right)[#image("qr-treebor.png", width: 20%)]
    #place(bottom + right)[#image("qr-miri.png", width: 20%)]
  ]
]
