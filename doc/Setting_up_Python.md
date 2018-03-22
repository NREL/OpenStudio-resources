# Setting up your python environment

The script has been tested on Python 2.7.14 and 3.6.3. The notebook has only been tested in 3.6 so **prefer Python 3** if you don't have an environment yet.

## Using pip

To ensure you have the necessary dependencies you can type this pip install command (whether in 2.7 or 3.6):

    pip install requests matplotlib numpy pandas seaborn jupyter lxml beautifulsoup4 df2gspread

**On Windows, the preferred alternative is to use conda**, but if you insist on using regular python with pip,
you may have to manually install `numpy+mkl`.  
You can do this by downloading the correct `numpy+mkl` wheel file for your platform from [Gohlke's PythonLibs](https://www.lfd.uci.edu/~gohlke/pythonlibs/#numpy) and then running:

```
pip install numpy-1.14.0+mkl-cp37-cp37m-win_amd64.whl
```
    
## Using conda (Preferred for Windows)

Conda is available on all platforms, but **on Windows I strongly advise you use it** in order to avoid missing binaries etc.

On Windows, unless you have already installed python by yourself, the easiest is to use conda as a package manager (conda is both a package manager and an environment manager),
which will take care of the required binaries etc.

You can choose between Anaconda or Miniconda. You can read more in conda's user guide, section [Downloading conda](https://conda.io/docs/user-guide/install/download.html),
Anaconda comes prepackaged with hundreds of scientific python packages and takes about 300MB of disk space, while miniconda is a barebone option.

Whether you choose Anaconda or Miniconda, select the Python 3.6 version, and install that.
I suggest taking a quick look at conda's [Getting Started](https://conda.io/docs/user-guide/getting-started.html).

For setting up the environment, you have two choices:

* using the `environment.yml` file to create a dedicated environment that has only the required dependencies, or,
* just install the needed dependencies in the environment of your choice.

### Using the environment.yml file

There is a file `OpenStudio-resources/environment.yml` that you can use to create an environment ready to be used. Go to the root of this project and type:

    conda env create -f environment.yml
    
This will create an environment named `openstudio-resources` that you will need to activate **every time**:

    conda activate openstudio-resources
    
You should see the prompt change, and you can type `conda env list` and there should be a star `*` next to it.
    
If you use git bash, you can place the following in your `~/.bashrc` file to automatically activate it when you enter the OpenStudio-resources folder:

```bash
# Adapted from conda-auto-env 
# Automatically activates a conda environment when
# entering a folder with an environment.yml file.
#
# If the environment doesn't exist, creates it and
# activates it for you.
#
function conda_auto_env() {
  if [ -e "environment.yml" ]; then
    ENV=$(head -n 1 environment.yml | cut -f2 -d ' ')
    # Check if you are already in the environment
    if [[ $PATH != *$ENV* ]]; then
      # Check if the environment exists
      source activate $ENV
      if [ $? -eq 0 ]; then
        :
      else
        # Create the environment and activate
        echo "Conda env '$ENV' doesn't exist."
        echo -e -n "Do you want to create it with conda? [y/N] "
        read -n 1 -r
        echo    # (optional) move to a new line
        # Default is No
        if [[ $REPLY =~ ^[Yy]$ ]]; then
          conda env create -f environment.yml
          source activate $ENV
        fi
      fi
    fi
  fi
}
export PROMPT_COMMAND=conda_auto_env
```

### Manually setting up your environment

After you are in the environment of your choice,
you can run these install commands (if you have installed Anaconda, you already have most of them but it won't hurt).

    conda install requests matplotlib numpy pandas seaborn jupyter lxml beautifulsoup4
    conda install -c conda-forge df2gspread