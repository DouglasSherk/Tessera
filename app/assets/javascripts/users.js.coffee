# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ = jQuery

getCanvas = (container) ->
  canvas = null
  $("canvas", container).each -> canvas = this
  context = canvas.getContext('2d')
  return [canvas, context]

vertexToCanvasCoords = (canvas, vertex) ->
  width = canvas.width
  height = canvas.height
  return {
    x: width / 2 + vertex.x * width / 2,
    y: height / 2 + vertex.y * height / 2
  }

findClosestVertexToMouse = (event, target) ->
  offset = $(target).offset()
  [canvas, context] = getCanvas(target)

  vertices = $.data(target, 'vertices')

  closest = null

  for key, vertex of vertices
    do (key, vertex) ->
      vertexInCanvasCoords = vertexToCanvasCoords(canvas, vertex)
      mouseX = event.pageX - offset.left
      mouseY = event.pageY - offset.top
      distance = Math.sqrt(Math.pow(vertexInCanvasCoords.x - mouseX, 2.0) +
                           Math.pow(vertexInCanvasCoords.y - mouseY, 2.0))
      if distance < 40.0
        closest = key

  return closest

$.fn.eventMouseMove = (event) ->
  vertex = findClosestVertexToMouse(event, this)
  $(this).drawPolygon(vertex)

$.fn.eventMouseClick = (event) ->
  vertex = findClosestVertexToMouse(event, this)
  selectedVertices = $.data(this, 'selectedVertices')
  indexOfCurrentVertex = selectedVertices.indexOf(parseInt(vertex))

  if indexOfCurrentVertex != -1 then selectedVertices.splice(indexOfCurrentVertex, 1)
  else selectedVertices.push(parseInt(vertex))

  $.data(this, 'selectedVertices', selectedVertices)

  $(this).drawPolygon(vertex)

$.fn.storeVerticesAndDraw = (vertices, firstVertex) ->
  span = this.get(0)
  $.data(span, 'vertices', vertices)
  $.data(span, 'firstVertex', firstVertex)
  $.data(span, 'selectedVertices', [])

  this.mousemove(this.eventMouseMove)
  this.click(this.eventMouseClick)

  this.drawPolygon(-1)

$.fn.drawPolygon = (activeVertex) ->
  span = this.get(0)
  vertices = $.data(span, 'vertices')
  firstVertex = $.data(span, 'firstVertex')
  selectedVertices = $.data(span, 'selectedVertices')

  [canvas, context] = getCanvas(this)

  width = canvas.width
  height = canvas.height

  context.clearRect(0, 0, width, height)

  shrinkFactor = 0.5

  # Begin path for line.
  context.beginPath()

  context.lineWidth = 1

  for vertex in vertices
    do (vertex) ->
      vertexInCanvasCoords = vertexToCanvasCoords(canvas, vertex)
      context.lineTo(vertexInCanvasCoords.x, vertexInCanvasCoords.y)

  context.strokeStyle = 'red'
  context.stroke()

  context.closePath()
  # End path for polygon.

  # Begin path for vertex markers.
  for key, vertex of vertices
    do (key, vertex) ->
      if key > 0
        key = parseInt(key)
        color = if key is firstVertex then '128, 128, 255' else '128, 255, 128'
        alpha = if key is parseInt(activeVertex) then '1.00' else '0.25'

        vertexInCanvasCoords = vertexToCanvasCoords(canvas, vertex)

        context.beginPath()
        context.arc(vertexInCanvasCoords.x, vertexInCanvasCoords.y, 10.0, 0, 2*Math.PI, false)
        context.lineWidth = 3

        if selectedVertices.indexOf(key) != -1
          context.fillStyle = 'white'
        else
          context.fillStyle = 'rgba(' + color + ', ' + alpha + ')'

        context.strokeStyle = 'rgba(' + color + ', 1.0)'
        context.fill()
        context.stroke()
        context.closePath()

  # End path for vertex markers.
