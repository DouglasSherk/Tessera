# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ = jQuery

getCanvas = (container) ->
  canvas = null
  $("canvas", container).each -> canvas = this
  context = canvas.getContext('2d')
  return [canvas, context]

getCanvasStretchFactor = (canvas) ->
  cssWidth = $(canvas).width()
  canvasWidth = canvas.width
  return cssWidth / canvasWidth

vertexToCanvasCoords = (canvas, vertex, coordSpace) ->
  width = if coordSpace == 'canvas' then canvas.width else $(canvas).width()
  height = if coordSpace == 'canvas' then canvas.height else $(canvas).height()
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
      vertexInCanvasCoords = vertexToCanvasCoords(canvas, vertex, 'css')
      mouseX = event.pageX - offset.left
      mouseY = event.pageY - offset.top
      distance = Math.sqrt(Math.pow(vertexInCanvasCoords.x - mouseX, 2.0) +
                           Math.pow(vertexInCanvasCoords.y - mouseY, 2.0))
      if distance < getCanvasStretchFactor(canvas) * 25.0
        closest = key

  return if !closest? then null else parseInt(closest)

$.fn.eventMouseMove = (event) ->
  vertex = findClosestVertexToMouse(event, this)
  $(this).drawPolygon(vertex)

$.fn.eventMouseClick = (event) ->
  vertex = findClosestVertexToMouse(event, this)
  if !vertex? then return
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

  # Begin path for line.
  context.beginPath()

  context.lineWidth = 1

  for vertex in vertices
    do (vertex) ->
      vertexInCanvasCoords = vertexToCanvasCoords(canvas, vertex, 'canvas')
      context.lineTo(vertexInCanvasCoords.x, vertexInCanvasCoords.y)

  context.strokeStyle = 'rgba(255, 0, 0, 0.5)'
  context.stroke()

  context.closePath()
  # End path for polygon.

  # Begin path for vertex markers.
  for key, vertex of vertices
    do (key, vertex) ->
      if key > 0
        key = parseInt(key)
        color = if key is firstVertex then '128, 128, 255' else '128, 255, 128'
        alpha = if key is activeVertex then '1.00' else '0.50'

        vertexInCanvasCoords = vertexToCanvasCoords(canvas, vertex, 'canvas')

        context.beginPath()
        context.arc(vertexInCanvasCoords.x, vertexInCanvasCoords.y, 15.0, 0, 2*Math.PI, false)
        context.lineWidth = 2

        if selectedVertices.indexOf(key) != -1
          context.fillStyle = 'rgba(255, 255, 255, ' + alpha + ')'
        else
          context.fillStyle = 'rgba(' + color + ', ' + alpha + ')'

        context.strokeStyle = 'rgba(' + color + ', 1.0)'
        context.fill()
        context.stroke()
        context.closePath()
  # End path for vertex markers.

  for key, vertex of vertices
    do (key, vertex) ->
      if key > 0
        key = parseInt(key)
        vertexInCanvasCoords = vertexToCanvasCoords(canvas, vertex, 'canvas')
        context.beginPath()
        context.textAlign = 'center'
        context.fillStyle = if selectedVertices.indexOf(key) != -1 then 'red' else 'black'
        context.font = '16px Arial'
        text = if key >= firstVertex then (key - firstVertex) else (key + vertices.length - 1 - firstVertex)
        context.fillText(text + 1, vertexInCanvasCoords.x, vertexInCanvasCoords.y + 6)
        context.closePath()

$.fn.writePatternToHiddenField = ->
  span = this.get(0)
  selectedVertices = $.data(span, 'selectedVertices')
  inputField = $("#user_password")
  inputField.val(JSON.stringify(selectedVertices))
