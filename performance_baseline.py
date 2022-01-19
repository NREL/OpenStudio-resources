# Python 2.x / 3.x compatibility
from __future__ import division, print_function

#%matplotlib inline

#Import modules
import pandas as pd
import dataframe_image as dfi
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
    process = subprocess.Popen([openstudio_path, p],
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
                    nargs='+',
                    help="List of OpenStudio SDK tar.gz urls",
                    action='store')
parser.add_argument("-f", "--filenames",
                    dest="filenames",
                    nargs='+',
                    help="List of OpenStudio SDK tar.gz filenames",
                    action='store')
parser.add_argument("-n --number-runs",
                    dest="number_runs",
                    type=int, 
                    default=50,
                    help="The number of workflow runs to run on each openstudio binary. Default 50 runs",
                    action='store')


# Parse the args
args = parser.parse_args()

if args.urls:
    paths = args.urls
elif args.filenames:
    paths = args.filenames
else:
   parser.print_help()
   sys.exit()

number_runs = args.number_runs

# Setup base path and 
base_path = os.environ.get('HOME')
base_path += "/perf_test"

if not os.path.exists(base_path):
    os.makedirs(base_path)

openstudio_bins = {}


for path in paths:

    base_filename = os.path.basename(path)

    dest_filename = base_path + "/" + base_filename

    if args.urls:
        # Replace url safe chars with the real thing
        dest_filename = dest_filename.replace("%2B", "+")
        download_sdk(path, dest_filename)

    print("Extracting " + dest_filename)
    extract_sdk(dest_filename)
    base_extract_path = dest_filename.split(".tar.gz")[0]

    # Ubuntu has extract paths in the tar.gz. Check for that and append. 
    if base_extract_path.lower().find("ubuntu") >= 0:

        openstudio_version = os.path.basename(dest_filename).split("+")
        openstudio_bin_path = base_extract_path + "/usr/local/" + openstudio_version[0].lower() + "/bin/openstudio"

    else:
        openstudio_bin_path = base_extract_path + "/bin/openstudio"

    result = subprocess.run([openstudio_bin_path,"--version"], universal_newlines=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=False)

    if result.returncode == 0:
        openstudio_bins[openstudio_bin_path] = result.stdout.strip("\n")
    else:
        print("Error running command %s --version" %  openstudio_bin_path )

df = {}
for key, value in openstudio_bins.items():
    all_results = []
    for i in range(0, number_runs):
        print(i)
        all_results.append(run_ruby_file([i, 'baseline_sys01.rb', key]))
    df[key] = pd.DataFrame(all_results)
    df[key] = df[key].set_index(['file', 'i']).sort_index()


desc = f'<h3>Running baseline_sys01.rb</h3>'
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

means = df_all.mean().unstack(0)
means.to_csv("perf_means.csv")
df_all.to_csv("perf_all.csv")

df_all.style

#dfi.export(means, 'means.png')
print(means)
print(df_all.unstack(0))

#dfi.export(df_all, 'all_runs.png')

q_low = df_all.quantile(0.02)
q_hi  = df_all.quantile(0.98)

df_filtered = df_all[(df_all < q_hi) & (df_all > q_low)]

print(df_filtered)
plt.savefig('perf_comparison.png')
