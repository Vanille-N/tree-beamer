#import "@preview/touying:0.6.1": *
#import "@preview/cetz:0.3.2"

#show raw: text.with(font: "JetBrains Mono")

#show heading.where(level: 2): it => [
  #set text(fill: aqua.darken(30%))
  #it
]
#show heading.where(level: 3): it => [
  #set text(fill: aqua.darken(50%))
  #it
]

#let textrect = rect

// Debug help
// Set this to true to print some bounding boxes and layout lines to help align content.
#let show-layout-boundaries = false
#let rect-if-show-layout(ul, br) = {
  cetz.draw.rect(ul, br, stroke: if show-layout-boundaries { black } else { none })
}
#let box-if-show-layout(c) = {
  rect(
    inset: 0pt,
    fill: if show-layout-boundaries { green.darken(-50%) } else { none },
    stroke: none,
  )[#c]
}
#let layout(c) = box-if-show-layout(c)

// Relative coordinates

#let rel(to, ..attrs) = {
  let as_arr = attrs.pos()
  let as_dic = attrs.named()
  let chosen = {
    if as_arr.len() > 0 {
      if as_dic.len() > 0 {
        panic("Can't handle poth positional and named arguments")
      } else {
        as_arr
      }
    } else {
      if as_dic.len() > 0 {
        as_dic
      } else {
        panic("Arguments must be provided")
      }
    }
  }
  (to: to, rel: chosen)
}

// Overlays

#let full-slide-overlay(c, dim: true) = {
  if dim {
    place(center + horizon)[
      #rect(width: 120%, height: 101%, fill: white.transparentize(20%))
    ]
  }
  place(center + horizon)[
    #box(fill: color.mix(aqua.darken(-40%), gray).darken(-20%), inset: 12pt, radius: 12pt)[
      #text(size: 40pt)[
        #align(left)[#c]
      ]
    ]
  ]
}

#let aside(content) = {
  align(center)[
    #box(fill: color.mix(aqua.darken(-40%), gray).darken(-20%), inset: 12pt, radius: 12pt)[
      #align(left)[
        #content
      ]
    ]
  ]
}

#let placed(at, content, neutral: false, dx: 0pt, dy: 0pt) = {
  place(at, dx: dx, dy: dy)[
    #box(
      inset: 12pt, radius: 12pt,
      fill: if neutral { gray.darken(-75%) } else { color.mix(aqua.darken(-40%), gray).darken(-20%) },
    )[
      #align(left)[
        #content
      ]
    ]
  ]
}

// Code blocks

#let body_color = gray.darken(-90%)
#let line_color = gray.darken(50%)
#let box_text_color = black

#let from-code(body, self: none) = {
  let linebreaks = ()
  for line in body.text.split("\n") {
    linebreaks.push(line.len() + 1)
  }
  import cetz.draw: *
  let cell-width = 12.05pt
  let cell-height = 28.1pt
  let line-col(line, col, anchor: "center") = {
    let x = cell-width * (col + 0.5)
    let y = - cell-height * (line + 0.5)
    if anchor.contains("north") {
      y += cell-height * 0.5
    } else if anchor.contains("south") {
      y -= cell-height * 0.5
    }
    if anchor.contains("east") {
      x += cell-width * 0.5
    } else if anchor.contains("west") {
      x -= cell-width * 0.5
    }
    (x, y)
  }
  let bounding-box = rect(
    stroke: none,
    line-col(0, 0, anchor: "north-west"),
    line-col(linebreaks.len(), calc.max(..linebreaks) - 1, anchor: "north-west"),
  )
  let dummy-highlight(nw, se) = {
    rect(
      line-col(..nw, anchor: "north-west"),
      line-col(..se, anchor: "south-east"),
    )
  }
  let highlight(nw, se, color: yellow) = {
    rect(
      stroke: none,
      fill: color.transparentize(80%),
      line-col(..nw, anchor: "north-west"),
      line-col(..se, anchor: "south-east"),
    )
  }
  let highlight-lines(min-width: 0, color: yellow, ..args) = {
    let lines = args.pos()
    let expanded-lines = ()
    for arg in lines {
      if type(arg) == int {
        expanded-lines.push(arg)
      } else {
        for ln in range(..arg) {
          expanded-lines.push(ln)
        }
      }
    }
    let max-width = min-width
    for ln in expanded-lines {
      max-width = calc.max(max-width, linebreaks.at(ln) - 2)
    }
    for ln in expanded-lines {
      highlight((ln,0), (ln,max-width), color: color)
    }
  }
  let patch(loc, code) = {
    let (nw, se) = loc
    rect(
      stroke: none,
      fill: body_color,
      line-col(..nw, anchor: "north-west"),
      line-col(..se, anchor: "south-east"),
    )
    content(rel(line-col(..nw, anchor: "north-west"), 0, -7pt), anchor: "north-west")[#code]
  }
  let patch-line(ln, new) = {
    let len = linebreaks.at(ln)
    rect(
      stroke: none,
      fill: body_color,
      line-col(ln, 0, anchor: "north-west"),
      line-col(ln, len, anchor: "south-east"),
    )
    content(rel(line-col(ln, 0, anchor: "north-west"), 0, -7pt), anchor: "north-west")[#new]
  }
  let locate(text) = {
    let match = body.text.matches(text)
    let res = ()
    for match in match {
      let len = match.end - match.start - 1
      let col = match.start
      let line = 0
      for linewidth in linebreaks {
        if col >= linewidth {
          col -= linewidth
          line += 1
        } else {
          break
        }
      }
      res.push(((line, col), (line, col + len)))
    }
    res
  }
  let uncover = if self == none { none } else {
    let self = utils.merge-dicts(self, config-methods(cover: utils.method-wrapper(hide.with(bounds: true))))
    let (uncover,) = utils.methods(self)
    uncover
  }
  let start-of(selection) = selection.at(0)
  let end-of(selection) = selection.at(1)
  let rel-to(loc, di, dj) = {
    let (i, j) = loc
    (i + di, j + dj)
  }
  let block = content((0,-6pt), anchor: "north-west")[#body]
  (
    block: {block; bounding-box},
    highlight: highlight,
    highlight-lines: highlight-lines,
    dummy-highlight: dummy-highlight,
    locate: locate,
    line-col: line-col,
    start-of: start-of,
    end-of: end-of,
    rel-to: rel-to,
    patch: patch,
    uncover: uncover,
    patch-line: patch-line,
  )
}

#let codebox(inner) = {
  rect(
    width: auto,
    radius: 6pt,
    fill: body_color,
    inset: (y: 8pt, x: 5pt),
    stroke: (top: 0.8pt + line_color, left: 0.8pt + line_color)
  )[
    #inner
  ]
}


