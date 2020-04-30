<!-- markdownlint-configure-file { "MD013": { "line_length": 120 } } -->
[![Release][github-release-image]][github-release-link]
[![Docker build][docker-build-image]][docker-build-link]
[![](https://img.shields.io/badge/news-Telegram-0088CC.svg?logo=telegram)](https://t.me/EA31337_News)
[![](https://img.shields.io/badge/chat-Telegram-0088CC.svg?logo=telegram)](https://t.me/EA31337)
[![Edit][gitpod-image]][gitpod-link]

[github-release-image]: https://img.shields.io/github/release/EA31337/EA-Tester.svg?logo=github
[github-release-link]: https://github.com/EA31337/EA-Tester/releases
[docker-build-image]: https://images.microbadger.com/badges/image/ea31337/ea-tester.svg
[docker-build-link]: https://microbadger.com/images/ea31337/ea-tester
[gitpod-image]: https://img.shields.io/badge/Gitpod-ready--to--code-blue?logo=gitpod
[gitpod-link]: https://gitpod.io/#https://github.com/EA31337/EA-Tester

# About

Headless VM backtesting for MT4 platform under Linux.

## Build status

| Type            | `master`      | `dev` |
| --------------: |:-----------:| :----: |
| MQL Compilation | [![Status][appveyor-ci-build-link]][appveyor-ci-build-image] |
| Shell Tests | [![Status][gha-image-shell-master]][gha-link-shell-master] | [![Status][gha-image-shell-dev]][gha-link-shell-dev]
| MQL Tests | [![Status][gha-image-mql-master]][gha-link-mql-master] | [![Status][gha-image-mql-dev]][gha-link-mql-dev]
| Syntax and formatting | [![Status][gha-image-lint-master]][gha-link-lint-master] | [![Status][gha-image-lint-dev]][gha-link-lint-dev]
| Travis CI build | [![Status][travis-ci-build-image-master]][travis-ci-build-link] | [![Status][travis-ci-build-image-dev]][travis-ci-build-link]

<!-- Travis CI build links -->
[travis-ci-build-link]: https://travis-ci.org/EA31337/EA-Tester
[travis-ci-build-image-master]: https://api.travis-ci.org/EA31337/EA-Tester.svg?branch=master
[travis-ci-build-image-dev]: https://api.travis-ci.org/EA31337/EA-Tester.svg?branch=dev

<!-- AppVeyor CI build links -->
[appveyor-ci-build-link]: https://ci.appveyor.com/api/projects/status/r4g7ughqovcv5ph5/branch/master?svg=true
[appveyor-ci-build-image]: https://ci.appveyor.com/project/kenorb/ea-tester

<!-- GitHub Actions CI build links - Tests-Shell -->
[gha-link-shell-master]: https://github.com/EA31337/EA-Tester/actions?query=workflow%3ATests-Shell
[gha-link-shell-dev]: https://github.com/EA31337/EA-Tester/actions?query=workflow%3ATests-Shell+branch%3Adev
[gha-image-shell-master]: https://github.com/EA31337/EA-Tester/workflows/Tests-Shell/badge.svg
[gha-image-shell-dev]: https://github.com/EA31337/EA-Tester/workflows/Tests-Shell/badge.svg?branch=dev

<!-- GitHub Actions CI build links - Tests-MQL -->
[gha-link-mql-master]: https://github.com/EA31337/EA-Tester/actions?query=workflow%3ATests-MQL
[gha-link-mql-dev]: https://github.com/EA31337/EA-Tester/actions?query=workflow%3ATests-MQL+branch%3Adev
[gha-image-mql-master]: https://github.com/EA31337/EA-Tester/workflows/Tests-MQL/badge.svg
[gha-image-mql-dev]: https://github.com/EA31337/EA-Tester/workflows/Tests-MQL/badge.svg?branch=dev

<!-- GitHub Actions CI build links - Lint -->
[gha-link-lint-master]: https://github.com/EA31337/EA-Tester/actions?query=workflow%3ALint
[gha-link-lint-dev]: https://github.com/EA31337/EA-Tester/actions?query=workflow%3ALint+branch%3Adev
[gha-image-lint-master]: https://github.com/EA31337/EA-Tester/workflows/Lint/badge.svg
[gha-image-lint-dev]: https://github.com/EA31337/EA-Tester/workflows/Lint/badge.svg?branch=dev

## Usage

The easiest way is to [install Docker](https://www.docker.com/get-started), then run tester from the terminal:

    docker run ea31337/ea-tester help

to list available commands.

### Backtesting

Here is the example command for running backtest on MACD using historical data from 2018:

    docker run ea31337/ea-tester run_backtest -e MACD -y 2018 -v -t

To backtest EA31337 bot, check: [Backtesting using Docker](https://github.com/EA31337/EA31337/wiki/Backtesting-using-Docker).

### CLI options

Check [`scripts/options.txt`](scripts/options.txt) file for supported parameters and variables.

### Support

- For bugs/features, raise a [new issue at GitHub](https://github.com/EA31337/EA-Tester/issues).
- Join our [Telegram group](https://t.me/EA31337) and [channel](https://t.me/EA31337_Announcements) for help.
