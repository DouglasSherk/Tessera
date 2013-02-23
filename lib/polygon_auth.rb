module PolygonAuth
  require 'bcrypt'

  class Vertex
    attr_accessor :x, :y

    def initialize(_x, _y)
      @x = _x
      @y = _y
    end
  end

  class PolygonGenerator
    def generatePolygon(security = 0)
      angle = 0.0, neededVertices = 6 + security * 18
      vertices = Array.new
      angleStep = 2*Math::PI/neededVertices

      distanceBetweenVertices = Math.sqrt(
        Math.cos(angleStep)**2 + Math.sin(angleStep)**2)

      shrinkFactor = 0.75

      0.upto(neededVertices) do |vertexNum|
        vertices.push(Vertex.new(
          shrinkFactor * (Math.cos(angleStep * vertexNum) + distanceBetweenVertices * (rand - 0.5) * 0.4),
          shrinkFactor * (Math.sin(angleStep * vertexNum) + distanceBetweenVertices * (rand - 0.5) * 0.4)
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

  class PolygonEncrypt
    def validatePattern(vertices, pattern)
      return true
    end

    def encryptPattern(pattern)
      return BCrypt::Password.create(pattern.to_json, :cost => 20)
    end
  end
end
