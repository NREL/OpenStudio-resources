import openstudio

# Simply test the example model
openstudio.model.examplemodel().save(openstudio.Path("in.osm"), True)
