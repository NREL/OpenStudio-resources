require 'openstudio'


master_autosize = ARGV[1].sub(/--.*=/,'') == 'true' ? true : false

translator = OpenStudio::SDD::SddReverseTranslator.new(master_autosize)

model = translator.loadModel(OpenStudio::Path.new(ARGV[0].sub(/--.*=/,'')))

model.get().save(OpenStudio::Path.new(Dir.pwd + '/out.osm'),true)

