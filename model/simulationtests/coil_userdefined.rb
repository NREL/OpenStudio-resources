# frozen_string_literal: true

require 'openstudio'

model = OpenStudio::Model.exampleModel

# get only AirLoopHVAC
airLoop = model.getAirLoopHVACs[0]

# get supplyOutletNode
supplyOutletNode = airLoop.supplyOutletNode()

# Get the single thermal Zone in the model
z = model.getThermalZones[0]

# make CoilUserDefined
coil = OpenStudio::Model::CoilUserDefined.new(model)
coil.setName('coil')
coil.setAmbientZone(z)
coil.addToNode(supplyOutletNode)

coil_Air_Tout = coil.airOutletTemperatureActuator.get
coil_Air_Wout = coil.airOutletHumidityRatioActuator.get
coil_Air_MdotOut = coil.airMassFlowRateActuator.get

# sim program
sim_pgrm = coil.overallSimulationProgram.get
sim_pgrm.setName('Coil_program')
sim_pgrm_body = <<~EMS
  Set #{coil_Air_Tout.handle} = 18
  Set #{coil_Air_Wout.handle} = 0.5
  Set #{coil_Air_MdotOut.handle} = 10
EMS
sim_pgrm.setBody(sim_pgrm_body)

# init program
init_pgrm = coil.initializationSimulationProgram.get
init_pgrm.setName('Coil_init')
init_pgrm_body = <<~EMS
  Set dummy = 0
EMS
init_pgrm.setBody(init_pgrm_body)

# save the OpenStudio model (.osm)
model.save(OpenStudio::Path.new('in.osm'), true)
