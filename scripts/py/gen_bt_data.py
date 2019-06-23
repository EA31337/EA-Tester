#!/usr/bin/env python3
# Script to generate backtest data in CSV format.
# Example usage:
#  ./gen_bt_data.py -s 10 -p random -v 100 2018.01.01 2018.01.30 2.0 4.0 | gnuplot -p -e "set datafile separator ','; plot '-' using 3 w l"

import argparse
import sys
import datetime
import csv
import random
from math import ceil, exp, pi, sin

def error(message, exit=True):
    print('[ERROR]', message)
    if exit: sys.exit(1)


def volumesFromTimestamp(timestamp, spread):
    longTimestamp = timestamp.timestamp()
    spread *= 1e5
    d = int(str(int(longTimestamp/60))[-3:]) + 1
    bidVolume = int((longTimestamp/d)%(1e3 - spread))

    return (bidVolume, bidVolume + spread)


def linearModel(startDate, endDate, startPrice, endPrice, deltaTime, spread):
    timestamp = startDate
    bidPrice = startPrice
    askPrice = bidPrice + spread
    bidVolume = 1
    askVolume = bidVolume + spread
    deltaPrice = deltaTime/(endDate + datetime.timedelta(days=1) - startDate - deltaTime)*(endPrice - startPrice)
    ticks = []
    while timestamp < (endDate + datetime.timedelta(days=1)):
        ticks += [{
            'timestamp': timestamp,
             'bidPrice': bidPrice,
             'askPrice': askPrice,
            'bidVolume': bidVolume,
            'askVolume': askVolume
        }]
        timestamp += deltaTime
        bidPrice += deltaPrice
        askPrice += deltaPrice
        (bidVolume, askVolume) = volumesFromTimestamp(timestamp, spread)
    return ticks


def zigzagModel(startDate, endDate, startPrice, endPrice, deltaTime, spread, volatility):
    timestamp = startDate
    bidPrice = startPrice
    askPrice = bidPrice + spread
    bidVolume = 1
    askVolume = bidVolume + spread
    deltaPrice = endPrice - startPrice
    count = ceil((endDate + datetime.timedelta(days=1) - startDate)/deltaTime)
    lift = deltaPrice/count
    forward = 500
    backward = int(volatility*50)
    ticks = []
    # Calculate zigzag body
    for i in range(0, count - backward):
        ticks += [{
            'timestamp': timestamp,
             'bidPrice': bidPrice,
             'askPrice': askPrice,
            'bidVolume': bidVolume,
            'askVolume': askVolume
        }]
        i += 1
        timestamp += deltaTime
        if i%(forward + backward) < forward:
            bidPrice += (forward + 2*backward)/forward*lift
        else:
            bidPrice -= lift
        askPrice = bidPrice + spread
        (bidVolume, askVolume) = volumesFromTimestamp(timestamp, spread)

    # Calculate tail as a linear line
    lift = (endPrice - bidPrice)/(backward - 1)
    for i in range(count - backward, count):
        ticks += [{
            'timestamp': timestamp,
             'bidPrice': bidPrice,
             'askPrice': askPrice,
            'bidVolume': bidVolume,
            'askVolume': askVolume
        }]
        i += 1
        timestamp += deltaTime
        bidPrice += lift
        askPrice = bidPrice + spread
        (bidVolume, askVolume) = volumesFromTimestamp(timestamp, spread)
    return ticks


def waveModel(startDate, endDate, startPrice, endPrice, deltaTime, spread, volatility):
    timestamp = startDate
    bidPrice = startPrice
    askPrice = bidPrice + spread
    bidVolume = 1
    askVolume = bidVolume + spread
    deltaPrice = endPrice - startPrice
    count = ceil((endDate + datetime.timedelta(days=1) - startDate)/deltaTime)
    d = count/2  # Denominator for curve shaping
    ticks = []
    for i in range(0, count):
        ticks += [{
            'timestamp': timestamp,
             'bidPrice': bidPrice,
             'askPrice': askPrice,
            'bidVolume': bidVolume,
            'askVolume': askVolume
        }]
        i += 1
        timestamp += deltaTime
        # Select appropriate formula depending on starting and ending prices
        if abs(deltaPrice) > 0:
            bidPrice = abs(startPrice + i/(count - 1)*deltaPrice + volatility*sin(i/(count - 1)*3*pi))
        else:
            bidPrice = abs(startPrice + (volatility*sin(i/(count - 1)*3*pi)))
        askPrice = bidPrice + spread
        (bidVolume, askVolume) = volumesFromTimestamp(timestamp, spread)
    return ticks


def curveModel(startDate, endDate, startPrice, endPrice, deltaTime, spread, volatility):
    timestamp = startDate
    bidPrice = startPrice
    askPrice = bidPrice + spread
    bidVolume = 1
    askVolume = bidVolume + spread
    deltaPrice = endPrice - startPrice
    count = ceil((endDate + datetime.timedelta(days=1) - startDate)/deltaTime)
    d = count/volatility  # A kind of volatility interpretation via curve shaping
    ticks = []
    for i in range(0, count):
        ticks += [{
            'timestamp': timestamp,
             'bidPrice': bidPrice,
             'askPrice': askPrice,
            'bidVolume': bidVolume,
            'askVolume': askVolume
        }]
        i += 1
        timestamp += deltaTime
        bidPrice = startPrice + (1 - (exp(i/d) - exp((count - 1)/d))/(1 - exp((count - 1)/d)))*deltaPrice
        askPrice = bidPrice + spread
        (bidVolume, askVolume) = volumesFromTimestamp(timestamp, spread)
    return ticks


def randomModel(startDate, endDate, startPrice, endPrice, deltaTime, spread, volatility):
    timestamp = startDate
    bidPrice = startPrice
    askPrice = bidPrice + spread
    bidVolume = 1
    askVolume = bidVolume + spread
    deltaPrice = deltaTime/(endDate + datetime.timedelta(days=1) - startDate - deltaTime)*(endPrice - startPrice)
    count = ceil((endDate + datetime.timedelta(days=1) - startDate)/deltaTime)
    ticks = []
    for i in range(0, count):
        ticks += [{
            'timestamp': timestamp,
             'bidPrice': bidPrice,
             'askPrice': askPrice,
            'bidVolume': bidVolume,
            'askVolume': askVolume
        }]
        timestamp += deltaTime
        bidPrice += deltaPrice + deltaPrice * (random.random()-0.5) * volatility
        askPrice = bidPrice + spread
        (bidVolume, askVolume) = volumesFromTimestamp(timestamp, spread)
    ticks[-1]['bidPrice'] = endPrice
    ticks[-1]['askPrice'] = endPrice + spread
    return ticks


def toCsv(rows, digits, output):
    csvWriter = csv.writer(output, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
    for row in rows:
        csvWriter.writerow([
            row['timestamp'].strftime('%Y.%m.%d %H:%M:%S.%f')[:-3],
            ('{:.%df}' % (digits)).format(max(row['bidPrice'], 10**-digits)),
            ('{:.%df}' % (digits)).format(max(row['askPrice'], 10**-digits)),
            ('{:.%df}' % (digits)).format(row['bidVolume']),
            ('{:.%df}' % (digits)).format(row['askVolume'])
        ])


if __name__ == '__main__':
    argumentParser = argparse.ArgumentParser()
    argumentParser.add_argument('startDate',
                                help='Starting date of generated data in YYYY.MM.DD format.')
    argumentParser.add_argument('endDate',
                                help='Ending date of generated data in YYYY.MM.DD format.')
    argumentParser.add_argument('startPrice',
                                type=float,
                                help='Starting bid price of generated data, must be a float value.')
    argumentParser.add_argument('endPrice',
                                type=float,
                                help='Ending bid price of generated data, must be a float value.')
    argumentParser.add_argument('-D', '--digits',
                                type=int,
                                action='store',
                                dest='digits',
                                help='Decimal digits of prices.',
                                default=5)
    argumentParser.add_argument('-s', '--spread',
                                type=int,
                                action='store',
                                dest='spread',
                                help='Spread between prices in points.',
                                default=10)
    argumentParser.add_argument('-d', '--density',
                                type=int,
                                action='store',
                                dest='density',
                                help='Data points per minute in generated data.',
                                default=1)
    argumentParser.add_argument('-p', '--pattern',
                                action='store',
                                dest='pattern',
                                choices=['none', 'wave', 'curve', 'zigzag', 'random'],
                                help='Modelling pattern, all of them are deterministic except of \'random\'.', default='none')
    argumentParser.add_argument('-v', '--volatility',
                                type=float,
                                action='store',
                                dest='volatility',
                                help='Volatility gain for models, higher values leads to higher volatility in price values.',
                                default=1.0)
    argumentParser.add_argument('-o', '--outputFile',
                                action='store',
                                dest='outputFile',
                                help='Write generated data to file instead of standard output.')
    arguments = argumentParser.parse_args()

    # Check date values
    try:
        startDate = datetime.datetime.strptime(arguments.startDate, '%Y.%m.%d')
        endDate   = datetime.datetime.strptime(arguments.endDate,   '%Y.%m.%d')
    except ValueError as e:
        error('Bad date format!')

    if endDate < startDate: error('Ending date precedes starting date!')

    if arguments.digits <= 0: error('Digits must be larger than zero!')

    if arguments.startPrice <= 0 or arguments.endPrice <= 0: error('Price must be larger than zero!')

    if arguments.spread < 0: error('Spread must be larger or equal to zero!')
    spread = arguments.spread/1e5

    if arguments.density <= 0: error('Density must be larger than zero!')

    if arguments.volatility <= 0: error('Volatility must be larger than zero!')

    # Select and run appropriate model
    deltaTime = datetime.timedelta(seconds=60/arguments.density)
    rows = None
    if arguments.pattern == 'none':
        rows = linearModel(startDate, endDate, arguments.startPrice, arguments.endPrice, deltaTime, spread)
    elif arguments.pattern == 'zigzag':
        rows = zigzagModel(startDate, endDate, arguments.startPrice, arguments.endPrice, deltaTime, spread, arguments.volatility)
    elif arguments.pattern == 'wave':
        rows = waveModel(startDate, endDate, arguments.startPrice, arguments.endPrice, deltaTime, spread, arguments.volatility)
    elif arguments.pattern == 'curve':
        rows = curveModel(startDate, endDate, arguments.startPrice, arguments.endPrice, deltaTime, spread, arguments.volatility)
    elif arguments.pattern == 'random':
        rows = randomModel(startDate, endDate, arguments.startPrice, arguments.endPrice, deltaTime, spread, arguments.volatility)

    # output array stdout/file
    if arguments.outputFile:
        with open(arguments.outputFile, 'w') as outputFile:
            toCsv(rows, arguments.digits, outputFile)
    else:
        toCsv(rows, arguments.digits, sys.stdout)
