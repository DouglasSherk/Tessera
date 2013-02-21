# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ = jQuery

$.fn.drawPolygon = (vertices, firstVertex) ->
  canvas = null
  $("canvas", this).each -> canvas = this
  context = canvas.getContext('2d')

  width = canvas.width
  height = canvas.height

  randomColor = ->
    colors = ['red', 'green', 'blue']
    colors[Math.floor(Math.random() * colors.length)]

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

  context.strokeStyle = randomColor()
  context.stroke()

  context.closePath()
  # End path for polygon.

  # Begin path for first vertex marker.
  context.beginPath()
  firstVertex = vertexToCanvasCoords(vertices[firstVertex])
  context.arc(firstVertex.x, firstVertex.y, 10.0, 0, 2*Math.PI, false)
  context.fillStyle = randomColor()
  context.strokeStyle = randomColor()
  context.fill()
  context.stroke()
  context.closePath()
  # End path for first vertex marker.
