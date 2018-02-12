OpenStudio Resources
==========

This repository includes a suite of simulation tests that can be used to validate new OpenStudio model objects as well as ensure that objects continue to work after they are added.  Each new OpenStudio Model object should ideally have two simulation tests associated with it; a Ruby one which verifies the Ruby API and an OSM one that verifies the OSM file can be loaded with future versions of OpenStudio.  Both tests should result in a simulation ready OpenStudio Model that can be simulated using EnergyPlus.  Both of these tests are located in the `\model\simulationtests` directory, the easiest way to add a new test is to find a related existing test and modify it.  When new tests are added they must be added to the `model_tests.rb` file.  

## Running the tests

Using the OpenStudio CLI:
```
openstudio model_tests.rb
```

Using the OpenStudio Ruby bindings:
```
ruby -I \path\to\openstudio.rb\dir\ model_tests.rb
```

To run multiple jobs in parallel you must set the environment variable `N`:

Windows
```
set N=8
```

Unix
```
export N=8
```

To run specific test(s): 

```
-n /test_name*regex/
-n "/(test_name_1|test_name_2)/"
```

## TODO
- Capture simulation results and compare them to past results

