require 'openstudio'
require 'test/unit'


#Simply test the example model
OpenStudio::Model::exampleModel().save(OpenStudio::Path.new("out.osm") , true);


