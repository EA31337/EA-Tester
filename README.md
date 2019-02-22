# About

Headless VM backtesting for MT4 platform under Linux.

## Build status

| Type            | Status      |
| --------------: |:-----------:|
| Travis CI build | [![Build Status](https://api.travis-ci.org/EA31337/EA-Tester.svg?branch=master)](https://travis-ci.org/EA31337/EA-Tester) |
| AppVeyor build  | [![Build status](https://ci.appveyor.com/api/projects/status/r4g7ughqovcv5ph5/branch/master?svg=true)](https://ci.appveyor.com/project/kenorb/ea-tester) |
| Docker build    | [![Docker build](https://images.microbadger.com/badges/image/ea31337/fx-mt-vm.svg)](https://microbadger.com/images/ea31337/fx-mt-vm "Docker build") |

## Usage

The easiest way is to [install Docker](https://www.docker.com/get-started), then run tester from the terminal:

    docker run ea31337/ea-tester help

to list available commands. Here is the list:

```
# Run backtest.
# Usage: run_backtest [args]
--
# Clone git repository.
# Usage: clone_repo [url] [args...]
--
# Get the backtest data.
# Usage: get_bt_data [currency] [year] [DS/MQ/N1-5/W1-5/C1-5/Z1-5/R1-5] [period]
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
# Replaces MetaEditor with the specific version.
# Usage: install_mteditor [ver/5.0.0.1804]
--
# Configure virtual display and wine.
# Usage: set_display
--
# Detect and configure proxy.
# Usage: set_proxy
--
# Display recent logs.
# Usage: show_logs
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
# Compile the given EA name.
# Usage: compile_ea [pattern] [log_file]
--
# Compile and test the given EA.
# Usage: compile_and_test [pattern] [args...]
--
# Copy ini settings from templates.
# Usage: ini_copy
--
# Find the EA file.
# Usage: ea_find [filename/url/pattern]
--
# Find the script file.
# Usage: script_find [filename/url/pattern]
--
# Copy EA file to the platform experts dir.
# Usage: ea_copy [file]
--
# Copy script file to the platform scripts dir.
# Usage: script_copy [file]
--
# Copy library file (e.g. dll) to the platform lib dir.
# Usage: lib_copy [file]
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
# Compile given script name.
# Usage: compile_script
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
# Set input value in the SET file.
# Usage: input_set [key] [value] [file]
--
# Get input value from the SET file.
# Usage: input_get [key] [file]
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
# Get value from the INI/HTM file.
# Usage: ini_get [key] [file]
--
# Get all values from the INI/HTM file.
# Usage: value_get_all [file]
--
# Set spread in ini and FXT files.
# Usage: set_spread [points/10]
--
# Set lot step in FXT files.
# Usage: set_lotstep [size/0.01]
--
# Set digits in symbol raw file.
# Usage: set_digits [value/5]
```

### Backtesting

Here is the example command for running backtest on MACD using historical data from 2018:

    docker run ea31337/ea-tester run_backtest -e MACD -y 2018 -v -t

To backtest EA31337 bot, check: [Backtesting using Docker](https://github.com/EA31337/EA31337/wiki/Backtesting-using-Docker).

To customize the command, here are the supported parameters and variables:

```
  -b (option)
    Source of backtest data to test. Default: DS
    Variable (string): BT_SRC
  -B (filename)
    Specify early booting script to execute.
    Variable (string): INCLUDE_BOOT
  -c (currency)
    Base currency for test. Default: USD
    Variable (string): BT_CURRENCY
  -C
    Clear previous backtest data files.
  -d (amount)
    Deposit amount to test. Default: 10000
    Variable (int): BT_DEPOSIT
  -D (digits)
    Specify market digits (e.g. 5 or 4).
    Variable (uint): BT_DIGITS
  -e (filename/url/pattern)
    EA name to test (TestExpert).
    Variable (string): EXPERT
  -E (filename/url/pattern)
    EA name to run (Expert).
    Variable (string): EXPERT
  -f (filename/auto)
    The .set file to run the test.
    When in optimization mode, better settings are applied into that file.
    If file doesn't exist, generate one from EA.
    Variable (string): SETFILE
  -F
    Convert test report file to full detailed text format.
    Variable (bool): OPT_FORMAT_FULL
  -g
    Post results to Gist. It enables: -j and -t
    Variables (bool): OPT_GIST
  -G
    Enhance gif report files.
    Variable (bool): OPT_GIF_ENHANCE
  -i (file)
    Invoke file with custom rules.
    Variable (string): INCLUDE
  -I (options)
    Change tester INI file with custom settings (e.g. Server=MetaQuotes-Demo,Login=123).
    Variable (string): TEST_OPTS
  -j
    Convert test report file into JSON format.
    Variable (bool): OPT_FORMAT_JSON
  -l (double)
    Specify a lot step (e.g. 0.01).
    Variable (float): BT_LOTSTEP
  -L (limit)
    EA common/limit test parameters separated by comma (e.g. genetic=0,maxdrawdown_enable=1,maxdrawdown=20.00).
    Variable (string): EA_OPTS
  -m (month)
    Month to test. Default: 1-12.
    Variable (uint/string): BT_MONTHS
  -M (version)
    Specify version of MetaTrader (e.g. 4, 4x, 5, 4.0.0.1010). Default: 4.0.0.1010
  -o
    Run test in optimization mode.
    Variable (bool): OPT_OPTIMIZATION
  -O (dir)
    Output directory to save the test results. Default: /opt/results for Docker container.
    Variable (string): BT_DEST
  -p (pair)
    Symbol pair to test (e.g. EURUSD).
  -P (param)
    Set EA param in SET file (e.g. VerboseInfo=1,TakeProfit=0).
    Variable (string): SET_OPTS
  -r (string)
    The name of the test report file. Default: tester/Report
    Variable (string): TEST_REPORT_NAME
  -R
    Set files to read-only.
  -s (file/url/pattern)
    Script to run (Script).
    Variable (string): SCRIPT
  -S (spread)
    Spread to test in points.
    Variable (uint): BT_SPREAD
  -t
    Convert test report file into brief text format.
    Variable (bool): OPT_FORMAT_BRIEF
  -T (timeframe)
    Timeframe (TestPeriod) to test. Default: M30
    Variable (string): BT_PERIOD
  -v
    Verbose mode.
    Variable (bool): OPT_VERBOSE
  -V
    Run test in visual mode (TestVisualEnable).
    Variable (bool): VISUAL_MODE
  -x
    Run the script in trace/debug mode.
    Variable (bool): OPT_TRACE
  -X (file)
    Invoke file on exit after the successful test.
  -y (year)
    Year to test. Default: 2017
    Variable (uint/string): BT_YEARS
  -?
    Display help.

Other supported variables (without arguments assigned):
- BT_DAYS (uint/string)
  Specify days to test. Default: 1-31.
- BT_TESTMODE (uint)
  This controls type of backtest data being downloaded.
  Values: 0 (default) - Every tick, 1 - Control points, 2 - Open prices only
- OPT_NOERR (bool)
  Disables errexit flag to prevent exiting script on failure.
- RUN_ON_START (string)
  Run shell code on startup (before the test).
- RUN_ON_SET (string)
  Run shell code on SET configuration (e.g. "file_get URL").
- RUN_ON_EXIT (string)
  Run shell code on exit (after the test).
- JSON_PARSER (string)
  Command to parse JSON file (e.g. jq or python).
```
