import openstudio

# Simply test the example model
openstudio.model.exampleModel().save(openstudio.Path("in.osm"), True)
