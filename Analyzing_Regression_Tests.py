# Python 2.x / 3.x compatibility
from __future__ import division, print_function

#%matplotlib inline

#Import modules
import pandas as pd
import numpy as np
import os
import json
import matplotlib as mpl
import matplotlib.pyplot as plt
import seaborn as sns
import re
import urllib
import shutil
import tarfile
import argparse
import sys 

#import csv
import glob as gb

#import pathlib

import datetime
import sqlite3

import shutil
import multiprocessing
import subprocess

#import tqdm
from tqdm.notebook import trange, tqdm
import pathlib

from ipywidgets import HTML
from IPython.display import display

import shlex

from itertools import product

# from df2gspread import df2gspread as d2g

mpl.rcParams['figure.figsize'] = (16, 9)
pd.options.display.max_rows = 200


RE_TIME = re.compile(r'(\w+): ([\d\.]+) seconds')

def download_sdk(url, dest_file):
    """
    Downloads the openstudio sdk to a specified path
    """
    header = {'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) '}
    req = urllib.request.Request(url=url, headers=header)

    print("Downloading %s" % url)
    with urllib.request.urlopen(req) as response:
        with open(dest_file, "wb") as f:
            shutil.copyfileobj(response, f)


def extract_sdk(tar_gz_file):
    """
    Extract the openstudio.tar.gz sdk to same path
    """
    tar_file = tarfile.open(dest_filename) 
    tar_file.extractall(base_path)
    tar_file.close()


def run_ruby_file(args):
    """
    Runs the simulation with NEW_EPLUS_EXE and calls parse_sql
    """
    i, ruby_file, openstudio_path = args
    p = os.path.abspath(os.path.join('model', 'simulationtests', ruby_file))
    process = subprocess.Popen(['openstudio', p],
                               stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE,
                               universal_newlines=True,
                               shell=False)

    # wait for the process to terminate
    out, err = process.communicate()
    errcode = process.returncode
    if errcode == 0:
        timings = {'file': ruby_file, 'i': i}
        for line in out.splitlines():
            if (m := RE_TIME.match(line)):
                timing, val = m.groups()
                timings[timing] = float(val)
        return timings


parser = argparse.ArgumentParser()
parser.add_argument("-u", "--urls",
                    dest="urls",
                    help="List of OpenStudio SDK tar.gz urls",
                    action='store')
parser.add_argument("-f", "--filenames",
                    dest="filename",
                    help="List of OpenStudio SDK tar.gz filenames",
                    action='store')
parser.add_argument("--save-plots",
                    dest="save_plots",
                    help="Save the output plots",
                    action='store')


args = parser.parse_args()


if args.urls:
#    print(args.urls)
    urls = args.urls.split(" ")
else:
    print("Please input urls")
    sys.exit()
#print(urls)

base_path = "/Users/tcoleman/openstudio_test"

if not os.path.exists(base_path):
    os.makedirs(base_path)

openstudio_bins = {}


for url in urls:

    print(url)
    base_filename = os.path.basename(url)
   
    dest_filename = base_path + "/" + base_filename
    # Replace url safe chars with the real thing
    dest_filename = dest_filename.replace("%2B", "+")

    download_sdk(url, dest_filename)

    print("Extracting " + dest_filename)
    extract_sdk(dest_filename)
    base_extract_path = dest_filename.split(".tar.gz")[0]
    openstudio_bin_path = base_extract_path + "/bin/openstudio" 

    result = subprocess.run([openstudio_bin_path,"--version"], universal_newlines=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=False)


    if result.returncode == 0:
        print(result.stdout)
        openstudio_bins[openstudio_bin_path] = result.stdout
    else:
        print("Error running %s" %  openstudio_bin_path )

df = {} 
for key, value in openstudio_bins.items():
    all_results = []
    for i in range(0, 2):
        print(i)
        all_results.append(run_ruby_file([i, 'baseline_sys01.rb', key]))
    df[key] = pd.DataFrame(all_results)
    df[key] = df[key].set_index(['file', 'i']).sort_index()


desc = f'<h3>Running baseline_sys01.rb only (50 times)</h3>'
label = HTML(desc)
display(label)

df_combined = []
df_keys = []
for key, value in df.items():
    df_combined.append((value.loc['baseline_sys01.rb'] ))
    df_keys.append(openstudio_bins[key] )

df_all = pd.concat(df_combined, keys=df_keys, axis=1)

grouped = df_all.groupby(level=1, axis=1)

ncols = 1
nrows = int(np.ceil(grouped.ngroups/ncols))

fig, axes = plt.subplots(nrows=nrows, ncols=ncols, figsize=(16,9), sharey=False)

for (key, ax) in zip(grouped.groups.keys(), axes.flatten()):
    grouped.get_group(key).boxplot(ax=ax)

plt.show()