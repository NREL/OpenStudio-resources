
require 'openstudio'
require 'lib/baseline_model'

model = BaselineModel.new

#make a 2 story, 100m X 50m, 10 zone core/perimeter building
model.add_geometry({"length" => 100,
              "width" => 50,
              "num_floors" => 2,
              "floor_to_floor_height" => 4,
              "plenum_height" => 1,
              "perimeter_zone_depth" => 3})

#add windows at a 40% window-to-wall ratio
model.add_windows({"wwr" => 0.4,
                  "offset" => 1,
                  "application_type" => "Above Floor"})
        
#add ASHRAE System type 07, VAV w/ Reheat
model.add_hvac({"ashrae_sys_num" => '07'})

zones = model.getThermalZones

i = 0

zones.each do |z|
  if i == 0 
    puts z.name.get
    air_loop = z.airLoopHVAC.get
    air_loop.removeBranchForZone(z)

    schedule = model.alwaysOnDiscreteSchedule()
    new_terminal = OpenStudio::Model::AirTerminalSingleDuctVAVNoReheat.new(model,schedule)
    air_loop.addBranchForZone(z,new_terminal.to_StraightComponent)
  elsif i == 1
    air_loop = z.airLoopHVAC.get
    air_loop.removeBranchForZone(z)

    schedule = model.alwaysOnDiscreteSchedule()
    coil = OpenStudio::Model::CoilHeatingWater.new(model,schedule)
    new_terminal = OpenStudio::Model::AirTerminalSingleDuctConstantVolumeReheat.new(model,schedule,coil)
    air_loop.addBranchForZone(z,new_terminal.to_StraightComponent)

    boiler = model.getBoilerHotWaters.first
    plant = boiler.plantLoop.get

    plant.addDemandBranchForComponent(coil)
  elsif i == 2
    air_loop = z.airLoopHVAC.get
    air_loop.removeBranchForZone(z)

    schedule = model.alwaysOnDiscreteSchedule()
    coil = OpenStudio::Model::CoilHeatingElectric.new(model,schedule)
    new_terminal = OpenStudio::Model::AirTerminalSingleDuctConstantVolumeReheat.new(model,schedule,coil)
    air_loop.addBranchForZone(z,new_terminal.to_StraightComponent)
  elsif i == 3
    air_loop = z.airLoopHVAC.get
    air_loop.removeBranchForZone(z)

    schedule = model.alwaysOnDiscreteSchedule()
    coil = OpenStudio::Model::CoilHeatingGas.new(model,schedule)
    new_terminal = OpenStudio::Model::AirTerminalSingleDuctConstantVolumeReheat.new(model,schedule,coil)
    air_loop.addBranchForZone(z,new_terminal.to_StraightComponent)
  elsif i == 4
    air_loop = z.airLoopHVAC.get
    air_loop.removeBranchForZone(z)

    schedule = model.alwaysOnDiscreteSchedule()
    coil = OpenStudio::Model::CoilHeatingWater.new(model,schedule)
    fan = OpenStudio::Model::FanConstantVolume.new(model,schedule)
    new_terminal = OpenStudio::Model::AirTerminalSingleDuctParallelPIUReheat.new(model,schedule,fan,coil)
    air_loop.addBranchForZone(z,new_terminal.to_StraightComponent)

    boiler = model.getBoilerHotWaters.first
    plant = boiler.plantLoop.get

    plant.addDemandBranchForComponent(coil)
  elsif i == 5
    air_loop = z.airLoopHVAC.get
    air_loop.removeBranchForZone(z)

    schedule = model.alwaysOnDiscreteSchedule()
    coil = OpenStudio::Model::CoilHeatingWater.new(model,schedule)
    fan = OpenStudio::Model::FanConstantVolume.new(model,schedule)
    new_terminal = OpenStudio::Model::AirTerminalSingleDuctSeriesPIUReheat.new(model,fan,coil)
    air_loop.addBranchForZone(z,new_terminal.to_StraightComponent)

    boiler = model.getBoilerHotWaters.first
    plant = boiler.plantLoop.get

    plant.addDemandBranchForComponent(coil)
  elsif i == 6
    air_loop = z.airLoopHVAC.get
    air_loop.removeBranchForZone(z)

    schedule = model.alwaysOnDiscreteSchedule()
    heat_coil = OpenStudio::Model::CoilHeatingWater.new(model,schedule)
    cool_coil = OpenStudio::Model::CoilCoolingWater.new(model,schedule)
    new_terminal = OpenStudio::Model::AirTerminalSingleDuctConstantVolumeFourPipeInduction.new(model,heat_coil)
    new_terminal.setCoolingCoil(cool_coil)
    air_loop.addBranchForZone(z,new_terminal.to_StraightComponent)

    boiler = model.getBoilerHotWaters.first
    plant = boiler.plantLoop.get
    plant.addDemandBranchForComponent(heat_coil)

    chiller = model.getChillerElectricEIRs.first
    plant = chiller.plantLoop.get
    plant.addDemandBranchForComponent(cool_coil)
  end

  i = i + 1
end

#add thermostats
model.add_thermostats({"heating_setpoint" => 24,
                      "cooling_setpoint" => 28})
              
#assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions()

#set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type()  

#add design days to the model (Chicago)
model.add_design_days()
       
#save the OpenStudio model (.osm)
model.save_openstudio_osm({"osm_save_directory" => Dir.pwd,
                           "osm_name" => "out.osm"})
                           
