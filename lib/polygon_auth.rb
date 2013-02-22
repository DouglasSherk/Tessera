module PolygonAuth
  class Vertex
    attr_accessor :x, :y

    def initialize(_x, _y)
      @x = _x
      @y = _y
    end
  end

  class PolygonGenerator
    def generatePolygon
      angle = 0.0, neededVertices = 6 + rand(13)
      vertices = Array.new
      angleStep = 2*Math::PI/neededVertices

      distanceBetweenVertices = Math.sqrt(
        Math.cos(angleStep)**2 + Math.sin(angleStep)**2)

      shrinkFactor = 0.75

      0.upto(neededVertices) do |vertexNum|
        vertices.push(Vertex.new(
          shrinkFactor * (Math.cos(angleStep * vertexNum) + distanceBetweenVertices * (rand - 0.5) * 0.5),
          shrinkFactor * (Math.sin(angleStep * vertexNum) + distanceBetweenVertices * (rand - 0.5) * 0.5)
        ))
      end

      # First must be same as last.
      vertices[0] = vertices.last

      return vertices
    end

    def generateFirstVertex(vertices)
      # Never allow the first vertex in the array to be the first logical vertex, since it overlaps
      # with the last vertex.
      return rand(vertices.length - 1) + 1
    end
  end
end
