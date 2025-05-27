#import "@preview/cetz:0.3.2"
//#import "tree.typ"
#import cetz: tree

#let c = (
  foreign: orange,
  local: green,
  both: purple,
)

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

#let state(x, y, name, label) = {
  import cetz.draw: *
  let name = name + "-box"
  rect((x, y), (x+4, y+1), name: name)
  content(name + ".center", anchor: "center", label)
}

#let bezier-between-states(start, end, dir) = {
  import cetz.draw: *
  let name = "arr-" + start + "-" + end
  let start = start + "-box"
  let end = end + "-box"
  bezier(
    start + "." + dir,
    end + ".north",
    (start + "." + dir, "-|", end + ".north"),
    mark: (end: ">"),
    name: name,
  )
}

#let straight-down(start, end, dir, label, with-text: true, ..style) = {
  import cetz.draw: *
  let name = "arr-" + start + "-" + end
  let start = start + "-box"
  let end = end + "-box"
  let sign = if dir == "west" { 1 } else { -1 }
  line(
    start + ".south",
    end + ".north",
    mark: (end: ">"),
    name: name,
    stroke: style.named().at("stroke", default: black)
  )
  let text-color = style.named().at("text-color", default: gray)
  if with-text {
    content(
      (rel: (sign * 0.2, 0), to: name + ".mid"),
      anchor: dir,
      text(fill: text-color)[#label]
    )
  }
}
#let self-loop(box, dir, label, with-text: true, ..style) = {
  import cetz.draw: *
  let name = box + "-loop"
  let box = box + "-box"
  let sign = if dir == "east" { 1 } else { -1 }
  bezier(
    box + "." + dir,
    box + "." + dir,
    (rel: (sign * 1.5, 1.5), to: box + "." + dir),
    (rel: (sign * 1.5, -1.5), to: box + "." + dir),
    name: name,
    mark: (end: ">"),
    stroke: style.named().at("stroke", default: black)
  )
  let text-color = style.named().at("text-color", default: gray)
  if with-text {
    content(
      (rel: (sign * 0.2, 0), to: name + ".mid"),
      anchor: if dir == "east" { "west" } else { "east" },
      text(fill: text-color)[#label]
    )
  }
}

#let state-machine-normal(with-text: true) = {
    import cetz.draw: *
    state(0, 0, "res", `Reserved`)
    state(0, -3, "act", `Unique`)
    state(0, -6, "frz", `Frozen`)
    state(3, -9, "dis", `Disabled`)

    bezier-between-states("res", "dis", "east")
    bezier-between-states("act", "dis", "east")
    bezier-between-states("frz", "dis", "east")

    if with-text {
      content(
        (rel: (0.7, -1.1), to: "arr-res-dis.ctrl-0"),
        anchor: "center", angle: -60deg,
        text(fill: c.foreign)[foreign write],
      )
    }

    straight-down("res", "act", "east", [local write], text-color: c.local, with-text: with-text)
    straight-down("act", "frz", "east", [foreign read], text-color: c.foreign, with-text: with-text)

    self-loop("res", "west", [any read], text-color: c.both, with-text: with-text)
    self-loop("act", "west", [local r/w], text-color: c.local, with-text: with-text)
    self-loop("frz", "west", [any read], text-color: c.both, with-text: with-text)
    self-loop("dis", "west", [foreign r/w], text-color: c.foreign, with-text: with-text)
}

