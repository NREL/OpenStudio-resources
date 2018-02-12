#!/usr/bin/env python3

"""Support functions to cleanup and analyze the collections of out.osw
produced when running the regression tests.
If run from the command line rather than imported, will do the parsing and
upload results to the google spreasheet

    use help(function) to load the docstring for this function.

"""

# Python 2.x / 3.x compatibility
from __future__ import division, print_function

import sys
import os
import requests
import json
import pandas as pd
import numpy as np
import re
import glob as gb
from df2gspread import df2gspread as d2g

__author__ = "Julien Marrec"
__license__ = "Standard OpenStudio License"
__maintainer__ = "Julien Marrec"
__email__ = "julien@effibem.com"
__status__ = "Production"

# Folder in which the out.osw are stored
TEST_DIR = './test/'
SHEET_URL = ('https://docs.google.com/spreadsheets/d/1gL8KSwRPtMPYj-'
             'QrTwlCwHJvNRP7llQyEinfM1-1Usg/edit?usp=sharing')

# Used to pretty the fuel by end use dataframe
PRETTY_NAMES = {'cooling': 'Cooling',
                'exterior_equipment': 'Exterior Equipment',
                'exterior_lighting': 'Exterior Lighting',
                'fans': 'Fans',
                'generators': 'Generators',
                'heat_recovery': 'Heat Recovery',
                'heat_rejection': 'Heat Rejection',
                'heating': 'Heating',
                'humidification': 'Humidification',
                'interior_equipment': 'Interior Equipment',
                'interior_lighting': 'Interior Lighting',
                'pumps': 'Pumps',
                'refrigeration': 'Refrigeration',
                'water_systems': 'Water Systems',

                'electricity': 'Electricity',
                'natural_gas': 'Natural Gas'
                }


def cleanup_bloated_osws():
    """
    The fuel cell tests produce out.osw files that are about 800 MB
    because E+ throws a warning in the Regula Falsi routine (an E+ bug)
    which results in about 7.5 Million times the same warning

    So if the result.osw is bigger than 100 KB, we remove the eplusout_err
    key and save in place.

    Note: this is now handled in model_tests.rb directly so you shouldn't
    really need to use this function
    """
    for out_osw_path in gb.glob(os.path.join(TEST_DIR, '*.osw')):
        # If bigger than 100 KB
        if os.path.getsize(out_osw_path) > 100000:
            with open(out_osw_path, 'r') as jsonfile:
                json_text = jsonfile.read()
            data = json.loads(json_text)

            # Pop the eplusout_err messages
            data.pop('eplusout_err')
            print("Poping eplusout_err for {}".format(out_osw_path))

            try:
                with open(out_osw_path, 'w') as jsonoutfile:
                    jsonoutfile.write(json.dumps(data))
            except:
                print('cannot write to {}'.format(out_osw_path))


def get_all_openstudio_docker_versions(latest=None):
    """
    Use the v2 Registry API to query all available docker hub tags
    https://hub.docker.com/r/nrel/openstudio/tags/

    Args:
    -----
    * latest (str, or default None): version string equivalent to 'latest'
        docker hub tag.
        If not None (eg: "2.4.0"), will replace the 'latest' tag with this str.
        Pass None to just ignore the 'latest' tag.

        The dockerhub repo has been inconsistent sometimes, but normally
        it should specifically tag the versions, eg if the last build is
        2.4.1 it should be tagged 2.4.1 AND latest

    Returns:
    --------
    * all_tags (list of str): list of all available versions (tags)

    Needs:
    -------
    requests, json
    """

    i = 1
    status_code = 200
    base_url = 'https://registry.hub.docker.com/v2/'
    page_url = 'repositories/nrel/openstudio/tags?page={i}'

    all_tags = []
    while (status_code == 200):
        response = requests.get(os.path.join(base_url,
                                             page_url.format(i=i)))
        status_code = response.status_code
        i += 1
        if status_code == 200:
            data = json.loads(response.text)
            all_tags += [x["name"] for x in data["results"]]

    if latest is None:
        all_tags = [x for x in all_tags if x != 'latest']
    else:
        all_tags = [latest if x == 'latest' else x for x in all_tags]

    return all_tags


def parse_compatibility_matrix(force_latest=False):
    """
    Parses the compatability matrix into a pandas dataframe. Matrix is here:
    https://github.com/NREL/OpenStudio/wiki/OpenStudio-Version-Compatibility-Matrix

    Also queries the docker hub API see (`get_all_openstudio_docker_versions`)
    to check if there is an available docker tag too.

    Args:
    ------
    * force_latest (bool): whether to replace the docker tag 'latest' with
    the latest available version. See get_all_openstudio_docker_versions
    for more info. In general False should be used

    Returns:
    ---------
    * compat_matrix (pd.DataFrame): a pandas dataframe of all versions.
        You can turn it into a valid json with:
        json.loads(compat_matrix.to_json(orient='records'))
    """

    compat_matrix_url = ('https://github.com/NREL/OpenStudio/wiki/'
                         'OpenStudio-Version-Compatibility-Matrix')
    compat_matrix = pd.read_html(compat_matrix_url, index_col=0)[0]
    compat_matrix.index = [x.replace('v', '').replace('*', '')
                           for x in compat_matrix.index]
    compat_matrix.drop('Gemfile', axis=1, inplace=True)
    compat_matrix.index.name = 'OpenStudio'
    compat_matrix.reset_index(inplace=True)
    compat_matrix['Released'] = pd.to_datetime(compat_matrix['Released'])

    if force_latest:
        latest = compat_matrix.set_index('OpenStudio')['Released'].idxmax()
    else:
        latest = None

    all_tags = get_all_openstudio_docker_versions(latest=latest)

    compat_matrix['Has_Docker'] = False
    compat_matrix.loc[compat_matrix['OpenStudio'].isin(all_tags),
                      'Has_Docker'] = True

    return compat_matrix


def find_osm_test_versions():
    """
    Globs the model/simulationtests/*.osm and parse the Version String
    Constructs a dataframe

    Args:
    ------
    None

    Returns:
    ---------
    model_test_cases (pd.DataFrame): index is testcase (eg 'air_chillers')
    columns are ['path', 'OSM Version', 'Major', 'Minor', 'Patch']
    """

    # Reconstruct by parsing file itself
    v_regex = re.compile('\s+(\d+\.\d+\.\d+);\s+!-? Version Identifier')

    model_version_lists = []
    osms = gb.glob('model/simulationtests/*.osm')
    for osm in osms:
        found = False
        test = os.path.splitext(os.path.split(osm)[1])[0]
        with open(osm, 'r') as f:
            lines = f.read().splitlines()
        for i, line in enumerate(lines):
            if 'OS:Version' in line:
                m = v_regex.search(lines[i+2])
                if m:
                    found = True
                    model_version_lists.append([test, osm, m.groups()[0]])
                else:
                    print("Error for line: {}".format(lines[i+2]))
        if not found:
            print("Problem for {}".format(osm))

    model_test_cases = pd.DataFrame(model_version_lists,
                                    columns=['testcase', 'path',
                                             'OSM version'])
    model_test_cases.set_index('testcase', inplace=True)
    model_test_cases.sort_index(inplace=True)
    model_test_cases[['Major', 'Minor',
                      'Patch']] = (model_test_cases['OSM version'].str
                                   .split('.', expand=True))
    return model_test_cases


def find_info_osws(compat_matrix=None, test_dir=None):
    """
    Looks for files in the test/ folder, and parses version and type (rb, osm)
    Constructs a dataframe that has E+/OS versions in column (by looking E+
    version in compat_matrix)

    Args:
    ------
    * compat_matrix (pd.DataFrame or None)
        if None, calls parse_compatibility_matrix. Otherwise you can supply it
    * test_dir (str path or None): if None uses the global TEST_DIR constant
    Returns:
    ---------
    * df_files (pd.DataFrame): A multi indexed dataframe in rows and columns
        Levels are as follows:
        index: ['Test', 'Type'], eg ('absorption_chiller', 'rb')
        columns: ['E+', 'OS'], the versions eg ('8.6.0', '2.4.0')

        values are the path of the corresponding out.osw,
        eg: 'absorption_chillers.rb_2.0.4_out.osw'

    """

    if test_dir is None:
        test_dir = TEST_DIR

    if compat_matrix is None:
        compat_matrix = parse_compatibility_matrix()

    files = gb.glob(os.path.join(test_dir, '*out.osw'))

    df_files = pd.DataFrame(files, columns=['path'])
    filepattern = (r'(?P<Test>.*?)\.(?P<Type>osm|rb)_'
                   '(?P<version>\d+\.\d+\.\d+)_out\.osw')
    version = (df_files['path'].apply(lambda p: os.path.relpath(p,  test_dir))
                               .str.extract(pat=filepattern, expand=True))
    df_files = pd.concat([df_files,
                          version],
                         axis=1)
    df_files = (df_files.set_index(['Test', 'Type',
                                    'version'])['path'].unstack(['version'])
                        .sort_index(axis=1))

    version_dict = compat_matrix.set_index('OpenStudio')['E+'].to_dict()

    df_files.columns = pd.MultiIndex.from_tuples([(version_dict[x], x)
                                                  for x in df_files.columns],
                                                 names=['E+', 'OS'])
    return df_files

###############################################################################
#                P A R S I N G    F U N C T I O N S
###############################################################################

# These functions are designed to be used via `df_files.applymap`


def load_osw(out_osw_path):
    """
    Loads the JSON into a dict

    Args:
    -----
    * out_osw_path (str, path): path to the out.osw

    Returns:
    --------
    * data (dict): the parsed data
    """
    if out_osw_path is None:
        return None
    with open(out_osw_path,'r') as jsonfile:
        json_text = jsonfile.read()
    data = json.loads(json_text)
    return data


def _parse_success(data, extra_check=False, verbose=False):
    """
    2.0.4 has a bug, it reports "Fail" when really it worked
    so if extra_check is True (for 2.0.4 only),
    if status='Fail', we check whether we can find 'EnergyPlus Completed
    Sucessfully' in the eplusout_err, in which case we return success

    Args:
    ------
    * data (dict): the dictionary corresponding to the out.osw JSON file
    * extra_check (bool): whether to ignore the completed_status when Fail
        and check the eplusout_err, pass True only for 2.0.4

    Returns:
    --------
    * status (str): 'Fail' or 'Success'
    """
    status = data['completed_status']

    # OS 2.0.4 has a bug, it reports "Fail" when really it worked
    if status == "Fail":
        if "eplusout_err" in data.keys():
            if "EnergyPlus Completed Successfully" in data['eplusout_err']:
                if verbose:
                    print("OSW status is 'Fail' but E+ completed successfully")
                status = "Success"
    return status

def parse_success(out_osw_path):
    """
    Loads out.osw (load_osw) and checks the success
    Calls `load_osw` and `_parse_success`

    Args:
    -----
    * out_osw_path (str, path): path to the out.osw

    Returns:
    --------
    * status (str): 'Fail' or 'Success', or '' (empty) if there isn't even an
    OSW, which could happen in particular for OSMs that have a version older
    than the OpenStudio version used to run the tests

    """
    data = load_osw(out_osw_path)
    if data is None:
        return ''

    extra_check = False
    if '2.0.4' in out_osw_path:
        extra_check = True

    status = _parse_success(data, extra_check=extra_check, verbose=False)
    # print("{} - {}".format(out_osw_path, status))
    return status

def _get_os_results(data, out_osw_path):
    """
    Helper function that finds the openstudio_result data in the dict

    Args:
    -----
    * data (dict): the dictionary corresponding to the out.osw JSON file
    * out_osw_path (str, path): path to the out.osw

    """
    if '2.0.4' in out_osw_path:
        os_results = [x for x in data['steps']
                      if x['measure_dir_name']=='openstudio_results']
    else:
        # This works from 2.0.5 onward...
        os_results = [x for x in data['steps']
                      if x['result']['measure_name']=='openstudio_results']

    if len(os_results) == 0:
        print("There are no OpenStudio results for {}".format(out_osw_path))
        return None
    if len(os_results) != 1:
        print("Warning: there are more than one openstudio_results measure "
              "for {}".format(out_osw_path))
    os_result = os_results[0]['result']
    return os_result

def parse_total_site_energy(out_osw_path):
    """
    Finds the 'total_site_energy' (kBTU) in an out_osw_path

    Args:
    -----
    * out_osw_path (str, path): path to the out.osw

    Returns:
    * site_kbtu (float): the 'total_site_energy' from the openstudio_results
        measure. Returns np.nan is status is not Success or path is empty
    """

    data = load_osw(out_osw_path)
    if data is None:
        return np.nan
    status = _parse_success(data)
    if status != 'Success':
        return np.nan

    os_result = _get_os_results(data, out_osw_path)
    if os_result is None:
        return np.nan

    site_kbtu = [x for x in os_result['step_values']
                 if x['name'] == 'total_site_energy'][0]['value']
    return site_kbtu

def parse_end_use(out_osw_path, throw_if_path_none=True):
    """
    Finds the fuel by end use in an out_osw_path

    Args:
    -----
    * out_osw_path (str, path): path to the out.osw

    Returns:
    * cleaned_end_use (pd.DataFrame): Fuel by End Use data
        index = 'End Use
        columns = ['Fuel', 'units']
    """

    data = load_osw(out_osw_path)
    if data is None:
        if throw_if_path_none:
            raise("No path")
        else:
            return np.nan
    status = _parse_success(data)
    if status != 'Success':
        raise("Simulation failed for #{out_osw_path}")

    os_result = _get_os_results(data, out_osw_path)
    if os_result is None:
        return np.nan

    df = pd.DataFrame.from_records([x for x in os_result['step_values']
                                    if 'units' in x.keys()])

    end_use = df[df.name.str.contains('end_use')].copy()

    end_use[['Fuel', 'End Use']] = (end_use['name'].replace(PRETTY_NAMES,
                                                            regex=True)
                                    .str.replace('end_use_', '')
                                    .str.split('_', expand=True))

    filt1 = end_use['End Use'].isnull()
    end_use.loc[filt1, "End Use"] = end_use.loc[filt1, "Fuel"]
    end_use.loc[filt1, "Fuel"] = 'Total'

    cleaned_end_use = (end_use.set_index(['Fuel', 'End Use',
                                          'units'])['value'].unstack([1]).T
                              .replace(0, np.nan))

    return cleaned_end_use


def success_sheet(df_files, model_test_cases=None, add_missing=True):
    """
    High-level method to construct a dataframe of Success

    Args:
    -----
    * df_files (pd.DataFrame): from `find_info_osws()`
    * model_test_cases (pd.DataFrame): if not calls, `find_osm_test_versions()`

    """
    success = df_files.applymap(parse_success)
    if model_test_cases is None:
        model_test_cases = find_osm_test_versions()

    # Put N/A where OSM is newer than than the OS version
    for index, row in success.iterrows():
        if index[1] == 'osm':
            test = index[0]
            version_osm = tuple(model_test_cases.loc[test,
                                                     'OSM version'].split('.'))
            filt1 = [(tuple(x[1].split('.')) < version_osm) for x in row.index]
            filt2 = row == ''
            row[filt1 & filt2] = "N/A"

    # Create n_fail and order by that
    n_fail = (success == 'Fail').sum(axis=1)
    n_missing = (success == '').sum(axis=1)
    n_fail_miss = n_fail + n_missing

    success['n_fail'] = n_fail

    if add_missing:
        success['n_missing'] = n_missing
        success['n_fail+missing'] = n_fail_miss
        # Order by n_fail, then by n_fail+missing
        order_n_fail = (success.groupby(level='Test').sum()
                               .sort_values(by=['n_fail', 'n_fail+missing'],
                                            ascending=False))
    else:
        order_n_fail = (success.groupby(level='Test')['n_fail']
                               .sum().sort_values(ascending=False))


    success = success.reindex(index=order_n_fail.index, level=0)

    return success


def test_implemented_sheet(df_files, success=None, model_test_cases=None,
                           only_for_mising_osm=False):
    """
    High-level method to construct a dataframe of test implemented or not
    as well as OSM version (+ Major, Minor, Patc)

    Args:
    -----
    * df_files (pd.DataFrame): from `find_info_osws()`
    * success (pd.DataFrame): if None, calls `success_sheet`
    * model_test_cases (pd.DataFrame): if None, calls `find_osm_test_versions`
    * only_for_mising_osm (bool): include "First Ruby Version Worked"
    for only the tests with missing OSMs or all
    """

    if model_test_cases is None:
        model_test_cases = find_osm_test_versions()
    if success is None:
        success = success_sheet()

    test_impl = pd.DataFrame(df_files.index.tolist(), columns=['Test', 'Type'])
    test_impl['Has_Test'] = True
    test_impl = test_impl.pivot(index='Test', columns='Type',
                                values='Has_Test').fillna(False)

    test_impl = test_impl.join(model_test_cases[['OSM version', 'Major',
                                                 'Minor', 'Patch']]).fillna('')

    if only_for_mising_osm:
        missing_osms = test_impl[~test_impl['osm'] &
                                 test_impl['rb']].index.tolist()
        temp = (success.swaplevel(1, 0, axis=0).loc['rb']
                       .loc[missing_osms,
                            [x for x in success.columns if x[0] != 'n_fail']])
    else:
        temp = (success.swaplevel(1, 0, axis=0).loc['rb']
                       .loc[:,
                            [x for x in success.columns if x[0] != 'n_fail']])

    first_success = temp.apply(lambda row: (row == 'Success').idxmax()[1],
                               axis=1)
    first_success.name = 'First Version Ruby Worked'

    test_impl = test_impl.join(first_success).fillna('')

    return test_impl


def update_and_upload():
    compat_matrix = parse_compatibility_matrix()
    df_files = find_info_osws(compat_matrix=compat_matrix, test_dir='./test/')

    model_test_cases = find_osm_test_versions()

    # Test Status
    success = success_sheet(df_files=df_files,
                            model_test_cases=model_test_cases)
    spreadsheet = '/EffiBEM&NREL-Regression-Test_Status'
    wks_name = 'Test_Status'
    print("Uploading to '{}'".format(wks_name), end="", flush=True)
    d2g.upload(success.T.reset_index().T.reset_index(),
               gfile=spreadsheet, wks_name=wks_name,
               row_names=False, col_names=False)
    print("... Done")

    # Missing / Implemented test
    test_impl = test_implemented_sheet(df_files=df_files,
                                       success=success,
                                       only_for_mising_osm=False)

    spreadsheet = '/EffiBEM&NREL-Regression-Test_Status'
    wks_name = 'Tests_Implemented'
    print("Uploading to '{}'".format(wks_name), end="", flush=True)
    d2g.upload(test_impl,
               gfile=spreadsheet, wks_name=wks_name,
               row_names=True, col_names=True)
    print("... Done")

    # Site kbtu
    site_kbtu = df_files.applymap(parse_total_site_energy)
    spreadsheet = '/EffiBEM&NREL-Regression-Test_Status'
    wks_name = 'SiteKBTU'
    print("Uploading to '{}'".format(wks_name), end="", flush=True)
    d2g.upload(site_kbtu.T.reset_index().T.reset_index().fillna(''),
               gfile=spreadsheet, wks_name=wks_name,
               # Skip first row
               start_cell='A1',
               row_names=False, col_names=False)
    print("... Done")

    # Rolling percent difference of total kBTU from one version to the next
    spreadsheet = '/EffiBEM&NREL-Regression-Test_Status'
    wks_name = 'SiteKBTU_Percent_Change'
    print("Uploading to '{}'".format(wks_name), end="", flush=True)
    d2g.upload((site_kbtu.pct_change(axis=1).T.reset_index().T
                         .reset_index().fillna('')),
               gfile=spreadsheet, wks_name=wks_name,
               row_names=False, col_names=False)
    print("... Done")


# If run from command line rather than imported
if __name__ == "__main__":

    question = ("Do you want to parse the regression OSWs from '{}' and upload"
                " to Google Sheets?".format(TEST_DIR))

    reply = str(input(question+' [Y/n]: ')).lower().strip()
    if reply[:1] == 'n':
        print("In this case, you can import this python file in an interactive"
              " environment to play with the results")
        sys.exit(0)

    update_and_upload()

    print("All results uploaded to {}".format(SHEET_URL))
