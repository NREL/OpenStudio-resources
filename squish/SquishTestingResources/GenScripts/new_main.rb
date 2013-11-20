# To change this template, choose Tools | Templates
# and open the template in the editor.

#!/usr/bin/ruby -w
puts "Run Test Suite Generation Scripts"

# require rubyscript for all suites I want to generate
puts "> generating Squish Test Suite - suite_OSSP_IDF_xmpl"
require 'Suite_Generation_Script-OSSP_XP_IDF_xmpl.rb'

# corner and bad are note workign yet so don't generate the tests
# puts "> generating Squish Test Suite - suite_OSSP_IDF_corner"
# require 'Suite_Generation_Script-OSSP_XP_IDF_corner.rb'
# puts "> generating Squish Test Suite - suite_OSSP_IDF_bad"
# require 'Suite_Generation_Script-OSSP_XP_IDF_bad.rb'

puts "Finished generating test suites"

# Later on adjust scripts to remove warning about initizlized constants

