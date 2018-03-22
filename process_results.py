"""
Command Line Utility (CLI) to parse and analyze the regression tests results.

Use it like so:
  python process-results.py command [options]

Usage:
  process-results.py heatmap [-r <r_t> | --row_threshold=<r_t>] [-d <d_t> | --display_threshold=<d_t>] [--indiv_axes] [--figname_with_thresholds]
  process-results.py heatmap [--figname_with_thresholds] [--granular [--indiv_axes]]
  process-results.py upload
  process-results.py -h | --help

Options:
  -r <r_t>, --row_threshold=<r_t>      Row Threshold [default: 0.01]
        Only display tests where there is at least one cell (=one OpenStudio
        Version) that has a change greater than this.
        This value is a percentage, eg: 0.005 means at least 0.5% change

  -d <d_t>, --display_threshold=<d_t>  Display threshold [default: 0.001]
        Apply the colorscale to the cells that are above this threshold,
        otherwise they get greyed out.

  -g, --granular    Defaults row and display thresholds, see examples section

  -i, --indiv_axes  Save individual axes [default: False]
                    If a big figure is generated, save it several smaller
                    chunks, useful when used in conjuction with --granular

  -f, --figname_with_thresholds
        Append row and display thresholds to the heatmap figure name

  -h, --help         Show this screen.

Examples:
  process-results.py heatmap
        Parse results and generate a heatmap with default values
        of --row_threshold=0.01 and --display_threshold=0.005

  process-results.py heatmap --granular
        Heatmap with values of --row_threshold=0.0005
        and --display_threshold=0.0001

  process-results.py heatmap -g -i -f
        Granular heatmap, save individual axes, and figure name with thresholds

  process-results.py heatmap --row_threshold=0.01 --display_threshold=0.001
  process-results.py heatmap -r 0.01 -d 0.001
        Parse results and generate a heatmap with custom thresholds

  process-results.py upload
        Upload to the google spreadsheet.
        THIS SHOULD ONLY BE DONE ONCE THE OFFICIAL RELEASE IS OUT AND AFTER
        RUNNING ALL TESTS WITH THIS NEW VERSION.

Help:
  For help using this tool, please open an issue on the Github repository:
  https://github.com/NREL/OpenStudio-resources
"""

from docopt import docopt


if __name__ == "__main__":

    """Main CLI entrypoint."""
    from python.regression_analysis import cli_heatmap, cli_upload
    options = docopt(__doc__)

    if options['heatmap']:
        if options['--granular']:
            options['--row_threshold'] = 0.0005
            options['--display_threshold'] = 0.0001
        else:
            try:

                r_t = float(options['--row_threshold'])
                options['--row_threshold'] = r_t

                d_t = float(options['--display_threshold'])
                options['--display_threshold'] = d_t
            except ValueError:
                print("row_threshold and display_threshold must be numeric")
                exit()

        cli_heatmap(row_threshold=options['--row_threshold'],
                    display_threshold=options['--display_threshold'],
                    save_indiv_figs_for_ax=options['--indiv_axes'],
                    figname_with_thresholds=options['--figname_with_thresholds'])
    elif options['upload']:
        cli_upload()
