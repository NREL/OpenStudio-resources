require 'date'

start = DateTime::now()

while ( Date::day_fraction_to_time((DateTime::now() - start))[2] < 1 )

end
