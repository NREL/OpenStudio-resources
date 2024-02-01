# frozen_string_literal: true

require 'openstudio'
require_relative 'lib/baseline_model'

m = BaselineModel.new

# make a 1 story, 100m X 50m, 1 zone building
m.add_geometry({ 'length' => 100,
                 'width' => 50,
                 'num_floors' => 1,
                 'floor_to_floor_height' => 4,
                 'plenum_height' => 0,
                 'perimeter_zone_depth' => 0 })

# add windows at a 40% window-to-wall ratio
m.add_windows({ 'wwr' => 0.4,
                'offset' => 1,
                'application_type' => 'Above Floor' })

# add thermostats
m.add_thermostats({ 'heating_setpoint' => 19,
                    'cooling_setpoint' => 26 })

# assign constructions from a local library to the walls/windows/etc. in the model
m.set_constructions

# set whole building space type; simplified 90.1-2004 Large Office Whole Building
m.set_space_type

# add design days to the model (Chicago)
m.add_design_days

def curve_biquadratic(model, c_1constant, c_2x, c_3xPOW2, c_4y, c_5yPOW2, c_6xTIMESY, minx, maxx, miny, maxy)
  curve = OpenStudio::Model::CurveBiquadratic.new(model)
  curve.setCoefficient1Constant(c_1constant)
  curve.setCoefficient2x(c_2x)
  curve.setCoefficient3xPOW2(c_3xPOW2)
  curve.setCoefficient4y(c_4y)
  curve.setCoefficient5yPOW2(c_5yPOW2)
  curve.setCoefficient6xTIMESY(c_6xTIMESY)
  curve.setMinimumValueofx(minx)
  curve.setMaximumValueofx(maxx)
  curve.setMinimumValueofy(miny)
  curve.setMaximumValueofy(maxy)
  return curve
end

def curve_cubic(model, c_1constant, c_2x, c_3xPOW2, c_4xPOW3, minx, maxx)
  curve = OpenStudio::Model::CurveCubic.new(model)
  curve.setCoefficient1Constant(c_1constant)
  curve.setCoefficient2x(c_2x)
  curve.setCoefficient3xPOW2(c_3xPOW2)
  curve.setCoefficient4xPOW3(c_4xPOW3)
  curve.setMinimumValueofx(minx)
  curve.setMaximumValueofx(maxx)
  return curve
end

def curve_quadratic(model, c_1constant, c_2x, c_3xPOW2, minx = nil, maxx = nil, miny = nil, maxy = nil)
  curve = OpenStudio::Model::CurveQuadratic.new(model)
  curve.setCoefficient1Constant(c_1constant)
  curve.setCoefficient2x(c_2x)
  curve.setCoefficient3xPOW2(c_3xPOW2)
  curve.setMinimumValueofx(minx) if !minx.nil?
  curve.setMaximumValueofx(maxx) if !maxx.nil?
  curve.setMinimumCurveOutput(miny) if !miny.nil?
  curve.setMaximumCurveOutput(maxy) if !maxy.nil?
  return curve
end

def curve_triquadratic(model, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14, c15, c16, c17, c18, c19, c20, c21, c22, c23, c24, c25, c26, c27, minx, maxx, miny, maxy, minz, maxz)
  curve = OpenStudio::Model::CurveTriquadratic.new(model)
  curve.setCoefficient1Constant(c1)
  curve.setCoefficient2xPOW2(c2)
  curve.setCoefficient3x(c3)
  curve.setCoefficient4yPOW2(c4)
  curve.setCoefficient5y(c5)
  curve.setCoefficient6zPOW2(c6)
  curve.setCoefficient7z(c7)
  curve.setCoefficient8xPOW2TIMESYPOW2(c8)
  curve.setCoefficient9xTIMESY(c9)
  curve.setCoefficient10xTIMESYPOW2(c10)
  curve.setCoefficient11xPOW2TIMESY(c11)
  curve.setCoefficient12xPOW2TIMESZPOW2(c12)
  curve.setCoefficient13xTIMESZ(c13)
  curve.setCoefficient14xTIMESZPOW2(c14)
  curve.setCoefficient15xPOW2TIMESZ(c15)
  curve.setCoefficient16yPOW2TIMESZPOW2(c16)
  curve.setCoefficient17yTIMESZ(c17)
  curve.setCoefficient18yTIMESZPOW2(c18)
  curve.setCoefficient19yPOW2TIMESZ(c19)
  curve.setCoefficient20xPOW2TIMESYPOW2TIMESZPOW2(c20)
  curve.setCoefficient21xPOW2TIMESYPOW2TIMESZ(c21)
  curve.setCoefficient22xPOW2TIMESYTIMESZPOW2(c22)
  curve.setCoefficient23xTIMESYPOW2TIMESZPOW2(c23)
  curve.setCoefficient24xPOW2TIMESYTIMESZ(c24)
  curve.setCoefficient25xTIMESYPOW2TIMESZ(c25)
  curve.setCoefficient26xTIMESYTIMESZPOW2(c26)
  curve.setCoefficient27xTIMESYTIMESZ(c27)
  curve.setMinimumValueofx(minx)
  curve.setMaximumValueofx(maxx)
  curve.setMinimumValueofy(miny)
  curve.setMaximumValueofy(maxy)
  curve.setMinimumValueofz(minz)
  curve.setMaximumValueofz(maxz)
  return curve
end

def curve_table_lookup_cool_charge_cool_cap_ft(model)
  curve = OpenStudio::Model::TableLookup.new(model)

  ind_var_1 = OpenStudio::Model::TableIndependentVariable.new(model)
  ind_var_1.setInterpolationMethod('Cubic')
  ind_var_1.setExtrapolationMethod('Linear')
  ind_var_1.setMinimumValue(-100.0)
  ind_var_1.setMaximumValue(100.0)
  ind_var_1.setUnitType('Temperature')
  ind_var_1.setValues([-100, 100])

  ind_var_2 = OpenStudio::Model::TableIndependentVariable.new(model)
  ind_var_2.setInterpolationMethod('Cubic')
  ind_var_2.setExtrapolationMethod('Linear')
  ind_var_2.setMinimumValue(-30.0)
  ind_var_2.setMaximumValue(50.0)
  ind_var_2.setUnitType('Temperature')
  ind_var_2.setValues([-30, -22, -14, -6, 2, 10, 18, 26, 34, 42, 50])

  ind_var_3 = OpenStudio::Model::TableIndependentVariable.new(model)
  ind_var_3.setInterpolationMethod('Cubic')
  ind_var_3.setExtrapolationMethod('Linear')
  ind_var_3.setMinimumValue(0.0)
  ind_var_3.setMaximumValue(1.0)
  ind_var_3.setUnitType('Dimensionless')
  ind_var_3.setValues([0.0000, 0.0165, 0.0330, 0.0495, 0.0660, 0.0825, 0.0990, 0.1155, 0.1320, 0.1485, 0.1650, 0.2485, 0.3320, 0.4155, 0.4990, 0.5825, 0.6660, 0.7495, 0.8330, 0.9165, 1.0000])
  
  curve.addIndependentVariable(ind_var_1)
  curve.addIndependentVariable(ind_var_2)
  curve.addIndependentVariable(ind_var_3)

  curve.setNormalizationMethod('DivisorOnly')
  curve.setNormalizationDivisor(1.0)
  curve.setMinimumOutput(0.5)
  curve.setMaximumOutput(1.5)
  curve.setOutputUnitType('Dimensionless')
  curve.setOutputValues([1.693105221,             
    1.65848016210929,        
    1.62689311200718,        
    1.59834407069365,        
    1.57283303816872,        
    1.55036001443237,        
    1.53092499948461,        
    1.51452799332544,        
    1.50116899595486,        
    1.49084800737287,        
    1.61101464972482,        
    1.59576309127151,        
    1.58080905736949,        
    1.56615254801876,        
    1.55179356321934,        
    1.53773210297121,        
    1.52396816727437,        
    1.51050175612883,        
    1.49733286953459,        
    1.48446150749165,        
    1.47188767,              
    1.702120005,             
    1.66819694468129,        
    1.63731189315118,        
    1.60946485040965,        
    1.58465581645672,        
    1.56288479129237,        
    1.54415177491661,        
    1.52845676732944,        
    1.51579976853086,        
    1.50618077852087,        
    1.59047099356482,        
    1.57623934552751,        
    1.56230522204149,        
    1.54866862310676,        
    1.53532954872334,        
    1.52228799889121,        
    1.50954397361037,        
    1.49709747288083,        
    1.48494849670259,        
    1.47309704507565,        
    1.461543118,             
    1.690907589,             
    1.65768652725329,        
    1.62750347429518,        
    1.60035843012565,        
    1.57625139474472,        
    1.55518236815237,        
    1.53715135034861,        
    1.52215834133344,        
    1.51020334110686,        
    1.50128634966887,        
    1.55554116140482,        
    1.54232942378351,        
    1.52941521071349,        
    1.51679852219476,        
    1.50447935822734,        
    1.49245771881121,        
    1.48073360394637,        
    1.46930701363283,        
    1.45817794787059,        
    1.44734640665965,        
    1.43681239,              
    1.659467973,             
    1.62694890982529,        
    1.59746785543918,        
    1.57102480984165,        
    1.54761977303272,        
    1.52725274501237,        
    1.50992372578061,        
    1.49563271533744,        
    1.48437971368286,        
    1.47616472081687,        
    1.50622515324482,        
    1.49403332603951,        
    1.48213902338549,        
    1.47054224528276,        
    1.45924299173134,        
    1.44824126273121,        
    1.43753705828237,        
    1.42713037838483,        
    1.41702122303859,        
    1.40720959224365,        
    1.397695486,             
    1.607801157,             
    1.57598409239729,        
    1.54720503658318,        
    1.52146398955765,        
    1.49876095132072,        
    1.47909592187237,        
    1.46246890121261,        
    1.44887988934144,        
    1.43832888625886,        
    1.43081589196487,        
    1.44252296908482,        
    1.43135105229551,        
    1.42047666005749,        
    1.40989979237076,        
    1.39962044923534,        
    1.38963863065121,        
    1.37995433661837,        
    1.37056756713683,        
    1.36147832220659,        
    1.35268660182765,        
    1.344192406,             
    1.535907141,             
    1.50479207496929,        
    1.47671501772718,        
    1.45167596927365,        
    1.42967492960872,        
    1.41071189873237,        
    1.39478687664461,        
    1.38189986334544,        
    1.37205085883486,        
    1.36523986311287,        
    1.36443460892483,        
    1.35428260255151,        
    1.34442812072949,        
    1.33487116345876,        
    1.32561173073934,        
    1.31664982257121,        
    1.30798543895437,        
    1.29961857988883,        
    1.29154924537459,        
    1.28377743541165,        
    1.27630315,              
    1.443785925,             
    1.41337285754129,        
    1.38599779887118,        
    1.36166074898965,        
    1.34036170789672,        
    1.32210067559237,        
    1.30687765207661,        
    1.29469263734944,        
    1.28554563141086,        
    1.27943663426087,        
    1.27196007276482,        
    1.26282797680751,        
    1.25399340540149,        
    1.24545635854676,        
    1.23721683624334,        
    1.22927483849121,        
    1.22163036529037,        
    1.21428341664083,        
    1.20723399254259,        
    1.20048209299565,        
    1.194027718,             
    1.331437509,             
    1.30172644011329,        
    1.27505338001518,        
    1.25141832870565,        
    1.23082128618472,        
    1.21326225245237,        
    1.19874122750861,        
    1.18725821135344,        
    1.17881320398686,        
    1.17340620540887,        
    1.16509936060482,        
    1.15698717506351,        
    1.14917251407349,        
    1.14165537763476,        
    1.13443576574734,        
    1.12751367841121,        
    1.12088911562637,        
    1.11456207739283,        
    1.10853256371059,        
    1.10280057457965,        
    1.09736611,              
    1.198861893,             
    1.16985282268529,        
    1.14388176115918,        
    1.12094870842165,        
    1.10105366447272,        
    1.08419662931237,        
    1.07037760294061,        
    1.05959658535744,        
    1.05185357656286,        
    1.04714857655687,        
    1.04385247244483,        
    1.03676019731951,        
    1.02996544674549,        
    1.02346822072276,        
    1.01726851925134,        
    1.01136634233121,        
    1.00576168996237,        
    1.00045456214483,        
    0.995444958878593,       
    0.990732880163648,       
    0.986318326,             
    1.046059077,             
    1.01775200525729,        
    0.992482942303179,       
    0.970251888137653,       
    0.951058842760716,       
    0.934903806172369,       
    0.921786778372611,       
    0.911707759361443,       
    0.904666749138864,       
    0.900663747704875,       
    0.908219408284825,       
    0.902147043575508,       
    0.896372203417488,       
    0.890894887810764,       
    0.885715096755337,       
    0.880832830251206,       
    0.876248088298372,       
    0.871960870896834,       
    0.867971178046593,       
    0.864279009747648,       
    0.860884366,             
    0.873029061,             
    0.845423987829295,       
    0.820856923447179,       
    0.799327867853653,       
    0.780836821048716,       
    0.765383783032369,       
    0.752968753804611,       
    0.743591733365443,       
    0.737252721714864,       
    0.733951718852875,       
    0.758200168124825,       
    0.753147713831508,       
    0.748392784089488,       
    0.743935378898764,       
    0.739775498259337,       
    0.735913142171206,       
    0.732348310634372,       
    0.729081003648834,       
    0.726111221214593,       
    0.723438963331648,       
    0.72106423,              
    1.693105221,             
    1.65848016210929,        
    1.62689311200718,        
    1.59834407069365,        
    1.57283303816872,        
    1.55036001443237,        
    1.53092499948461,        
    1.51452799332544,        
    1.50116899595486,        
    1.49084800737287,        
    1.61101464972482,        
    1.59576309127151,        
    1.58080905736949,        
    1.56615254801876,        
    1.55179356321934,        
    1.53773210297121,        
    1.52396816727437,        
    1.51050175612883,        
    1.49733286953459,        
    1.48446150749165,        
    1.47188767,              
    1.702120005,             
    1.66819694468129,        
    1.63731189315118,        
    1.60946485040965,        
    1.58465581645672,        
    1.56288479129237,        
    1.54415177491661,        
    1.52845676732944,        
    1.51579976853086,        
    1.50618077852087,        
    1.59047099356482,        
    1.57623934552751,        
    1.56230522204149,        
    1.54866862310676,        
    1.53532954872334,        
    1.52228799889121,        
    1.50954397361037,        
    1.49709747288083,        
    1.48494849670259,        
    1.47309704507565,        
    1.461543118,             
    1.690907589,             
    1.65768652725329,        
    1.62750347429518,        
    1.60035843012565,        
    1.57625139474472,        
    1.55518236815237,        
    1.53715135034861,        
    1.52215834133344,        
    1.51020334110686,        
    1.50128634966887,        
    1.55554116140482,        
    1.54232942378351,        
    1.52941521071349,        
    1.51679852219476,        
    1.50447935822734,        
    1.49245771881121,        
    1.48073360394637,        
    1.46930701363283,        
    1.45817794787059,        
    1.44734640665965,        
    1.43681239,              
    1.659467973,             
    1.62694890982529,        
    1.59746785543918,        
    1.57102480984165,        
    1.54761977303272,        
    1.52725274501237,        
    1.50992372578061,        
    1.49563271533744,        
    1.48437971368286,        
    1.47616472081687,        
    1.50622515324482,        
    1.49403332603951,        
    1.48213902338549,        
    1.47054224528276,        
    1.45924299173134,        
    1.44824126273121,        
    1.43753705828237,        
    1.42713037838483,        
    1.41702122303859,        
    1.40720959224365,        
    1.397695486,             
    1.607801157,             
    1.57598409239729,        
    1.54720503658318,        
    1.52146398955765,        
    1.49876095132072,        
    1.47909592187237,        
    1.46246890121261,        
    1.44887988934144,        
    1.43832888625886,        
    1.43081589196487,        
    1.44252296908482,        
    1.43135105229551,        
    1.42047666005749,        
    1.40989979237076,        
    1.39962044923534,        
    1.38963863065121,        
    1.37995433661837,        
    1.37056756713683,        
    1.36147832220659,        
    1.35268660182765,        
    1.344192406,             
    1.535907141,             
    1.50479207496929,        
    1.47671501772718,        
    1.45167596927365,        
    1.42967492960872,        
    1.41071189873237,        
    1.39478687664461,        
    1.38189986334544,        
    1.37205085883486,        
    1.36523986311287,        
    1.36443460892483,        
    1.35428260255151,        
    1.34442812072949,        
    1.33487116345876,        
    1.32561173073934,        
    1.31664982257121,        
    1.30798543895437,        
    1.29961857988883,        
    1.29154924537459,        
    1.28377743541165,        
    1.27630315,              
    1.443785925,             
    1.41337285754129,        
    1.38599779887118,        
    1.36166074898965,        
    1.34036170789672,        
    1.32210067559237,        
    1.30687765207661,        
    1.29469263734944,        
    1.28554563141086,        
    1.27943663426087,        
    1.27196007276482,        
    1.26282797680751,        
    1.25399340540149,        
    1.24545635854676,        
    1.23721683624334,        
    1.22927483849121,        
    1.22163036529037,        
    1.21428341664083,        
    1.20723399254259,        
    1.20048209299565,        
    1.194027718,             
    1.331437509,             
    1.30172644011329,        
    1.27505338001518,        
    1.25141832870565,        
    1.23082128618472,        
    1.21326225245237,        
    1.19874122750861,        
    1.18725821135344,        
    1.17881320398686,        
    1.17340620540887,        
    1.16509936060482,        
    1.15698717506351,        
    1.14917251407349,        
    1.14165537763476,        
    1.13443576574734,        
    1.12751367841121,        
    1.12088911562637,        
    1.11456207739283,        
    1.10853256371059,        
    1.10280057457965,        
    1.09736611,              
    1.198861893,             
    1.16985282268529,        
    1.14388176115918,        
    1.12094870842165,        
    1.10105366447272,        
    1.08419662931237,        
    1.07037760294061,        
    1.05959658535744,        
    1.05185357656286,        
    1.04714857655687,        
    1.04385247244483,        
    1.03676019731951,        
    1.02996544674549,        
    1.02346822072276,        
    1.01726851925134,        
    1.01136634233121,        
    1.00576168996237,        
    1.00045456214483,        
    0.995444958878593,       
    0.990732880163648,       
    0.986318326,             
    1.046059077,             
    1.01775200525729,        
    0.992482942303179,       
    0.970251888137653,       
    0.951058842760716,       
    0.934903806172369,       
    0.921786778372611,       
    0.911707759361443,       
    0.904666749138864,       
    0.900663747704875,       
    0.908219408284825,       
    0.902147043575508,       
    0.896372203417488,       
    0.890894887810764,       
    0.885715096755337,       
    0.880832830251206,       
    0.876248088298372,       
    0.871960870896834,       
    0.867971178046593,       
    0.864279009747648,       
    0.860884366,             
    0.873029061,             
    0.845423987829295,       
    0.820856923447179,       
    0.799327867853653,       
    0.780836821048716,       
    0.765383783032369,       
    0.752968753804611,       
    0.743591733365443,       
    0.737252721714864,       
    0.733951718852875,       
    0.758200168124825,       
    0.753147713831508,       
    0.748392784089488,       
    0.743935378898764,       
    0.739775498259337,       
    0.735913142171206,       
    0.732348310634372,       
    0.729081003648834,       
    0.726111221214593,       
    0.723438963331648,       
    0.72106423])

  return curve
end

def curve_table_lookup_cool_charge_cool_eir_ft(model)
  curve = OpenStudio::Model::TableLookup.new(model)

  ind_var_1 = OpenStudio::Model::TableIndependentVariable.new(model)
  ind_var_1.setInterpolationMethod('Cubic')
  ind_var_1.setExtrapolationMethod('Linear')
  ind_var_1.setMinimumValue(-100.0)
  ind_var_1.setMaximumValue(100.0)
  ind_var_1.setUnitType('Temperature')
  ind_var_1.setValues([-100, 100])

  ind_var_2 = OpenStudio::Model::TableIndependentVariable.new(model)
  ind_var_2.setInterpolationMethod('Cubic')
  ind_var_2.setExtrapolationMethod('Linear')
  ind_var_2.setMinimumValue(-30.0)
  ind_var_2.setMaximumValue(50.0)
  ind_var_2.setUnitType('Temperature')
  ind_var_2.setValues([-30, -22, -14, -6, 2, 10, 18, 26, 34, 42, 50])

  ind_var_3 = OpenStudio::Model::TableIndependentVariable.new(model)
  ind_var_3.setInterpolationMethod('Cubic')
  ind_var_3.setExtrapolationMethod('Linear')
  ind_var_3.setMinimumValue(0.0)
  ind_var_3.setMaximumValue(1.0)
  ind_var_3.setUnitType('Dimensionless')
  ind_var_3.setValues([0.0000, 0.0165, 0.0330, 0.0495, 0.0660, 0.0825, 0.0990, 0.1155, 0.1320, 0.1485, 0.1650, 0.2485, 0.3320, 0.4155, 0.4990, 0.5825, 0.6660, 0.7495, 0.8330, 0.9165, 1.0000])
  
  curve.addIndependentVariable(ind_var_1)
  curve.addIndependentVariable(ind_var_2)
  curve.addIndependentVariable(ind_var_3)

  curve.setNormalizationMethod('DivisorOnly')
  curve.setNormalizationDivisor(1.0)
  curve.setMinimumOutput(0.5)
  curve.setMaximumOutput(2.5)
  curve.setOutputUnitType('Dimensionless')
  curve.setOutputValues([0.992306693,             
    0.993205787535399,       
    0.993576451780598,       
    0.993418685735596,       
    0.992732489400392,       
    0.991517862774987,       
    0.989774805859382,       
    0.987503318653576,       
    0.984703401157568,       
    0.981375053371359,       
    0.87213395701435,        
    0.870598684342923,       
    0.869046873020384,       
    0.867478523046732,       
    0.865893634421966,       
    0.864292207146087,       
    0.862674241219096,       
    0.861039736640991,       
    0.859388693411774,       
    0.857721111531443,       
    0.856036991,             
    0.752399557,             
    0.754439488331399,       
    0.755950989372598,       
    0.756934060123595,       
    0.757388700584392,       
    0.757314910754987,       
    0.756712690635382,       
    0.755582040225575,       
    0.753922959525568,       
    0.75173544853536,        
    0.67278144081435,        
    0.672013042162923,       
    0.671228104860384,       
    0.670426628906732,       
    0.669608614301966,       
    0.668774061046087,       
    0.667922969139096,       
    0.667055338580991,       
    0.666171169371774,       
    0.665270461511444,       
    0.664353215,             
    0.576753285,             
    0.579934053127399,       
    0.582586390964598,       
    0.584710298511595,       
    0.586305775768392,       
    0.587372822734987,       
    0.587911439411382,       
    0.587921625797575,       
    0.587403381893568,       
    0.586356707699359,       
    0.53303814061435,        
    0.533036615982924,       
    0.533018552700384,       
    0.532983950766732,       
    0.532932810181966,       
    0.532865130946087,       
    0.532780913059096,       
    0.532680156520991,       
    0.532562861331774,       
    0.532429027491444,       
    0.532278655,             
    0.465367877,             
    0.469689481923399,       
    0.473482656556598,       
    0.476747400899595,       
    0.479483714952392,       
    0.481691598714988,       
    0.483371052187382,       
    0.484522075369576,       
    0.485144668261568,       
    0.48523883086336,        
    0.45290405641435,        
    0.453669405802923,       
    0.454418216540384,       
    0.455150488626731,       
    0.455866222061966,       
    0.456565416846087,       
    0.457248072979096,       
    0.457914190460991,       
    0.458563769291774,       
    0.459196809471443,       
    0.459813311,             
    0.418243333,             
    0.423705774719399,       
    0.428639786148598,       
    0.433045367287595,       
    0.436922518136392,       
    0.440271238694988,       
    0.443091528963382,       
    0.445383388941575,       
    0.447146818629568,       
    0.448381818027359,       
    0.43237918821435,        
    0.433911411622924,       
    0.435427096380384,       
    0.436926242486732,       
    0.438408849941966,       
    0.439874918746087,       
    0.441324448899096,       
    0.442757440400992,       
    0.444173893251774,       
    0.445573807451443,       
    0.446957183,             
    0.435379653,             
    0.4419829315154,         
    0.448057779740598,       
    0.453604197675596,       
    0.458622185320392,       
    0.463111742674988,       
    0.467072869739382,       
    0.470505566513576,       
    0.473409832997568,       
    0.47578566919136,        
    0.47146353601435,        
    0.473762633442923,       
    0.476045192220384,       
    0.478311212346732,       
    0.480560693821966,       
    0.482793636646087,       
    0.485010040819096,       
    0.487209906340991,       
    0.489393233211774,       
    0.491560021431443,       
    0.493710271,             
    0.516776837,             
    0.5245209523114,         
    0.531736637332598,       
    0.538423892063595,       
    0.544582716504392,       
    0.550213110654987,       
    0.555315074515382,       
    0.559888608085576,       
    0.563933711365568,       
    0.567450384355359,       
    0.57015709981435,        
    0.573223071262923,       
    0.576272504060384,       
    0.579305398206732,       
    0.582321753701966,       
    0.585321570546087,       
    0.588304848739096,       
    0.591271588280991,       
    0.594221789171774,       
    0.597155451411444,       
    0.600072575,             
    0.662434885,             
    0.6713198371074,         
    0.679676358924598,       
    0.687504450451595,       
    0.694804111688392,       
    0.701575342634988,       
    0.707818143291382,       
    0.713532513657576,       
    0.718718453733568,       
    0.72337596351936,        
    0.72845987961435,        
    0.732292725082924,       
    0.736109031900384,       
    0.739908800066732,       
    0.743692029581966,       
    0.747458720446088,       
    0.751208872659096,       
    0.754942486220991,       
    0.758659561131774,       
    0.762360097391444,       
    0.766044095,             
    0.872353797,             
    0.882379585903399,       
    0.891876944516598,       
    0.900845872839595,       
    0.909286370872392,       
    0.917198438614988,       
    0.924582076067382,       
    0.931437283229576,       
    0.937764060101568,       
    0.94356240668336,        
    0.94637187541435,        
    0.950971594902923,       
    0.955554775740384,       
    0.960121417926732,       
    0.964671521461966,       
    0.969205086346087,       
    0.973722112579096,       
    0.978222600160991,       
    0.982706549091774,       
    0.987173959371443,       
    0.991624831,             
    1.146533573,             
    1.1577001986994,         
    1.1683383941086,         
    1.1784481592276,         
    1.18802949405639,        
    1.19708239859499,        
    1.20560687284338,        
    1.21360291680158,        
    1.22107053046957,        
    1.22800971384736,        
    1.22389308721435,        
    1.22925968072292,        
    1.23460973558038,        
    1.23994325178673,        
    1.24526022934197,        
    1.25056066824609,        
    1.2558445684991,         
    1.26111193010099,        
    1.26636275305177,        
    1.27159703735144,        
    1.276814783,             
    1.484974213,             
    1.4972816754954,         
    1.5090607077006,         
    1.5203113096156,         
    1.53103348124039,        
    1.54122722257499,        
    1.55089253361938,        
    1.56002941437358,        
    1.56863786483757,        
    1.57671788501136,        
    1.56102351501435,        
    1.56715698254292,        
    1.57327391142038,        
    1.57937430164673,        
    1.58545815322197,        
    1.59152546614609,        
    1.5975762404191,         
    1.60361047604099,        
    1.60962817301177,        
    1.61562933133144,        
    1.621613951,             
    0.992306693,             
    0.993205787535399,       
    0.993576451780598,       
    0.993418685735596,       
    0.992732489400392,       
    0.991517862774987,       
    0.989774805859382,       
    0.987503318653576,       
    0.984703401157568,       
    0.981375053371359,       
    0.87213395701435,        
    0.870598684342923,       
    0.869046873020384,       
    0.867478523046732,       
    0.865893634421966,       
    0.864292207146087,       
    0.862674241219096,       
    0.861039736640991,       
    0.859388693411774,       
    0.857721111531443,       
    0.856036991,             
    0.752399557,             
    0.754439488331399,       
    0.755950989372598,       
    0.756934060123595,       
    0.757388700584392,       
    0.757314910754987,       
    0.756712690635382,       
    0.755582040225575,       
    0.753922959525568,       
    0.75173544853536,        
    0.67278144081435,        
    0.672013042162923,       
    0.671228104860384,       
    0.670426628906732,       
    0.669608614301966,       
    0.668774061046087,       
    0.667922969139096,       
    0.667055338580991,       
    0.666171169371774,       
    0.665270461511444,       
    0.664353215,             
    0.576753285,             
    0.579934053127399,       
    0.582586390964598,       
    0.584710298511595,       
    0.586305775768392,       
    0.587372822734987,       
    0.587911439411382,       
    0.587921625797575,       
    0.587403381893568,       
    0.586356707699359,       
    0.53303814061435,        
    0.533036615982924,       
    0.533018552700384,       
    0.532983950766732,       
    0.532932810181966,       
    0.532865130946087,       
    0.532780913059096,       
    0.532680156520991,       
    0.532562861331774,       
    0.532429027491444,       
    0.532278655,             
    0.465367877,             
    0.469689481923399,       
    0.473482656556598,       
    0.476747400899595,       
    0.479483714952392,       
    0.481691598714988,       
    0.483371052187382,       
    0.484522075369576,       
    0.485144668261568,       
    0.48523883086336,        
    0.45290405641435,        
    0.453669405802923,       
    0.454418216540384,       
    0.455150488626731,       
    0.455866222061966,       
    0.456565416846087,       
    0.457248072979096,       
    0.457914190460991,       
    0.458563769291774,       
    0.459196809471443,       
    0.459813311,             
    0.418243333,             
    0.423705774719399,       
    0.428639786148598,       
    0.433045367287595,       
    0.436922518136392,       
    0.440271238694988,       
    0.443091528963382,       
    0.445383388941575,       
    0.447146818629568,       
    0.448381818027359,       
    0.43237918821435,        
    0.433911411622924,       
    0.435427096380384,       
    0.436926242486732,       
    0.438408849941966,       
    0.439874918746087,       
    0.441324448899096,       
    0.442757440400992,       
    0.444173893251774,       
    0.445573807451443,       
    0.446957183,             
    0.435379653,             
    0.4419829315154,         
    0.448057779740598,       
    0.453604197675596,       
    0.458622185320392,       
    0.463111742674988,       
    0.467072869739382,       
    0.470505566513576,       
    0.473409832997568,       
    0.47578566919136,        
    0.47146353601435,        
    0.473762633442923,       
    0.476045192220384,       
    0.478311212346732,       
    0.480560693821966,       
    0.482793636646087,       
    0.485010040819096,       
    0.487209906340991,       
    0.489393233211774,       
    0.491560021431443,       
    0.493710271,             
    0.516776837,             
    0.5245209523114,         
    0.531736637332598,       
    0.538423892063595,       
    0.544582716504392,       
    0.550213110654987,       
    0.555315074515382,       
    0.559888608085576,       
    0.563933711365568,       
    0.567450384355359,       
    0.57015709981435,        
    0.573223071262923,       
    0.576272504060384,       
    0.579305398206732,       
    0.582321753701966,       
    0.585321570546087,       
    0.588304848739096,       
    0.591271588280991,       
    0.594221789171774,       
    0.597155451411444,       
    0.600072575,             
    0.662434885,             
    0.6713198371074,         
    0.679676358924598,       
    0.687504450451595,       
    0.694804111688392,       
    0.701575342634988,       
    0.707818143291382,       
    0.713532513657576,       
    0.718718453733568,       
    0.72337596351936,        
    0.72845987961435,        
    0.732292725082924,       
    0.736109031900384,       
    0.739908800066732,       
    0.743692029581966,       
    0.747458720446088,       
    0.751208872659096,       
    0.754942486220991,       
    0.758659561131774,       
    0.762360097391444,       
    0.766044095,             
    0.872353797,             
    0.882379585903399,       
    0.891876944516598,       
    0.900845872839595,       
    0.909286370872392,       
    0.917198438614988,       
    0.924582076067382,       
    0.931437283229576,       
    0.937764060101568,       
    0.94356240668336,        
    0.94637187541435,        
    0.950971594902923,       
    0.955554775740384,       
    0.960121417926732,       
    0.964671521461966,       
    0.969205086346087,       
    0.973722112579096,       
    0.978222600160991,       
    0.982706549091774,       
    0.987173959371443,       
    0.991624831,             
    1.146533573,             
    1.1577001986994,         
    1.1683383941086,         
    1.1784481592276,         
    1.18802949405639,        
    1.19708239859499,        
    1.20560687284338,        
    1.21360291680158,        
    1.22107053046957,        
    1.22800971384736,        
    1.22389308721435,        
    1.22925968072292,        
    1.23460973558038,        
    1.23994325178673,        
    1.24526022934197,        
    1.25056066824609,        
    1.2558445684991,         
    1.26111193010099,        
    1.26636275305177,        
    1.27159703735144,        
    1.276814783,             
    1.484974213,             
    1.4972816754954,         
    1.5090607077006,         
    1.5203113096156,         
    1.53103348124039,        
    1.54122722257499,        
    1.55089253361938,        
    1.56002941437358,        
    1.56863786483757,        
    1.57671788501136,        
    1.56102351501435,        
    1.56715698254292,        
    1.57327391142038,        
    1.57937430164673,        
    1.58545815322197,        
    1.59152546614609,        
    1.5975762404191,         
    1.60361047604099,        
    1.60962817301177,        
    1.61562933133144,        
    1.621613951])

  return curve
end

# RetailPackagedTESCoil.idf

# CoilCoolingDXSingleSpeedThermalStorage
coil = OpenStudio::Model::CoilCoolingDXSingleSpeedThermalStorage.new(m)
coil.setAvailabilitySchedule(m.alwaysOnDiscreteSchedule)
coil.setOperatingModeControlMethod('EMSControlled')
coil.setStorageType('Ice')
coil.autocalculateIceStorageCapacity
coil.setStorageCapacitySizingFactor(6.0)
coil.setStorageTanktoAmbientUvalueTimesAreaHeatTransferCoefficient(7.913)
coil.autosizeRatedEvaporatorAirFlowRate
coil.setAncillaryElectricPower(0.0)
coil.setColdWeatherOperationMinimumOutdoorAirTemperature(2.0)
coil.setColdWeatherOperationAncillaryPower(0.0)
coil.setCondenserAirFlowSizingFactor(1.25)
coil.setCondenserType('AirCooled')
coil.setEvaporativeCondenserEffectiveness(0.7)
coil.setEvaporativeCondenserPumpRatedPowerConsumption(0)
coil.setBasinHeaterCapacity(0)
coil.setBasinHeaterSetpointTemperature(2)

# Cooling Only Mode = Yes
coil.setCoolingOnlyModeAvailable(true)
coil.autosizeCoolingOnlyModeRatedTotalEvaporatorCoolingCapacity
coil.setCoolingOnlyModeRatedSensibleHeatRatio(0.7)
coil.setCoolingOnlyModeRatedCOP(3.50015986358308)
cool_cap_ft = curve_biquadratic(m, 0.9712123, -0.015275502, 0.0014434524, -0.00039321, -0.0000068364, -0.0002905956, -100, 100, -100, 100)
constant_cubic = curve_cubic(m, 1, 0, 0, 0, -100, 100)
cool_eir_ft = curve_biquadratic(m, 0.28687133, 0.023902164, -0.000810648, 0.013458546, 0.0003389364, -0.0004870044, -100, 100, -100, 100)
cool_plf_fplr = curve_quadratic(m, 0.90949556, 0.09864773, -0.00819488, 0, 1, 0.7, 1)
cool_shr_ft = curve_biquadratic(m, 1.3294540786, -0.0990649255, 0.0008310043, 0.0652277735, -0.0000793358, -0.0005874422, 24.44, 26.67, 29.44, 46.1)
cool_shr_fff = curve_quadratic(m, 0.9317, -0.0077, 0.0760, 0.69, 1.30)
coil.setCoolingOnlyModeTotalEvaporatorCoolingCapacityFunctionofTemperatureCurve(cool_cap_ft)
coil.setCoolingOnlyModeTotalEvaporatorCoolingCapacityFunctionofFlowFractionCurve(constant_cubic)
coil.setCoolingOnlyModeEnergyInputRatioFunctionofTemperatureCurve(cool_eir_ft)
coil.setCoolingOnlyModeEnergyInputRatioFunctionofFlowFractionCurve(constant_cubic)
coil.setCoolingOnlyModePartLoadFractionCorrelationCurve(cool_plf_fplr)
coil.setCoolingOnlyModeSensibleHeatRatioFunctionofTemperatureCurve(cool_shr_ft)
coil.setCoolingOnlyModeSensibleHeatRatioFunctionofFlowFractionCurve(cool_shr_fff)

# Cooling And Charge Mode = Yes
coil.setCoolingAndChargeModeAvailable(true)
coil.autocalculateCoolingAndChargeModeRatedTotalEvaporatorCoolingCapacity
coil.setCoolingAndChargeModeCapacitySizingFactor(1.0)
coil.autocalculateCoolingAndChargeModeRatedStorageChargingCapacity
coil.setCoolingAndChargeModeStorageCapacitySizingFactor(0.86)
coil.setCoolingAndChargeModeRatedSensibleHeatRatio(0.7)
coil.setCoolingAndChargeModeCoolingRatedCOP(3.66668442928701)
coil.setCoolingAndChargeModeChargingRatedCOP(2.17)
cool_charge_cool_cap_ft = curve_triquadratic(m, 0.9712123, 0.0014434524, -0.015275502, -0.0000068364, -0.00039321, 0.0, 0.0, 0.0, -0.0002905956, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -100, 100, -100, 100, -100, 100)
cool_charge_cool_eir_ft = curve_triquadratic(m, 0.28687133, -0.000810648, 0.023902164, 0.0003389364, 0.013458546, 0.0, 0.0, 0.0, -0.0004870044, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -100, 100, -100, 100, -100, 100)
cool_charge_charge_cap_ft = curve_table_lookup_cool_charge_cool_cap_ft(m)
cool_charge_charge_eir_ft = curve_table_lookup_cool_charge_cool_eir_ft(m)
coil.setCoolingAndChargeModeTotalEvaporatorCoolingCapacityFunctionofTemperatureCurve(cool_charge_cool_cap_ft)
coil.setCoolingAndChargeModeTotalEvaporatorCoolingCapacityFunctionofFlowFractionCurve(constant_cubic)
coil.setCoolingAndChargeModeEvaporatorEnergyInputRatioFunctionofTemperatureCurve(cool_charge_cool_eir_ft)
coil.setCoolingAndChargeModeEvaporatorEnergyInputRatioFunctionofFlowFractionCurve(constant_cubic)
coil.setCoolingAndChargeModeEvaporatorPartLoadFractionCorrelationCurve(cool_plf_fplr)
coil.setCoolingAndChargeModeStorageChargeCapacityFunctionofTemperatureCurve(cool_charge_charge_cap_ft)
coil.setCoolingAndChargeModeStorageChargeCapacityFunctionofTotalEvaporatorPLRCurve(constant_cubic)
coil.setCoolingAndChargeModeStorageEnergyInputRatioFunctionofTemperatureCurve(cool_charge_charge_eir_ft)
coil.setCoolingAndChargeModeStorageEnergyInputRatioFunctionofFlowFractionCurve(constant_cubic)
coil.setCoolingAndChargeModeStorageEnergyPartLoadFractionCorrelationCurve(constant_cubic)
coil.setCoolingAndChargeModeSensibleHeatRatioFunctionofTemperatureCurve(cool_shr_ft)
coil.setCoolingAndChargeModeSensibleHeatRatioFunctionofFlowFractionCurve(cool_shr_fff)

# Cooling And Discharge Mode = No
coil.setCoolingAndDischargeModeAvailable(false)

# Charge Only Mode = No
coil.setChargeOnlyModeAvailable(false)

# Discharge Only Mode = Yes
coil.setDischargeOnlyModeAvailable(true)
coil.autocalculateDischargeOnlyModeRatedStorageDischargingCapacity
coil.setDischargeOnlyModeCapacitySizingFactor(1.70)
coil.setDischargeOnlyModeRatedSensibleHeatRatio(0.64)
coil.setDischargeOnlyModeRatedCOP(63.6)
discharge_cap_ft = curve_biquadratic(m, -0.561476105575098, 0.133948946696947, -0.0027652398813276, 0.0, 0.0, 0.0, -100, 100, -100, 100)
discharge_cap_fff = curve_cubic(m, 0.743258739392434, 0.167765026703717, 0.0852727911986869, 0, -100, 100)
constant_bi = curve_biquadratic(m, 1, 0, 0, 0, 0, 0, -100, 100, -100, 100)
discharge_shr_ft = curve_biquadratic(m, -76.3312028672366, 3.69083877577677, 0.00402614182268047, 3.120670734078, -0.00297662635327143, -0.148603418986272, 24.44, 26.67, 29.44, 46.1)
discharge_shr_fff = curve_quadratic(m, 0.60557628, 0.506516665, -0.12647141, 0.2, 1.00)
coil.setDischargeOnlyModeStorageDischargeCapacityFunctionofTemperatureCurve(discharge_cap_ft)
coil.setDischargeOnlyModeStorageDischargeCapacityFunctionofFlowFractionCurve(discharge_cap_fff)
coil.setDischargeOnlyModeEnergyInputRatioFunctionofTemperatureCurve(constant_bi)
coil.setDischargeOnlyModeEnergyInputRatioFunctionofFlowFractionCurve(constant_cubic)
coil.setDischargeOnlyModePartLoadFractionCorrelationCurve(constant_cubic)
coil.setDischargeOnlyModeSensibleHeatRatioFunctionofTemperatureCurve(discharge_shr_ft)
coil.setDischargeOnlyModeSensibleHeatRatioFunctionofFlowFractionCurve(discharge_shr_fff)

# EMSControlled
sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(m, 'Cooling Coil Ice Thermal Storage End Fraction')
sensor.setName("#{coil.name} s")
sensor.setKeyName(coil.name.to_s)

schedule = OpenStudio::Model::ScheduleConstant.new(m)
schedule.setValue(5)

sensor_2 = OpenStudio::Model::EnergyManagementSystemSensor.new(m, 'Schedule Value')
sensor_2.setName("#{schedule.name} s")
sensor_2.setKeyName(schedule.name.to_s)

actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(coil, 'Coil:Cooling:DX:SingleSpeed:ThermalStorage', 'Operating Mode')
actuator.setName("#{coil.name} opmode")

program = OpenStudio::Model::EnergyManagementSystemProgram.new(m)
program.setName("#{coil.name} control")
program.addLine("Set #{actuator.name} = #{sensor_2.name}")
program.addLine("If (#{actuator.name} == 2)")
program.addLine("If (#{sensor.name} > 0.99)")
program.addLine("Set #{actuator.name} = 1")
program.addLine("EndIf")
program.addLine("EndIf")
program.addLine("If (#{actuator.name} == 5)")
program.addLine("If (#{sensor.name} < 0.01)")
program.addLine("Set #{actuator.name} = 1")
program.addLine("EndIf")
program.addLine("EndIf")

pcm = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(m)
pcm.setName("#{coil.name} pcm")
pcm.setCallingPoint('AfterPredictorAfterHVACManagers')
pcm.addProgram(program)

# FanOnOff
fan = OpenStudio::Model::FanOnOff.new(m)
fan.setFanEfficiency(0.75)
fan.setPressureRise(476.748000740096)
fan.setMotorEfficiency(1.0)
fan.setMotorInAirstreamFraction(1.0)

# AirLoopHVACUnitarySystem
air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitarySystem.new(m)
air_loop_unitary.setAvailabilitySchedule(m.alwaysOnDiscreteSchedule)
air_loop_unitary.setCoolingCoil(coil)
air_loop_unitary.setSupplyAirFlowRateDuringHeatingOperation(0.0)
air_loop_unitary.setSupplyFan(fan)
air_loop_unitary.setFanPlacement('BlowThrough')
air_loop_unitary.setSupplyAirFanOperatingModeSchedule(m.alwaysOffDiscreteSchedule)
air_loop_unitary.setSupplyAirFlowRateMethodDuringCoolingOperation('SupplyAirFlowRate')
air_loop_unitary.setSupplyAirFlowRateMethodDuringHeatingOperation('SupplyAirFlowRate')
air_loop_unitary.setMaximumSupplyAirTemperature(48.888889)
air_loop_unitary.setSupplyAirFlowRateWhenNoCoolingorHeatingisRequired(0)

# AirLoopHVAC
air_loop = OpenStudio::Model::AirLoopHVAC.new(m)
air_supply_inlet_node = air_loop.supplyInletNode
air_loop_unitary.addToNode(air_supply_inlet_node)

# Add to zone
# In order to produce more consistent results between different runs,
# we sort the zones by names
# (There's only one here, but just in case this would be copy pasted somewhere
# else...)
zones = m.getThermalZones.sort_by { |z| z.name.to_s }
z = zones[0]
atu = OpenStudio::Model::AirTerminalSingleDuctConstantVolumeNoReheat.new(m, m.alwaysOnDiscreteSchedule)
air_loop_unitary.setControllingZoneorThermostatLocation(z)
air_loop.addBranchForZone(z, atu)

# save the OpenStudio model (.osm)
m.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd,
                        'osm_name' => 'in.osm' })
