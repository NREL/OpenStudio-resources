Pull request overview
---------------------

Please change this line to a description of the pull request, with useful supporting information.

This Pull Request is concerning:

 - [ ] **Case 1 - `NewTest`:** a new test for a new model API class,
 - [x] **Case 2 - `TestFix`:** a fix for an existing test. The GitHub issue should be referenced in the PR description
 - [ ] **Case 3 - `NewTestForExisting`:** a new test for an already-existing model API class

Depending on your answer, please fill out the required section below, and delete the two others. Leave the review checklist in place.

----------------------------------------------------------------------------------------------------------

### Case 2: Fix for an existing test

Please include a link to the specific test you are modifying, and a description of the changes you have made and why they are required.

### Work Checklist

**The change:**
 - [ ] affects site kBTU results
 - [ ] does not affect total site kBTU results

**If it affects total site kBTU:**
 - [ ] Test has been run backwards (see [Instructions for Running Docker](https://github.com/NREL/OpenStudio-resources/blob/develop/doc/Instructions_Docker.md)) for all OpenStudio versions to update numbers
 - [ ] Changes did not make the test fail in older OpenStudio versions where it used to pass
 - [ ] Matching OSM has been replaced with the output of the ruby test for the oldest OpenStudio release where it passes.
 - [ ] All new/changed `out.osw` have been committed for official OpenStudio versions only

**Either way:**

 - [ ] **Ruby test is still stable**: when run multiple times on the same machine, it produces the same total site kBTU.
     - [ ] I ensured that I assign systems/loads/etc in a repeatable manner (eg: if I assign Terminals to thermalZones, I do `model.getThermalZones.sort_by{|z| z.name.to_s}.each do ...` so I am sure I put the same ZoneHVAC systems to the same zones regardless of their order)
     - [ ] I tested stability using `process_results.py` (see `python process_results.py --help` for usage).
    Please paste the text output or heatmap png generated after running the following commands:
        ```bash
        # Clean up all custom-tagged OSWs
        python process_results.py test-stability clean
        # Run your test 5 times in a row. Replace `testname_rb` (eg `airterminal_fourpipebeam_rb`)
        python process_results.py test-stability run -n testname
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
   - [ ] One of: `NewTest`, `TestFix`, `NewTestForExisting`
   - [ ] If `NewTest`: add `PendingOSM` if needed

