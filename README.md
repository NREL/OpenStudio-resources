OpenStudio Resources
==========

This repository includes a suite of simulation tests that can be used to validate new OpenStudio model objects as well as ensure that objects continue to work after they are added. 
Each new OpenStudio Model object should ideally have two simulation tests associated with it:

* a Ruby one which verifies the Ruby API and,
* an OSM one that verifies the OSM file can be loaded with future versions of OpenStudio.  

Both tests should result in a simulation-ready OpenStudio Model that can be simulated using EnergyPlus. 
Both of these tests are located in the `\model\simulationtests` directory, the easiest way to add a new test is to find a related existing test and modify it. 
When new tests are added they must be added to the `model_tests.rb` file.

## Running the tests

Using the OpenStudio CLI:
```
openstudio model_tests.rb
```

Using the OpenStudio Ruby bindings:

```
ruby -I \path\to\openstudio.rb\dir\ model_tests.rb
```

*Optional:* if you use your system ruby, you can do `gem install minitest-reporters` and enjoy a cleaner output.

Multiple jobs will be run in parallel, the number of which is determined by:

* The environment variable `N` if it is set
* Your number of logical threads minus 1 if `N` is not set (for eg a recent quad core machine will run 7 jobs in parallel)

To the environment variable `N`:

Windows
```
set N=8
```

Unix
```
export N=8
```

To run specific test(s), you can either:

* Filter by a regex pattern

```
openstudio model_tests.rb -n /test_name*regex/
openstudio model_tests.rb -n "/(test_name_1|test_name_2)/"
# Example: run all ruby tests (not the osms)
openstudio model_tests.rb -n /test_.*_rb/
# Run the OSM and the RB test for a single test
openstudio model_tests.rb -n /test_name/
```

* Filter on the actual name of the test

```
openstudio model_tests.rb -n test_plenums_rb
```

## Analyzing history of simulation tests

### Creating the out.osw

The `model_tests.rb` is responsible to run the tests you have requested (or all if you didn't filter), and will post-process all `out.osw` files to clean them up a bit:

* Remove eplusout_err for files that are bigger than 100KB (workaround for the fuel cell test that throws error in regula falsi 8 million times => 800 MB)
* Remove timestamps throughout the file to avoid useless git diff
* Round values to 2 digits to avoid excessive diffing

The `model_tests.rb`  outputs this modified `out.osw` in the right folder with the right naming convention `test_osversion_out.osw` (eg: air_chillers.rb_2.3.1_out.osm):
a given user can run the regression suite against his OpenStudio version exactly like he used to. Currently every test output is commited to the `test/` folder.

### Parsing and analyzing

The `regression_analysis.py` script is provided with functions to update the [google sheet](https://docs.google.com/spreadsheets/d/1gL8KSwRPtMPYj-QrTwlCwHJvNRP7llQyEinfM1-1Usg/edit#gid=1548402386) centralizing the test results, and visualize deviations.
This script is parsing all the out.osw (for all versions) in the `test` folder and creating table representation for export to google spreadsheet, or for visualization as heatmaps.

**Setting up a suitable python environment**

The script has been tested on Python 2.7.14 and 3.6.3. (The notebook has only been tested in 3.6 so prefer 3.6 if you don't have an environment yet). 

To ensure you have the necessary dependencies you can type this pip install command (whether in 2.7 or 3.6):

```
pip install requests matplotlib numpy pandas seaborn jupyter df2gspread lxml bs4
```

**Running the script**:

This script can be run as a command line utility:
```
python regression_analysis.py
```

You will be asked two questions:
* Whether you want to upload the results to the google sheet.To use this function, you will need two things: 
    * Write access to the google spreadsheet
    * Install and configure the python module df2gspread. This requires setting credentials in the google console API, see [here](https://df2gspread.readthedocs.io/en/latest/overview.html#access-credentials) for how to do it.
* Whether you want to plot a heatmap of the major deviations, and if so, what is your row (test threshold). In order to limit the size of the heatmap, the threshold is used to filter out tests where none of the individual versions have shown a deviation that is bigger. Suggested values are 0.01 (for 1%) and 0.005 (0.5%). Here is an example with a threshold of 0.01

![Percentage difference in total site kBTU](doc/images/site_kbtu_pct_change.png)

**Exploring data**

For exploring data in depth, the python file can also be imported and you can just use its high-level functiins. A jupyter notebook `Analyzing_Regression_Tests.ipynb` is provided for convenience and has some examples about how to slice and dice the data.

To launch a notebook, you need to type `jupyter notebook [optional-start-path]`. If you don't provide a start path, it starts in your current directory.
This opens a tab in your browser window, and you can navigate to the notebook of your choice. Each cell gets executed individually by pressing SHIFT+ENTER.
Please refer to the [Jupyter/IPython Quick Start Guide](https://jupyter-notebook-beginner-guide.readthedocs.io/en/latest/) if you aren't familiar with this feature


## Running tests in past history

**Note:** The past history has been built already: **all previous version files are stored in the `test` folder already**.
So you shouldn't need to run tests in previous versions unless you are adding a missing test for an object that has been in OpenStudio for quite some time.

Running past versions is achieved using docker, and the relies on the images stored on DockerHub at [nrel/openstudio](https://hub.docker.com/r/nrel/openstudio/).

**Note:** If you only want to run for a single specific past version, you can definitely use your old installed OpenStudio version, you don't need docker.
Docker is useful to run multiple past version (12 as of writing this for example).

Two high-level command line utilities are provided, one for running a single version, the other to run all.
They ask a couple of questions that all have sensible defaults to begin with, and should abstract all docker complexities.

Launch a specific version
```
./launch_docker.sh 2.4.0
```

Launch all versions (you can modify the harcoded arguments atop the script `launch_all.sh`)
```
./launch_all.sh
```

**Please refer to the [Instructions for Running Docker](doc/Instructions_Docker.md) for more info, especially if you use Windows.**
