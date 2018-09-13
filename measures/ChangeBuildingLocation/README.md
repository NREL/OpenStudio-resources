

###### (Automatically generated documentation)

# ChangeBuildingLocation

## Description


## Modeler Description


## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Weather File Name
Name of the weather file to change to. This is the filename with the extension (e.g. NewWeather.epw). Optionally this can inclucde the full file path, but for most use cases should just be file name.
**Name:** weather_file_name,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Climate Zone.

**Name:** climate_zone,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Use Upstream Argument Values
When true this will look for arguments or registerValues in upstream measures that match arguments from this measure, and will use the value from the upstream measure in place of what is entered for this measure.
**Name:** use_upstream_args,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false




