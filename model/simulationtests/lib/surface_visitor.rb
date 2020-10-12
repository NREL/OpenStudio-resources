# frozen_string_literal: true

require 'openstudio'

class SurfaceVisitor
  attr_reader :summary

  def initialize(model)
    setup(model)
    run(model)
    shutdown(model)
  end

  def setup(model); end

  def run(model)
    allsurfs = model.getSurfaces
    @surfs = []
    for surf in allsurfs do
      if !@surfs.include?(surf)
        other = surf.adjacentSurface
        if !other.empty?
          if !@surfs.include?(other.get)
            # This is an interior surface
            stype = surf.surfaceType
            @surfs << surf
            if stype == 'Floor'
              interiorFloor(model, surf, other.get)
            elsif stype == 'RoofCeiling'
              interiorRoofCeiling(model, surf, other.get)
            else # Wall
              interiorWall(model, surf, other.get)
            end
          end
        else
          # This is an exterior surface of some kind
          @surfs << surf
          exteriorSurface(model, surf)
        end
      end
    end
  end

  def interiorFloor(model, surface, adjacentSurface); end

  def interiorWall(model, surface, adjacentSurface); end

  def interiorRoofCeiling(model, surface, adjacentSurface); end

  def exteriorSurface(model, surface); end

  def shutdown(model)
    @summary = 'Visited ' + @surfs.size.to_s + ' surfaces'
  end
end
