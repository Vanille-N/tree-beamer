#import "@preview/cetz:0.4.2"
#import cetz: tree

#let draw-tree(move: (0,0), structure) = {
  import cetz.draw: *
  tree.tree(structure,
    spread: 4,
    grow: 3,
    name: "tree",
    draw-node: (node, ..) => {
      circle((), radius: 1, stroke: black)
      content((), node.content)
    },
    draw-edge: (from, to, ..) => {
      let (a, b) = (from + ".center", to + ".center")
      line((a, 1, b), (b, 1, a))
    },
  )
}

