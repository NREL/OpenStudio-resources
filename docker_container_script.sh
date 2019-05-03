#!/bin/bash
# ARG 1: optional. You can supply file ruby test file to run, default to model_tests.rb
# ARG 2: optional. You can supply a pattern passed to model_tests.rb -n /pattern/

test_file=$1
TEST_FILTER=$2

if [ -z "$test_file" ]
then
  test_file="model_tests.rb"
fi

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
echo "Launching command: 'ruby $test_file $test_filter'"

if [ "$OSVERSION" = 2.0.4 ]; then
  # This version is weird, I directly require /usr/Ruby/openstudio.so in the model_tests.rb, done in docker exec via sed
  ~/.rbenv/shims/ruby $test_file $test_filter
else
  # Before 2.4.3, ruby used to be installed via rbenv
  # From 2.4.3 onward, it installs ruby via the openstudio-server development script, so there is no longer rbenv and you can use system ruby directly
  # Note JM 2018-08-30: in recent versions at least, we could just use the cli, `openstudio model_test.rb`
  # We test if there is rbenv
  if [ -f ~/.rbenv/shims/ruby ]; then
    # If there is, we do use that
    ~/.rbenv/shims/ruby -I /usr/Ruby/openstudio.so $test_file $test_filter
  else
    # Otherwise, we use system ruby, no need for the include, RUBYLIB env variable is set
    ruby $test_file $test_filter
  fi
fi
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

  #for f in $(ls **/in.osm)
  #do
    #test=$(dirname $f) # ${f////_}
    #outname="${test}_${OSVERSION}.osm"
    #cp $f ~/test/$outname
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



