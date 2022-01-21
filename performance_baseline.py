import argparse
import logging
import os
import re
import requests
import subprocess
import shutil
import tarfile

import pandas as pd
import numpy as np

import matplotlib as mpl
import matplotlib.pyplot as plt
import seaborn as sns

from pathlib import Path
from urllib.parse import unquote

from ipywidgets import HTML
from IPython.display import display

from tqdm.auto import tqdm, trange

ROOT_DIR = Path(__file__).parent
PERF_DIR = ROOT_DIR / "perf_test"

mpl.rcParams['figure.figsize'] = (16, 9)
pd.options.display.max_rows = 200

RE_TIME = re.compile(r'(\w+): ([\d\.]+) seconds')


class PerformanceTester():

    def __init__(self, path_or_urls: list[str], is_url: bool,
                 number_runs: int = 50,  verbose: bool = False,
                 force_redownload_extract: bool = False,
                 base_dir_path: Path = PERF_DIR):

        self.path_or_urls = path_or_urls
        self.is_url = is_url
        self.number_runs = number_runs
        self.verbose = verbose
        self.force_redownload_extract = force_redownload_extract
        self.base_dir_path = base_dir_path
        # Setup base path and create if need be
        if not os.path.exists(self.base_dir_path):
            os.makedirs(self.base_dir_path)
            print(f"Output in {self.base_dir_path}")

        loglevel = logging.WARNING
        if self.verbose:
            loglevel = logging.DEBUG

        self.setup_logger(level=loglevel)

    def set_console_log_level(self, level: int):
        self.console_log_level = level
        self._stream_handler.setLevel(level)

    def setup_logger(self, level: int):

        self.console_log_level = level
        self.file_log_level = logging.DEBUG

        # Create a formatter
        formatter = logging.Formatter(
            '%(asctime)s | %(name)s |  %(levelname)s: %(message)s')

        # Get a logger
        self.logger = logging.getLogger("performance_baseline")
        # Set it's level to the lowest possible (for file)
        self.logger.setLevel(logging.DEBUG)

        # Create a console handler
        self._stream_handler = logging.StreamHandler()
        self._stream_handler.setFormatter(formatter)
        self.set_console_log_level(level=level)

        # Create a log handler, in DEBUG mode
        self.logFilePath = self.base_dir_path / "run.log"
        print(f"File logging set to output to {self.logFilePath}")
        self._file_handler = logging.handlers.TimedRotatingFileHandler(
            filename=self.logFilePath, when='midnight', backupCount=30)
        self._file_handler.setFormatter(formatter)
        self._file_handler.setLevel(logging.DEBUG)

        self.logger.addHandler(self._file_handler)
        self.logger.addHandler(self._stream_handler)

    def download_sdk(self, url: str, dest_tar_gz_filepath: Path):
        """
        Downloads the openstudio sdk to a specified path
        """
        headers = {'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) '}
        self.logger.debug(f"Downloading {url}")

        response = requests.get(url, stream=True, headers=headers)
        with tqdm.wrapattr(
            open(dest_tar_gz_filepath, "wb"), "write", miniters=1,
            desc=f"Downloading {dest_tar_gz_filepath.name}",
            total=int(response.headers.get('content-length', 0))
        ) as fout:
            for chunk in response.iter_content(chunk_size=4096):
                fout.write(chunk)

        response.raise_for_status()

    def extract_sdk(self, tar_gz_file: Path):
        """
        Extract the openstudio.tar.gz sdk to same path
        """
        if not tar_gz_file.exists():
            raise OSError("tar.gz file '{tar_gz_file}' does not exists!")
        self.logger.debug(f"Extracting {tar_gz_file} to {self.base_dir_path}")
        tar_file = tarfile.open(tar_gz_file)
        tar_file.extractall(self.base_dir_path)
        tar_file.close()

    def _prepare_installer(self, path_or_url: str):
        """
        Downloads and extracts if url, otherwise just extracts

        Returns the path to the openstudio CLI
        """
        # Replace url safe chars with the real thing
        base_filename = unquote(os.path.basename(path_or_url))
        dest_tar_gz_filepath = self.base_dir_path / base_filename

        base_extract_path = dest_tar_gz_filepath
        while base_extract_path.suffix in {'.tar', '.gz', '.zip'}:
            base_extract_path = base_extract_path.with_suffix('')

        if self.force_redownload_extract:
            if base_extract_path.exists():
                logging.warning(
                    'Force removing extracted directory at: '
                    f'{base_extract_path}')
                shutil.rmtree(base_extract_path)
            if self.is_url:
                if dest_tar_gz_filepath.exists():
                    logging.info(f'Removing tar.gz at: {dest_tar_gz_filepath}')
                    shutil.rmtree(base_extract_path)

        if self.is_url and not dest_tar_gz_filepath.exists():
            self.download_sdk(path_or_url,
                              dest_tar_gz_filepath=dest_tar_gz_filepath)

        if not base_extract_path.exists():
            self.extract_sdk(tar_gz_file=dest_tar_gz_filepath)

        # Ubuntu has extract paths in the tar.gz. Check for that and append.
        if base_filename.lower().find("ubuntu") >= 0:

            openstudio_version = base_filename.split('+')[0]
            openstudio_bin_path = (
                base_extract_path / "usr/local/" /
                openstudio_version.lower() / "bin/openstudio")

        else:
            openstudio_bin_path = base_extract_path / "bin/openstudio"

        return openstudio_bin_path

    def _check_version(self, openstudio_exe: Path):
        if not openstudio_exe.exists:
            raise OSError("{openstudio_exe=} does not exist")
        return subprocess.check_output([openstudio_exe,
                                        '--version']).strip().decode()

    def prepare_installers(self):
        self.openstudio_bins = {}

        for path in self.path_or_urls:
            openstudio_exe = self._prepare_installer(path)
            version = self._check_version(openstudio_exe=openstudio_exe)
            self.openstudio_bins[openstudio_exe] = version

    def _run_ruby_file(self, run_number, ruby_file, openstudio_path):
        """
        Runs the simulation with NEW_EPLUS_EXE and calls parse_sql
        """
        p = ROOT_DIR / 'model' / 'simulationtests' / ruby_file
        if not p.exists():
            raise ValueError(f"Test file at '{p}' does not exist")

        # TODO: modernize, probably handle failure gracefully?
        # subprocess.check_output([openstudio_exe, p]).strip().decode()

        process = subprocess.Popen([openstudio_path, p],
                                   stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE,
                                   universal_newlines=True,
                                   shell=False)

        # wait for the process to terminate
        out, err = process.communicate()
        errcode = process.returncode
        if errcode == 0:
            timings = {'file': ruby_file, 'i': run_number}
            for line in out.splitlines():
                if (m := RE_TIME.match(line)):
                    timing, val = m.groups()
                    timings[timing] = float(val)
            return timings

    def run_ruby_file_n_times(self, ruby_file, openstudio_path):

        all_results = []
        for i in trange(self.number_runs):
            all_results.append(
                perf_tester._run_ruby_file(
                    run_number=i, ruby_file=openstudio_path,
                    openstudio_path=openstudio_path)
            )

        return all_results

    def run_ruby_file_n_times_with_all_installers(self, ruby_file):
        df = {}
        for key, value in perf_tester.openstudio_bins.items():
            all_results = self.run_ruby_file_n_times(
                ruby_file=ruby_file, openstudio_path=key)
            df[key] = pd.DataFrame(all_results)
            df[key] = df[key].set_index(['file', 'i']).sort_index()
        return df


def setup_argparse():
    parser = argparse.ArgumentParser()

    # Force either urls or filenames to be present (but not both)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("-u", "--urls",
                       dest="urls",
                       nargs='+',
                       help="List of OpenStudio SDK tar.gz urls",
                       action='store')

    group.add_argument("-f", "--filenames",
                       dest="filenames",
                       nargs='+',
                       help="List of OpenStudio SDK tar.gz filenames",
                       action='store')

    parser.add_argument('--number-runs', '-n',
                        dest="number_runs",
                        type=int,
                        default=50,
                        help=("The number of workflow runs to run on each "
                              "openstudio binary. Default 50 runs"),
                        action='store')
    parser.add_argument('--verbose', '-v',
                        default=False,
                        help="Enable verbose output",
                        action='store_true')
    # Parse the args
    args = parser.parse_args()

    is_url = False
    if args.urls:
        is_url = True
        paths = args.urls
    else:
        paths = args.filenames

    return paths, is_url, args.number_runs, args.verbose


if __name__ == '__main__':

    path_or_urls, is_url, number_runs, verbose = setup_argparse()

    perf_tester = PerformanceTester(
        path_or_urls=path_or_urls, is_url=is_url, number_runs=number_runs,
        verbose=verbose, force_redownload_extract=False)

    perf_tester.logger.info(
        f'{path_or_urls=}, {is_url=}, {number_runs=}, {verbose=}')

    # Download (if need be), extract, locate openstudio.exe, and check version
    perf_tester.prepare_installers()

    df = {}
    for key, value in perf_tester.openstudio_bins.items():
        all_results = []
        for i in range(0, number_runs):
            print(i)
            all_results.append(
                perf_tester.run_ruby_file(
                    run_number=i, ruby_file='baseline_sys01.rb',
                    openstudio_path=key)
            )
        df[key] = pd.DataFrame(all_results)
        df[key] = df[key].set_index(['file', 'i']).sort_index()

    desc = f'<h3>Running baseline_sys01.rb</h3>'
    label = HTML(desc)
    display(label)

    df_combined = []
    df_keys = []
    for key, value in df.items():
        df_combined.append((value.loc['baseline_sys01.rb'] ))
        df_keys.append(perf_tester.openstudio_bins[key] )

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
