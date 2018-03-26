Pull request overview
---------------------

Please change this line to a description of the pull request, with useful supporting information.

This Pull Request is concerning:

- [ ] Case 1: a new test for a new model API class,
- [ ] Case 2: a fix for an existing test
- [ ] Case 3: a new test for an alread-yexisting model API class

Depending on your answer, please fill out the required section below, and delete the two others

- [ ] At least one of the following appropriate labels must be added to this PR to be consumed into the changelog:
   - Defect: This pull request repairs a github defect issue.  The github issue should be referenced in the PR description
   - Refactoring: This pull request includes code changes that don't change the functionality of the program, just perform refactoring
   - NewFeature: This pull request includes code to add a new feature to EnergyPlus
   - Performance: This pull request includes code changes that are directed at improving the runtime performance of EnergyPlus
   - DoNoPublish: This pull request includes changes that shouldn't be included in the changelog


### Case 1: New test for a new model API class

Please include which class(es) you are adding a test to specifically test for.
Include a link to the OpenStudio Pull Request in which you are adding the new classes, or the class itself if already on develop.

eg:

This pull request is in relation with the Pull Request [#3031](https://github.com/NREL/OpenStudio/pull/3031), and  will specifically test for the following classes:
* `AirTerminalSingleDuctConstantVolumeFourPipeBeam`
* `CoilCoolingFourPipeBeam`
* `CoilHeatingFourPipeBeam`
* Additionally it explicitly tests for the existing class [TableMultiVariableLookUp](https://github.com/NREL/OpenStudio/blob/develop/openstudiocore/src/model/TableMultiVariableLookup.hpp)

#### Work Checklist

The following has been checked to ensure compliance with the guidelines:

 - [ ] Tests pass either:
     - [ ] With official OpenStudio release (include version):
         - [ ] A matching OSM test has been added from the successful run of the Ruby one with the official OpenStudio release

     - [ ] with current develop (incude SHA):
         - [ ] A matching OSM test has not yet been added because the official release is pending, but `model_tests.rb` has a TODO.
```ruby
def test_airterminal_cooledbeam_rb
  result = sim_test('airterminal_cooledbeam.rb')
end

# TODO : To be added once the next official release
# including this object is out : 2.5.0
# def test_airterminal_fourpipebeam_osm
#   result = sim_test('airterminal_fourpipebeam.osm')
# end
```


 - [ ] Ruby test is stable: when ran multiple times on the same machine, it produces the same total site kBTU.
     - [ ] I ensured that I assign systems/loads/etc in a repeatable manner (eg: if I assign stuff to thermalZones, I do `model.getThermalZones.sort_by{|z| z.name.to_s}.each do ...` so I am sure I put the same ZoneHVAC systems to the same zones regardless of their order)
     - [ ] I tested stability. Please paste the heatmap png generated after running the following commands:
        ```bash
        # Clean up all custom-tagged OSWs
        python process_results.py test-stability clean
        # Run your test 5 times in a row. Replace `testname_rb` (eg `airterminal_fourpipebeam_rb`)
        python process_results.py test-stability -n testname_rb
        python process_results.py heatmap --tagged
        ```

### Case 2: Fix for an existing test

Please include a link to the specific test you are modifying, and a description of the changes you have made and why they are required.

### Work Checklist

Add to this list or remove from it as applicable.  This is a simple templated set of guidelines.

The change:
 - [ ] affects site kBTU results
 - [ ] does not affect total site kBTU results

If it affects total site kBTU:
 - [ ] Test has been run backwards (see [Instructions for Running Docker](https://github.com/NREL/OpenStudio-resources/blob/develop/doc/Instructions_Docker.md)) for all OpenStudio versions to update numbers
 - [ ] Changes did not make the test fail in older OpenStudio versions where it used to pass
 - [ ] Matching OSM has been replaced with the output of the ruby test for the oldest OpenStudio release where it passes.
 - [ ] All new/changed `out.osw` have been committed
 - [ ] Ruby test is stable: when ran multiple times on the same machine, it produces the same total site kBTU.
    - [ ] I ensured that I assign systems/loads/etc in a repeatable manner (eg: if I assign Terminals to thermalZones, I do `model.getThermalZones.sort_by{|z| z.name.to_s}.each do ...` so I am sure I put the same ZoneHVAC systems to the same zones regardless of their order)
    - [ ] I tested stability. Please paste the heatmap png generated after running the following commands:
        ```bash
        # Clean up all custom-tagged OSWs
        python process_results.py test-stability clean
        # Run your test 5 times in a row. Replace `testname_rb` (eg `airterminal_fourpipebeam_rb`)
        python process_results.py test-stability -n testname_rb
        python process_results.py heatmap --tagged

        ```

### Case 3: New test for an already-existing model API class

Please include which class(es) you are adding a test to specifically test for as it was currently not being tested for.
Include a link to the OpenStudio model classes themselves.

eg:

This pull request adds missing tests for the following classes:
*  [AvailabilibityManagerDifferentialThermostat](https://github.com/NREL/OpenStudio/blob/develop/openstudiocore/src/model/AvailabilityManagerDifferentialThermostat.hpp)
*  [AvailabilibityManagerHighTemperatureTurnOff](https://github.com/NREL/OpenStudio/blob/develop/openstudiocore/src/model/AvailabilityManagerHighTemperatureTurnOff.hpp)
*  [AvailabilibityManagerHighTemperatureTurnOn](https://github.com/NREL/OpenStudio/blob/develop/openstudiocore/src/model/AvailabilityManagerHighTemperatureTurnOn.hpp)
*  [AvailabilibityManagerHighTemperatureTurnOff](https://github.com/NREL/OpenStudio/blob/develop/openstudiocore/src/model/AvailabilityManagerHighTemperatureTurnOff.hpp)
*  [AvailabilibityManagerHighTemperatureTurnOn](https://github.com/NREL/OpenStudio/blob/develop/openstudiocore/src/model/AvailabilityManagerHighTemperatureTurnOn.hpp)

#### Work Checklist

The following has been checked to ensure compliance with the guidelines:


The following has been checked to ensure compliance with the guidelines:

 - [ ] Test has been run backwards (see [Instructions for Running Docker](https://github.com/NREL/OpenStudio-resources/blob/develop/doc/Instructions_Docker.md)) for all OpenStudio versions
 - [ ] A Matching OSM test has been addded with the output of the ruby test for the oldest OpenStudio release where it passes (include OpenStudio Version)

 - [ ] Ruby test is stable in the last OpenStudio version: when ran multiple times on the same machine, it produces the same total site kBTU.
    - [ ] I ensured that I assign systems/loads/etc in a repeatable manner (eg: if I assign stuff to thermalZones, I do `model.getThermalZones.sort_by{|z| z.name.to_s}.each do ...` so I am sure I put the same ZoneHVAC systems to the same zones regardless of their order)
    - [ ] I tested stability. Please paste the heatmap png generated after running the following commands:
        ```bash
        # Clean up all custom-tagged OSWs
        python process_results.py test-stability clean
        # Run your test 5 times in a row. Replace `testname_rb` (eg `airterminal_fourpipebeam_rb`)
        python process_results.py test-stability -n testname_rb
        python process_results.py heatmap --tagged

        ```

### Review Checklist

This will not be exhaustively relevant to every PR.
 - [ ] Code style (indentation, variable names, strip trailing spaces)
 - [ ] Functional code review (it has to work!)
 - [ ] Matching OSM test has been added or `# TODO` added to `model_tests.rb`
 - [ ] Appropriate `out.osw` have been committed
 - [ ] Test is stable
