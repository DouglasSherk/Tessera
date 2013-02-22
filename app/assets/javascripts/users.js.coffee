# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ = jQuery

a = 0

$.fn.eventMouseMove = (event) ->
  console.log(a++)

$.fn.storeVerticesAndDraw = (vertices, firstVertex) ->
  $.data(this, 'vertices', vertices)
  $.data(this, 'firstVertex', firstVertex)

  canvas = null
  $("canvas", this).each -> canvas = this
  context = canvas.getContext('2d')

  this.mousemove(this.eventMouseMove)

  width = canvas.width
  height = canvas.height

  vertexToCanvasCoords = (vertex) ->
    x: width / 2 + vertex.x * width / 2,
    y: height / 2 + vertex.y * height / 2

  shrinkFactor = 0.5

  # Begin path for line.
  context.beginPath()

  for vertex in vertices
    do (vertex) ->
      vertexInCanvasCoords = vertexToCanvasCoords(vertex)
      context.lineTo(vertexInCanvasCoords.x, vertexInCanvasCoords.y)

  context.strokeStyle = 'red'
  context.stroke()

  context.closePath()
  # End path for polygon.

  # Begin path for vertex markers.
  for key, vertex of vertices
    do (key, vertex) ->
      if key > 0
        color = if parseInt(key) is firstVertex then '128, 128, 255' else '128, 255, 128'
        alpha = '0.25'

        vertexInCanvasCoords = vertexToCanvasCoords(vertex)

        context.beginPath()
        context.arc(vertexInCanvasCoords.x, vertexInCanvasCoords.y, 10.0, 0, 2*Math.PI, false)
        context.lineWidth = 3
        context.fillStyle = 'rgba(' + color + ', ' + alpha + ')'
        context.strokeStyle = 'rgba(' + color + ', 1.0)'
        context.fill()
        context.stroke()
        context.closePath()

  # End path for vertex markers.
