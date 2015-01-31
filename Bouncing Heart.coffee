'use strict'

class Vector
  constructor: (@x=0, @y=0, @z=0) ->
  add:      (v) -> new Vector(@x+v.x, @y+v.y, @z+v.z)
  multiply: (s) -> new Vector(@x*s  , @y*s  , @z*s  )
  subtract: (v) -> new Vector(@x-v.x, @y-v.y, @z-v.z)
  negative: (v) -> new Vector(-@x   , -@y   , -@z   )
  norm:     (v) -> Math.sqrt(@x*@x + @y*@y + @z*@z)
  dot:      (v) -> @x*v.x + @y*v.y + @z*v.z
  cross:    (v) -> new Vector(@y*v.z - @z*v.y,
                              @z*v.x - @x*v.z,
                              @x*v.y - @y*v.x)
  rotate:   (a) -> new Vector(@x*Math.cos(a) - @y*Math.sin(a),
                              @y*Math.cos(a) + @x*Math.sin(a))

class Polygon
  constructor: (@vertices) ->

  translate: (v) -> new Polygon(@vertices.map (w) -> w.add(v))

  getCentroid: ->
    A2 = 0 # twice area
    C = new Vector()
    [i, j] = [0, @vertices.length - 1]

    while i < @vertices.length
      [p1, p2] = [@vertices[i], @vertices[j]]
      [f,  j ] = [p1.x * p2.y - p2.x * p1.y, i++]
      A2  += f
      C.x += (p1.x + p2.x) * f
      C.y += (p1.y + p2.y) * f
    C.multiply(1 / (A2 * 3))

  getMoment: ->
    I = 0
    [i, j] = [0, @vertices.length - 1]

    while i < @vertices.length
      [p1, p2] = [@vertices[i], @vertices[j]]
      [f,  j ] = [p1.x * p2.y - p2.x * p1.y, i++]
      I  += (p1.x * p1.x + p1.y * p1.y + p1.x * p2.x + p1.y * p2.y + p2.x * p2.x + p2.y * p2.y) * f
    I

  getArea: ->
    [A2, l] = [0, @vertices.length]
    [i,  j] = [0, @vertices.length - 1]

    while i < @vertices.length
      [p1, p2] = [@vertices[i], @vertices[j]]
      A2 += p1.x * p2.y - p2.x * p1.y
      j = i++
    A2 / 2

  contains: (point) ->
    inside = false

    p1 = @vertices[0]
    for i in [1...@vertices.length]
        p2 = @vertices[i]
        if Math.min(p1.y,p2.y) < point.y <= Math.max(p1.y,p2.y) and point.x <= Math.max(p1.x,p2.x)
          xints  = (point.y - p1.y) * (p2.x - p1.x) / (p2.y - p1.y) + p1.x   if p1.y != p2.y
          inside = not inside   if p1.x == p2.x or point.x <= xints
        p1 = p2

    inside

  draw: (fill=no) ->
    # context.clearRect(0, 0, context.canvas.width, context.canvas.height)
    c = context
    c.save()
    [c.strokeStyle, c.fillStyle, c.lineJoin, c.lineWidth] = ["red", "red", "round", 2]
    c.beginPath()
    c[if i==0 then 'moveTo' else 'lineTo'](v.x, v.y) for v,i in @vertices
    c.closePath()
    if fill then c.fill() else c.stroke()
    c.restore()

class Body
  constructor: (@polygon, @pos, @vel, @ang, @ang_v) ->
    @polygon = new Polygon(@polygon) unless @polygon instanceof Polygon

    c = @polygon.getCentroid()
    @polygon = @polygon.translate(c.negative())
    [A, I] = [@polygon.getArea(), @polygon.getMoment()]

    @mass   = Math.abs(A)
    @moment = Math.abs(I/3)
    @pos    = @pos   or c
    @vel    = @vel   or 0
    @ang    = @ang   or 0
    @ang_v  = @ang_v or 0

  draw: ->
    # context.clearRect(0, 0, context.canvas.width, context.canvas.height)
    context.save()
    context.translate(@pos.x, @pos.y)
    context.rotate(@ang)
    @polygon.draw(yes)
    context.restore()

  vertices: ->
    new Polygon(@polygon.vertices.map (v) => v.rotate(@ang).add(@pos))

# Utility general purpose
canvas  = document.getElementById("canvas")
context = canvas.getContext("2d")
setEvents = do () ->
  listeners = {}
  (event_object) ->
    for type, listener of event_object
      canvas.removeEventListener type, listeners[type] if listeners[type]?
      canvas.addEventListener type, listener
      listeners[type] = listener
clearCanvas = -> context.clearRect(0, 0, context.canvas.width, context.canvas.height)
drawDot = (x,y,fill) ->
  context.save()
  context.beginPath()
  context.arc(x, y, 3, 0, Math.PI*2, false)
  context.fillStyle = fill
  context.fill()
  context.closePath()
  context.restore()
drawLine = (x1,y1,x2,y2,fill) ->
  context.save()
  context.beginPath()
  context.moveTo(x1, y1)
  context.lineTo(x2,y2)
  context.strokeStyle = fill
  context.stroke()
  context.closePath()
  context.restore()

# Drawing portion
[pen_down, path, body] = [no, new Polygon([]), undefined]
addPosition = (x, y) -> path.vertices.push(new Vector(x,y))

drawing_events =
  mousedown: (e) ->
    pen_down = yes
    addPosition(e.pageX - this.offsetLeft, e.pageY - this.offsetTop)
    clearCanvas()
    path.draw()

  mousemove: (e) ->
    if pen_down
      addPosition(e.pageX - this.offsetLeft, e.pageY - this.offsetTop)
      clearCanvas()
      path.draw()

  mouseup: (e) ->
    body = new Body(path.vertices.concat path.vertices[0])
    clearCanvas()
    body.draw()
    [pen_down, path.vertices] = [no, []]
    setEvents(launching_events)

  mouseleave: (e) ->
    if pen_down
      [pen_down, path.vertices] = [no, []]
      clearCanvas()

# Launching portion
id = undefined
[c, caught_object] = [undefined, no]
launching_events =
  mousedown: (e) ->
    [x,y] = [e.pageX - this.offsetLeft, e.pageY - this.offsetTop]
    vertices = body.vertices()
    if vertices.contains(new Vector(x,y))
      body.vel = new Vector()
      body.ang_v = 0
      [c, caught_object] = [vertices.getCentroid(), yes]
      drawDot(c.x,c.y)

  mousemove: (e) ->
    if caught_object
      clearCanvas()
      body.draw()
      drawDot(c.x,c.y, "black")
      drawLine(c.x,c.y, e.pageX - this.offsetLeft, e.pageY - this.offsetTop, "black")
      drawDot(e.pageX - this.offsetLeft, e.pageY - this.offsetTop, "black")

  mouseup: (e) ->
    return unless caught_object
    body.vel = new Vector(e.pageX-this.offsetLeft-c.x, e.pageY-this.offsetTop-c.y).multiply(1/7)
    caught_object = no
    # setEvents(clearing_events)
    id = setInterval((-> animate(body)), 1000/60) unless id?

  mouseleave: (e) ->

animate = (body) ->

  return if caught_object

  [g, e] = [new Vector(0,0.2), 0.7]
  [H, W] = [canvas.height, canvas.width]
  # Redraw
  clearCanvas()
  body.draw()
  # First order forward Euler time advance. dt = 1
  [body.pos, body.vel, body.ang] = [body.pos.add(body.vel), body.vel.add(g), body.ang + body.ang_v]
  # map coordinates
  transformed_vertices = body.vertices().vertices

  n = new Vector()
  for _, i in transformed_vertices[...-1]
    break unless n.norm() == 0
    [v1, v2] = transformed_vertices[i..i+1]

    # intersects right wall, left wall, bottom wall, top wall respectively
    switch
      when (v1.x - W) * (v2.x - W) <= 0 then [n, border_function] = [new Vector(-1,0,0), (v) -> v.x-W]
      when v1.x * v2.x <= 0             then [n, border_function] = [new Vector(1,0,0),  (v) -> -v.x ]
      when (v1.y - H) * (v2.y - H) <= 0 then [n, border_function] = [new Vector(0,-1,0), (v) -> v.y-H]
      when v1.y * v2.y <= 0             then [n, border_function] = [new Vector(0,1,0),  (v) -> -v.y ]

  unless n.norm() == 0
    extrema             = Math.max.apply @, transformed_vertices.map(border_function)
    body.pos            = body.pos.add n.multiply(extrema) # adjust shape so it isn't off-canvas

    intersection_points = transformed_vertices.filter (v) -> border_function(v) == extrema
    # Estimate the "average" intersection point
    c = intersection_points.reduce((acc, point) -> acc.add point).multiply(1/intersection_points.length)

    r_ap = c.subtract(body.pos)
    v_ap = body.vel.add((new Vector(0,0,body.ang_v)).cross(r_ap))

    # Impulse
    j = -(1+e)*v_ap.dot(n) / (1/body.mass + Math.pow(r_ap.cross(n).norm(), 2)/body.moment)

    # Update post-collision angular and linear velocity
    body.ang_v = body.ang_v + r_ap.cross(n.multiply(j)).z/body.moment
    body.vel   = body.vel.add(n.multiply(j/body.mass)).multiply(0.9)

# Clearing events
clearing_events =
  mousedown:  (e) ->
  mousemove:  (e) ->
  mouseup:    (e) ->
  mouseleave: (e) ->

setEvents(drawing_events)