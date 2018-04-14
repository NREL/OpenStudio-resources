Pull request overview
---------------------

**Please change this line to a description of the pull request, with useful supporting information.**

Link to relevant GitHub Issue(s) if appropriate:

This Pull Request is concerning:

 - [ ] **Case 1 - `NewTest`:** a new test for a new model API class,
 - [ ] **Case 2 - `TestFix`:** a fix for an existing test. The GitHub issue should be referenced in the PR description
 - [x] **Case 3 - `NewTestForExisting`:** a new test for an already-existing model API class
 - [ ] **Case 4 - `Other`:** Something else, like maintenance of the repo, or just committing test results with a new OpenStudio version.

----------------------------------------------------------------------------------------------------------

### Case 3: New test for an already-existing model API class

Please include which class(es) you are adding a test to specifically test for as it was currently not being tested for.
Include a link to the OpenStudio model classes themselves.

> eg:
>
> This pull request adds missing tests for the following classes:
> *  [AvailabilibityManagerDifferentialThermostat](https://github.com/NREL/OpenStudio/blob/develop/openstudiocore/src/model/AvailabilityManagerDifferentialThermostat.hpp)
> *  [AvailabilibityManagerHighTemperatureTurnOff](https://github.com/NREL/OpenStudio/blob/develop/openstudiocore/src/model/AvailabilityManagerHighTemperatureTurnOff.hpp)
> *  [AvailabilibityManagerHighTemperatureTurnOn](https://github.com/NREL/OpenStudio/blob/develop/openstudiocore/src/model/AvailabilityManagerHighTemperatureTurnOn.hpp)

#### Work Checklist

The following has been checked to ensure compliance with the guidelines:

 - [ ] **Test has been run backwards** (see [Instructions for Running Docker](https://github.com/NREL/OpenStudio-resources/blob/develop/doc/Instructions_Docker.md)) for all OpenStudio versions
 - [ ] **A Matching OSM test** has been added with the output of the ruby test for the oldest OpenStudio release where it passes (include OpenStudio Version)

 - [ ] **Ruby test is stable** in the last OpenStudio version: when run multiple times on the same machine, it produces the same total site kBTU.
    - [ ] I ensured that I assign systems/loads/etc in a repeatable manner (eg: if I assign stuff to thermalZones, I do `model.getThermalZones.sort_by{|z| z.name.to_s}.each do ...` so I am sure I put the same ZoneHVAC systems to the same zones regardless of their order)
     - [ ] I tested stability using `process_results.py` (see `python process_results.py --help` for usage).
    Please paste the text output or heatmap png generated after running the following commands:
        ```bash
        # Clean up all custom-tagged OSWs
        python process_results.py test-stability clean
        # Run your test 5 times in a row. Replace `testname_rb` (eg `airterminal_fourpipebeam_rb`)
        python process_results.py test-stability run -n testname_rb
        # Check that they all passed
        python process_results.py test-status --tagged
        # Check site kBTU differences
        python process_results.py heatmap --tagged

        ```

----------------------------------------------------------------------------------------------------------

### Review Checklist

 - [ ] Code style (indentation, variable names, strip trailing spaces)
 - [ ] Functional code review (it has to work!)
 - [ ] Matching OSM test has been added or `# TODO` added to `model_tests.rb`
 - [ ] Appropriate `out.osw` have been committed
 - [ ] Test is stable
 - [ ] The appropriate labels have been added to this PR:
   - [ ] One of: `NewTest`, `TestFix`, `NewTestForExisting`, `Other`
   - [ ] If `NewTest`: add `PendingOSM` if needed

