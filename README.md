# EA Tester

[![Release][github-release-image]][github-release-link]
[![License][license-image]][license-link]
[![Docker image][docker-build-image]][docker-build-link]
[![AppVeyor][appveyor-ci-build-link]][appveyor-ci-build-image]
[![Status][gha-image-check-master]][gha-link-check-master]
[![Status][gha-image-lint-master]][gha-link-lint-master]
[![Status][gha-image-shell-master]][gha-link-shell-master]
[![Status][gha-image-mql-master]][gha-link-mql-master]
[![Channel][tg-channel-image]][tg-channel-link]
[![Chat][tg-chat-image]][tg-chat-link]
[![Edit Code][gitpod-image]][gitpod-link]

## About

Headless Forex backtesting for MetaTrader platform using Docker.

## Usage

The easiest way is to [install Docker](https://www.docker.com/get-started), then run tester from the terminal:

```shell
docker run ea31337/ea-tester help
```

to list available commands.

### Backtesting

Here is the example command for running backtest on MACD using historical data from 2019:

```shell
docker run ea31337/ea-tester run_backtest -e MACD -y 2019 -v -t
```

To backtest EA31337 bot, check: [Backtesting using Docker](https://github.com/EA31337/EA31337/wiki/Backtesting-using-Docker).

### CLI options

Check [`scripts/options.txt`](scripts/options.txt) file for supported parameters and variables.

### Support

- For bugs/features, raise a [new issue at GitHub](https://github.com/EA31337/EA-Tester/issues).
- Join our [Telegram group][tg-chat-link] and [channel][tg-channel-link] for help.

<!-- Named links -->

[github-release-image]: https://img.shields.io/github/release/EA31337/EA-Tester.svg?logo=github
[github-release-link]: https://github.com/EA31337/EA-Tester/releases

[license-image]: https://img.shields.io/github/license/EA31337/EA-Tester.svg
[license-link]: https://tldrlegal.com/license/mit-license

[docker-build-image]: https://images.microbadger.com/badges/image/ea31337/ea-tester.svg
[docker-build-link]: https://microbadger.com/images/ea31337/ea-tester

[appveyor-ci-build-link]: https://ci.appveyor.com/project/kenorb/ea-tester/branch/master
[appveyor-ci-build-image]: https://ci.appveyor.com/api/projects/status/r4g7ughqovcv5ph5/branch/master?svg=true

[travis-ci-build-link]: https://travis-ci.org/EA31337/EA-Tester
[travis-ci-build-image-master]: https://api.travis-ci.org/EA31337/EA-Tester.svg?branch=master
[travis-ci-build-image-dev]: https://api.travis-ci.org/EA31337/EA-Tester.svg?branch=dev

[appveyor-ci-build-link]: https://ci.appveyor.com/api/projects/status/r4g7ughqovcv5ph5/branch/master?svg=true
[appveyor-ci-build-image]: https://ci.appveyor.com/project/kenorb/ea-tester

[gha-link-check-master]: https://github.com/EA31337/EA-Tester/actions?query=workflow%3ACheck+branch%3Amaster
[gha-image-check-master]: https://github.com/EA31337/EA-Tester/workflows/Check/badge.svg

[gha-link-lint-master]: https://github.com/EA31337/EA-Tester/actions?query=workflow%3ALint+branch%3Amaster
[gha-image-lint-master]: https://github.com/EA31337/EA-Tester/workflows/Lint/badge.svg

[gha-link-shell-master]: https://github.com/EA31337/EA-Tester/actions?query=workflow%3ATests-Shell+branch%3Amaster
[gha-image-shell-master]: https://github.com/EA31337/EA-Tester/workflows/Tests-Shell/badge.svg

[gha-link-mql-master]: https://github.com/EA31337/EA-Tester/actions?query=workflow%3ATests-MQL+branch%3Amaster
[gha-image-mql-master]: https://github.com/EA31337/EA-Tester/workflows/Tests-MQL/badge.svg

[tg-channel-image]: https://img.shields.io/badge/Telegram-news-0088CC.svg?logo=telegram
[tg-channel-link]: https://t.me/EA31337_News
[tg-chat-image]: https://img.shields.io/badge/Telegram-chat-0088CC.svg?logo=telegram
[tg-chat-link]: https://t.me/EA31337

[gitpod-image]: https://img.shields.io/badge/Gitpod-ready--to--code-blue?logo=gitpod
[gitpod-link]: https://gitpod.io/#https://github.com/EA31337/EA-Tester
