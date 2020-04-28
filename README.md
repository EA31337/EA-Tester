<!-- markdownlint-configure-file { "MD013": { "line_length": 120 } } -->

# About

Headless VM backtesting for MT4 platform under Linux.

## Build status

| Type            | Status      |
| --------------: |:-----------:|
| Travis CI build | [![Build Status][travis-ci-build-image-master]][travis-ci-build-link] |
| AppVeyor build  | [![Build status][appveyor-ci-build-link]][appveyor-ci-build-image] |
| Docker build    | [![Docker build][docker-build-image]][docker-build-link] |

[travis-ci-build-link]: https://travis-ci.org/EA31337/EA-Tester
[travis-ci-build-image-master]: https://api.travis-ci.org/EA31337/EA-Tester.svg?branch=master
[appveyor-ci-build-link]: https://ci.appveyor.com/api/projects/status/r4g7ughqovcv5ph5/branch/master?svg=true
[appveyor-ci-build-image]: https://ci.appveyor.com/project/kenorb/ea-tester
[docker-build-image]: https://images.microbadger.com/badges/image/ea31337/ea-tester.svg
[docker-build-link]: https://microbadger.com/images/ea31337/ea-tester

## Usage

The easiest way is to [install Docker](https://www.docker.com/get-started), then run tester from the terminal:

    docker run ea31337/ea-tester help

to list available commands. Here is the list:

    ```console
    # Run backtest.
    # Usage: run_backtest [args]
    --
    # Run Terminal.
    # Usage: run_terminal
    --
    # Clone git repository.
    # Usage: clone_repo [url] [args...]
    --
    # Download backtest data.
    # Usage: bt_data_dl [-v] [-D DEST] [-c] [-p PAIRS] [-h HOURS] [-d DAYS] [-m MONTHS] [-y YEARS]
    --
    # Generate backtest data.
    # Usage: bt_data_gen [-D DIGITS] [-s SPREAD] [-d DENSITY] [-p {none,wave,curve,zigzag,random}] [-v VOLATILITY] [-o OUTPUTFILE]
    --
    # Download backtest data from GitHub
    # Usage: bt_data_get [currency] [year] [DS/MQ/N1-5/W1-5/C1-5/Z1-5/R1-5] [period]
    --
    # Read MT file.
    # Usage: mt_read -i INPUTFILE -t INPUTTYPE
    --
    # Modify MT file.
    # Usage: mt_modify -i INPUTFILE -t INPUTTYPE -k KEYGROUP [-d] [-a DOADD] [-m DOMODIFY]
    --
    # Convert CSV files to FXT/HST formats.
    # Usage: conv_csv_to_mt -i INPUTFILE [-f OUTPUTFORMAT] [-s SYMBOL] [-t TIMEFRAME] [-p SPREAD] [-d OUTPUTDIR] [-S SERVER] [-v] [-m MODEL]
    --
    # Change the working directory.
    # Usage: chdir [dir]
    --
    # Check logs for specific text.
    # Usage: check_logs [filter] [args]
    --
    # Display logs in real-time.
    # Usage: live_logs [invert-match] [interval]
    --
    # Display performance stats in real-time.
    # Usage: live_stats [interval]
    --
    # Delete compiled EAs.
    # Usage: clean_ea
    --
    # Clean files (e.g. previous report and log files).
    # Usage: clean_files
    --
    # Delete backtest data files.
    # Usage: clean_bt
    --
    # Check the version of the given binary file.
    # Usage: filever [file/terminal.exe]
    --
    # Install platform.
    # Usage: install_mt [ver/4/5/4.0.0.1010]
    --
    # Configure virtual display and wine.
    # Usage: set_display
    --
    # Detect and configure proxy.
    # Usage: set_proxy
    --
    # Display recent logs.
    # Usage: show_logs (lines_no/40)
    --
    # Copy script file given the file path.
    # Usage: script_copy [file]
    --
    # Copy library file (e.g. dll) given the file path.
    # Usage: lib_copy [file]
    --
    # Copy a file given the file path.
    # Usage: file_copy [file]
    --
    # Copy srv files into terminal dir.
    # Usage: srv_copy [file]
    --
    # Download the file.
    # Usage: file_get [url]
    --
    # Compile the source code file.
    # Usage: compile [file/dir] (log_file) (...args)
    --
    # Compile specified EA file.
    # Usage: compile_ea [EA/pattern] (log_file) (...args)
    --
    # Compile specified script file.
    # Usage: compile_script [Script/pattern] (log_file) (...args)
    --
    # Compile all in MQL4 folder.
    # Usage: compile_all (log_file/CON)
    --
    # Compile and test the given EA.
    # Usage: compile_and_test [EA/pattern] (args...)
    --
    # Copy ini settings from templates.
    # Usage: ini_copy
    --
    # Find the EA file.
    # Usage: ea_find [filename/url/pattern] (optional/dir)
    --
    # Find the script file.
    # Usage: script_find [filename/url/pattern] (optional/dir)
    --
    # Copy EA file to the platform experts dir.
    # Usage: ea_copy [file] [optional/dir-dst]
    --
    # Copy script file to the platform scripts dir.
    # Usage: script_copy [file] [optional/dir-dst]
    --
    # Copy library file (e.g. dll) to the platform lib dir.
    # Usage: lib_copy [file] [optional/dir-dst]
    --
    # Copy a file to the platform files dir.
    # Usage: file_copy [file]
    --
    # Convert HTML to text format.
    # Usage: convert_html2txt [file_src] [file_dst]
    --
    # Convert HTML to text format (full version).
    # Usage: convert_html2txt_full [file_src] [file_dst]
    --
    # Convert HTML to JSON format
    # Usage: convert_html2json [file_src] [file_dst]
    --
    # Sort optimization test result values by profit factor.
    # Usage: sort_opt_results [file/report.html]
    --
    # Post results to gist.
    # Usage: gist_results [dir] [files/pattern]
    --
    # Enhance a GIF report file.
    # Usage: enhance_gif -c1 [color_name] -c2 [color_name] -t "Some text with \\\n new lines"
    --
    # Run platform and kill it.
    # Usage: quick_run
    --
    # Set value in the INI file.
    # Usage: ini_set [key] [value] [file]
    --
    # Delete value from the INI file.
    # Usage: ini_del [key] [file]
    --
    # Set value in the EA INI file.
    # Usage: ini_set_ea [key] [value]
    --
    # Set inputs in the EA INI file.
    # Usage: ini_set_inputs [set_file] [ini_file]
    --
    # Get value from the INI file.
    # Usage: ini_get [key] (file)
    --
    # Get value from the HTM file.
    # Usage: htm_get [key] (file)
    --
    # Get all values from the INI/HTM file.
    # Usage: value_get_all [file]
    --
    # Updates value in FXT/HST files.
    # Usage: set_data_value [key] [value] [fxt/hst]
    --
    # Set spread in ini and FXT files.
    # Usage: set_spread [points/10]
    --
    # Set lot step in FXT files.
    # Usage: set_lotstep [size/0.01]
    --
    # Set digits in symbol raw file.
    # Usage: set_digits [value/5]
    --
    # Set account leverage in FXT files.
    # Usage: set_leverage [value]
    ```

### Backtesting

Here is the example command for running backtest on MACD using historical data from 2018:

    docker run ea31337/ea-tester run_backtest -e MACD -y 2018 -v -t

To backtest EA31337 bot, check: [Backtesting using Docker](https://github.com/EA31337/EA31337/wiki/Backtesting-using-Docker).

### CLI options

Check [`scripts/options.txt`](scripts/options.txt) file for supported parameters and variables.

### Support

- For bugs/features, raise a [new issue at GitHub](https://github.com/EA31337/EA-Tester/issues).
- Join our [Telegram group](https://t.me/EA31337) and [channel](https://t.me/EA31337_Announcements) for help.
