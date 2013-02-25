module PolygonAuth
  require 'bcrypt'

  class Vertex
    attr_accessor :x, :y

    def initialize(_x, _y)
      @x = _x
      @y = _y
    end

    def distanceTo(otherVertex)
      puts Math.sqrt((@x - otherVertex.x)**2 + (@y - otherVertex.y)**2)
      return Math.sqrt((@x - otherVertex.x)**2 + (@y - otherVertex.y)**2)
    end
  end

  class PolygonGenerator
    def generatePolygon(security = 0)
      angle = 0.0, neededVertices = 9 + security * 9, securityFactor = 2 - security
      vertices = Array.new
      angleStep = 2*Math::PI/neededVertices

      distanceBetweenVertices = Math.sqrt(
        Math.cos(angleStep)**2 + Math.sin(angleStep)**2) *
        (securityFactor + 0.5)
      shrinkFactor = security == 0 ? 0.6 : 0.75

      0.upto(neededVertices) do |vertexNum|
        vertex = nil
        begin
          vertex = Vertex.new(
            shrinkFactor * (Math.cos(angleStep * vertexNum) + distanceBetweenVertices * (rand - 0.5) * 0.4),
            shrinkFactor * (Math.sin(angleStep * vertexNum) + distanceBetweenVertices * (rand - 0.5) * 0.4)
          )
        end while vertex == nil or
                  (!vertices.empty? and vertex.distanceTo(vertices.last) < 0.20 * securityFactor) or
                  (!vertices.empty? and vertexNum == neededVertices-2 and vertex.distanceTo(vertices.first) < 0.20 * securityFactor)
        vertices.push(vertex)
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
