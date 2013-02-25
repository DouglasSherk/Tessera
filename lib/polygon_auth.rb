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
      angle = 0.0, neededVertices = 9 + security * 9, securityFactor = 2 - security
      vertices = Array.new
      angleStep = 2*Math::PI/neededVertices

      distanceBetweenVertices = Math.sqrt(
        Math.cos(angleStep)**2 + Math.sin(angleStep)**2) *
        securityFactor
      shrinkFactor = security == 0 ? 0.6 : 0.75

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

    def convertPatternToLogicalFormat(pattern, vertices, firstVertex)
      logicalFirstVertex = firstVertex - 1
      logicalPattern = pattern.map do |vertex|
        if vertex < logicalFirstVertex
          vertex += vertices.length
        end
        vertex -= logicalFirstVertex
      end

      return logicalPattern
    end
  end

  class PolygonEncrypt
    def validatePattern(vertices, pattern, security)
      return "Not enough vertices." if pattern.length < 3 || pattern.length > 6 + security * 18

      pattern.each do |vertex|
        return "Invalid pattern." if !vertex.is_a? Integer
      end

      return ""
    end

    def encryptPattern(pattern)
      return BCrypt::Password.create(pattern.to_json, :cost => 17)
    end

    def passwordFromHash(hash)
      return BCrypt::Password.new(hash)
    end
  end
end
