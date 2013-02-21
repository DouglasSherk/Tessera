# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ = jQuery

$.fn.drawPolygon = (vertices) ->
  canvas = null
  $("canvas", this).each -> canvas = this
  context = canvas.getContext('2d')

  width = canvas.width
  height = canvas.height

  # Begin path drawing code.
  context.beginPath()

  shrinkFactor = 0.5

  for vertex in vertices
    do (vertex) ->
      context.lineTo(
        width / 2 + vertex.x * width / 2,
        height / 2 + vertex.y * height / 2
      )

  context.closePath()
  context.stroke()
  # End path drawing code.
