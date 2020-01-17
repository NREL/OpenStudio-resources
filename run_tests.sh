# For develop, we can probably just pull the latest official docker
# docker pull nrel/openstudio:latest

# For a PR, we could rather use an ubuntu image, download the .deb file from CI related to a specific companion PR and install that
# And we could run model_tests.rb with a filter specific to the test being added (use git diff to identify new/mod tests files in model/simulationtests)
# first, and it that works, only then run the full model_tests.rb

# Clean up reports dir before we start
# I configured JUnitReport to not empty dir on start because we use multiple test_files
# or it will basically wipe highlevel_tests results when launching the next one
/bin/rm -Rf test_reports

openstudio highlevel_tests.rb
openstudio model_tests.rb # -n /filter/
openstudio utilities_tests.rb
openstudio sql_tests.rb
# Takes a while and not so critical probably, so disabling for now
# openstudio SDD_tests.rb

# Glob all test_reports/*.xml and consume that in Jenkins
