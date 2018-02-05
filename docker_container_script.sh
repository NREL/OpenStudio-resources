#!/bin/bash
# ARG 1: optional. You can supply a pattern passed to model_tests.rb -n /pattern/

TEST_FILTER=$1

if [ -z "$TEST_FILTER" ]
then
  test_filter=""
else
  test_filter="-n /$TEST_FILTER/"
fi

echo "Launching command: 'ruby model_tests.rb $test_filter'"

~/.rbenv/shims/ruby -I /usr/Ruby/openstudio.so model_tests.rb $test_filter

cd testruns

for f in $(ls **/out.osw)
do
  test=$(dirname $f) # ${f////_}
  outname="${test}_${OSVERSION}_out.osw"
  cp $f ~/test/$outname
done

#mongo_ip=$(head -n 1 mongo_ip)

# Connect to mongo
#mongo $mongo_ip
