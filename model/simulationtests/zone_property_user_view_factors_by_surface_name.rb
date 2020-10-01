# frozen_string_literal: true

require 'openstudio'
require 'lib/baseline_model'

model = BaselineModel.new

# make a 1 story, 100m X 50m, 5 zone core/perimeter building
model.add_geometry({ 'length' => 100,
                     'width' => 50,
                     'num_floors' => 1,
                     'floor_to_floor_height' => 4,
                     'plenum_height' => 1,
                     'perimeter_zone_depth' => 3 })

# add windows at a 40% window-to-wall ratio
model.add_windows({ 'wwr' => 0.4,
                    'offset' => 1,
                    'application_type' => 'Above Floor' })

# add ASHRAE System type 01, PTAC, Residential
model.add_hvac({ 'ashrae_sys_num' => '01' })

# add thermostats
model.add_thermostats({ 'heating_setpoint' => 24,
                        'cooling_setpoint' => 28 })

# assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions

# set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type

# add design days to the model (Chicago)
model.add_design_days

# In order to produce more consistent results between different runs,
# we sort the zones by names
thermal_zones = model.getThermalZones.sort_by { |z| z.name.to_s }
# assign user view factors to all surfaces in a single thermal zone, ensuring
# this zone is a perimeter zone
thermal_zone = thermal_zones[1]

# create the zone property user view factors by surface name object
zone_property_user_view_factors_by_surface_name = thermal_zone.getZonePropertyUserViewFactorsBySurfaceName

# get all spaces in the zone
spaces = thermal_zone.spaces.sort_by { |s| s.name.to_s }

# get all surfaces and subsurfaces in the zone
surfaces = []
sub_surfaces = []
spaces.each do |space|
  space.surfaces.each do |surface|
    surfaces << surface
    surface.subSurfaces.each do |sub_surface|
      sub_surfaces << sub_surface
    end
  end
end

# view factors for surfaces to surfaces
surfaces = surfaces.uniq.sort_by { |s| s.name.to_s }
surfaces.each do |surface1|
  surfaces.each do |surface2|
    view_factor = 0.0
    if surface1 != surface2
      view_factor = 0.25
    end
    zone_property_user_view_factors_by_surface_name.addViewFactor(surface1, surface2, view_factor)
  end
end

# view factors for subsurfaces to subsurfaces
sub_surfaces = sub_surfaces.uniq.sort_by { |s| s.name.to_s }
sub_surfaces.each do |sub_surface1|
  sub_surfaces.each do |sub_surface2|
    view_factor = 0.0
    if sub_surface1 != sub_surface2
      view_factor = -0.75
    end
    zone_property_user_view_factors_by_surface_name.addViewFactor(sub_surface1, sub_surface2, view_factor)
  end
end

# view factors for surfaces to subsurfaces
surfaces.each do |surface|
  sub_surfaces.each do |sub_surface|
    # From surface to subsurface
    zone_property_user_view_factors_by_surface_name.addViewFactor(surface, sub_surface, 0.5)
    # And from subsurface to surface
    zone_property_user_view_factors_by_surface_name.addViewFactor(sub_surface, surface, 0.5)
  end
end

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd,
                            'osm_name' => 'in.osm' })
