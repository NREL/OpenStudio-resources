#!/bin/bash
# ARG 1: optional. You can supply a pattern passed to model_tests.rb -n /pattern/

TEST_FILTER=$1

if [ -z "$TEST_FILTER" ]
then
  test_filter=""
else
  test_filter="-n /$TEST_FILTER/"
fi

# Making sure versions do match
long_os_version=$(openstudio openstudio_version)
short_os_version=${long_os_version%.*}
# Could also just do
# openstudio -e "puts OpenStudio.openStudioVersion"

if [ "$OSVERSION" != "$short_os_version" ]; then
  echo "/!\\ Warning, the docker version $OSVERSION doesn't match the CLI version $short_os_version"
else
  echo "OK, the docker version $OSVERSION matches the CLI version $short_os_version"
fi

# Launch tests
echo
echo "Launching command: 'ruby model_tests.rb $test_filter'"
~/.rbenv/shims/ruby -I /usr/Ruby/openstudio.so model_tests.rb $test_filter

# Test if directory exists
if [ -d "testruns" ]; then

  cd testruns

  # Copy all out.osw files into the mounted directory with the right naming pattern
  # Note: Now handled in the model_tests.rb sim_test method itself
  #for f in $(ls **/out.osw)
  #do
  #  test=$(dirname $f) # ${f////_}
  #  outname="${test}_${OSVERSION}_out.osw"
  #  cp $f ~/test/$outname
  #done
else
  echo
  echo "/!\\ Warning: testruns/ directory doesn't exist, tests probably didn't run. Check the pattern you supplied or error messages"
fi


#mongo_ip=$(head -n 1 mongo_ip)

# Connect to mongo
#mongo $mongo_ip

# From within a testruns/modelxxx/ directory:
# cp in.osm ~/test/`basename ${PWD%.*}`.osm

