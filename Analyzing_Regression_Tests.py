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





all_results = []
for i in range(0, 50):
    print(i)
    all_results.append(run_ruby_file([i, 'baseline_sys01.rb', 'openstudio-3.3.0']))
df_3_3 = pd.DataFrame(all_results)
df_3_3 = df_3_3.set_index(['file', 'i']).sort_index()

all_results = []
for i in range(0, 50):
    print(i)
    all_results.append(run_ruby_file([i, 'baseline_sys01.rb', 'openstudio-3.2.0']))
df_3_2 = pd.DataFrame(all_results)
df_3_2 = df_3_2.set_index(['file', 'i']).sort_index()

all_results = []
for i in range(0, 50):
    print(i)
    all_results.append(run_ruby_file([i, 'baseline_sys01.rb', 'openstudio-3.1.0']))
df_3_1 = pd.DataFrame(all_results)
df_3_1 = df_3_1.set_index(['file', 'i']).sort_index()


desc = f'<h3>Running baseline_sys01.rb only (50 times)</h3>'
label = HTML(desc)
display(label)


#df_single.loc['baseline_sys01.rb', ['model_articulation', 'model_save', 'ForwardTranslator']].astype(float).plot()

df_all = pd.concat([df_3_1.loc['baseline_sys01.rb'], df_3_2.loc['baseline_sys01.rb'], df_3_3.loc['baseline_sys01.rb']],
                   keys=['Single Thread -OS 3.1', 'Single Thread -OS 3.2', 'Single Thread -OS 3.3'], axis=1)


grouped = df_all.groupby(level=1, axis=1)

ncols = 1
nrows = int(np.ceil(grouped.ngroups/ncols))

fig, axes = plt.subplots(nrows=nrows, ncols=ncols, figsize=(16,9), sharey=False)

for (key, ax) in zip(grouped.groups.keys(), axes.flatten()):
    grouped.get_group(key).boxplot(ax=ax)

plt.show()