#!/usr/bin/env python3
# Script to convert CSV files into FXT/HST formats.

import argparse
import sys
import os
import csv
import re
from struct import pack, pack_into, calcsize
import time
import datetime
import mmap

class Spinner:
    def __init__(self, step):
        self._n = self._x = 0
        self._chars = '\\|/-'
        self._step = step

    def spin(self):
        self._n += 1

        if self._n % self._step == 0:
            sys.stdout.write('\b' + self._chars[self._x % 4])
            sys.stdout.flush()

            self._x += 1

            if self._x >= 4:
                self._x = 0

            self._n = 0

spinner = Spinner(100000)

class Input:
    def __init__(self, path):
        if args.verbose:
            print('[INFO] Trying to read data from %s...' % path)
        try:
            self.path = open(path, 'r')
        except OSError as e:
            print("[ERROR] '%s' raised when tried to read the file '%s'" % (e.strerror, e.filename))
            sys.exit(1)

    def __del__(self):
        self.path.close()

    def _addBar(self, barTimestamp, tickTimestamp, open, high, low, close, volume):
        self.uniBars += [{
            'barTimestamp': barTimestamp,
           'tickTimestamp': tickTimestamp,
                    'open': open,
                    'high': high,
                     'low': low,
                   'close': close,
                  'volume': volume
        }]

def string_to_timestamp(s):
    try_microseconds = s[20:]

    if try_microseconds == '':
        microseconds = int(s[20:])
    else:
        microseconds = 0

    return datetime.datetime(
            int(s[0:4]),   # Year
            int(s[5:7]),   # Month
            int(s[8:10]),  # Day
            int(s[11:13]), # Hour
            int(s[14:16]), # Minute
            int(s[17:19]), # Second
            microseconds,  # Microseconds
            datetime.timezone.utc)

class CSV(Input):
    def __init__(self, path):
        super().__init__(path)
        if os.name == "nt":
            self._map_obj = mmap.mmap(self.path.fileno(), 0, access=mmap.ACCESS_READ)
        else:
            self._map_obj = mmap.mmap(self.path.fileno(), 0, prot=mmap.PROT_READ)

    def __iter__(self):
        return self

    def __next__(self):
        line = self._map_obj.readline()
        if line:
            isLastRow = self._map_obj.tell () == self._map_obj.size ()
            return (self._parseLine(line), isLastRow)
        else:
            raise StopIteration

    def _parseLine(self, line):
        tick = line.split(b',')
        return {
            # Storing timestamp as float to preserve its precision.
            # 'timestamp': time.mktime(datetime.datetime.strptime(tick[0], '%Y.%m.%d %H:%M:%S.%f').replace(tzinfo=datetime.timezone.utc).timetuple()),
            'timestamp': string_to_timestamp(tick[0]).timestamp(),
             'bidPrice': float(tick[1]),
             'askPrice': float(tick[2]),
            'bidVolume': float(tick[3]),
            'askVolume': float(tick[4])               # float() handles ending '\n' character
        }

class Output:
    def __init__(self, timeframe, path_suffix, symbol, output_dir):
        self.deltaTimestamp = timeframe * 60
        self.endTimestamp = None
        self.barCount = 0

        self.filename = '%s%d%s' % (symbol, timeframe, path_suffix)
        self.fullname = os.path.join(output_dir, self.filename)

        try:
            os.remove(self.fullname)  # Remove existing output file before creating an appended new one
        except (OSError, IOError) as e:
            pass
        try:
            self.path = open(self.fullname, 'wb')
        except OSError as e:
            print("[ERROR] '%s' raised when tried to open for appending the file '%s'" % (e.strerror, e.filename))
            sys.exit(1)


    def __del__(self):
        self.path.close()

    def finalize(self):
        pass

    def _aggregate(self, tick):
        if not self.endTimestamp or tick['timestamp'] >= self.endTimestamp:
            uniBar = None
            if self.endTimestamp: uniBar = {
                'barTimestamp': self.startTimestamp,
               'tickTimestamp': tick['timestamp'],
                        'open': self.open,
                        'high': self.high,
                         'low': self.low,
                       'close': self.close,
                      'volume': self.volume
            }

            self.startTimestamp = (int(tick['timestamp']) // self.deltaTimestamp) * self.deltaTimestamp
            self.endTimestamp = self.startTimestamp + self.deltaTimestamp
            self.open = self.high = self.low = self.close = tick['bidPrice']
            self.volume = tick['bidVolume'] + tick['askVolume']

            if uniBar: return (uniBar, True)
        else:
            self.high = max(tick['bidPrice'], self.high)
            self.low  = min(tick['bidPrice'], self.low)
            self.close = tick['bidPrice']
            self.volume += tick['bidVolume'] + tick['askVolume']

        uniBar = {
            'barTimestamp': self.startTimestamp,
           'tickTimestamp': tick['timestamp'],
                    'open': self.open,
                    'high': self.high,
                     'low': self.low,
                   'close': self.close,
                  'volume': self.volume
        }
        return (uniBar, False)


    def _aggregateWithTicks(self, tick):
        if not self.endTimestamp or tick['timestamp'] >= self.endTimestamp:
            self.startTimestamp = (int(tick['timestamp']) // self.deltaTimestamp) * self.deltaTimestamp
            self.endTimestamp = self.startTimestamp + self.deltaTimestamp
            self.open = self.high = self.low = tick['bidPrice']
            self.volume = tick['bidVolume'] + tick['askVolume']
            self.barCount += 1
        else:
            self.high = max(tick['bidPrice'], self.high)
            self.low  = min(tick['bidPrice'], self.low)
            self.volume += tick['bidVolume'] + tick['askVolume']

        return {
            'barTimestamp': self.startTimestamp,
           'tickTimestamp': tick['timestamp'],
                    'open': self.open,
                    'high': self.high,
                     'low': self.low,
                   'close': tick['bidPrice'],
                  'volume': self.volume
        }


class HST509(Output):
    def __init__(self, path, path_suffix, output_dir, timeframe, symbol):
        # Initialize variables in parent constructor
        super().__init__(timeframe, path_suffix, symbol, output_dir)

        # Build header (148 Bytes in total)
        header = bytearray()
        header += pack('<i', 400)                                                    # Version
        header += bytearray('(C)opyright 2003, MetaQuotes Software Corp.'.ljust(64,  # Copyright
                            '\x00'),'latin1', 'ignore')
        header += bytearray(symbol.ljust(12, '\x00'), 'latin1', 'ignore')            # Symbol
        header += pack('<i', timeframe)                                              # Period
        header += pack('<i', 5)                                                      # Digits, using the default value of HST format
        header += pack('<i', int(time.time()))                                       # Time of sign (database creation)
        header += pack('<i', 0)                                                      # Time of last synchronization
        header += bytearray(13*4)                                                    # Space for future use

        self.path.write(header)

    def pack_ticks(self, tick):
        # Transform universal bar list to binary bar data (44 Bytes per bar)
        (uniBar, newUniBar) = self._aggregate(tick)
        if newUniBar:
            self.path.write(self._packUniBar(uniBar))

    def _packUniBar(self, uniBar):
        bar = bytearray()
        bar += pack('<i', uniBar['barTimestamp'])      # Time
        bar += pack('<d', uniBar['open'])              # Open
        bar += pack('<d', uniBar['low'])               # Low
        bar += pack('<d', uniBar['high'])              # High
        bar += pack('<d', uniBar['close'])             # Close
        bar += pack('<d', max(uniBar['volume'], 1.0))  # Volume

        return bar


class HST574(Output):
    def __init__(self, path, path_suffix, output_dir, timeframe, symbol):
        # Initialize variables in parent constructor
        super().__init__(timeframe, path_suffix, symbol, output_dir)

        # Build header (148 Bytes in total)
        header = bytearray()
        header += pack('<i', 401)                                                    # Version
        header += bytearray('(C)opyright 2003, MetaQuotes Software Corp.'.ljust(64,  # Copyright
                            '\x00'),'latin1', 'ignore')
        header += bytearray(symbol.ljust(12, '\x00'), 'latin1', 'ignore')            # Symbol
        header += pack('<i', timeframe)                                              # Period
        header += pack('<i', 5)                                                      # Digits, using the default value of HST format
        header += pack('<i', int(time.time()))                                       # Time of sign (database creation)
        header += pack('<i', 0)                                                      # Time of last synchronization
        header += bytearray(13*4)                                                    # Space for future use

        self.path.write(header)

    def pack_ticks(self, ticks):
        # Transform universal bar list to binary bar data (60 Bytes per bar)
        ticksAggregated  = {
            'barTimestamp':  ticks[0]['timestamp'],
            'tickTimestamp': ticks[0]['timestamp'],
            'open':          ticks[0]['bidPrice'],
            'low':           ticks[0]['bidPrice'],
            'high':          ticks[0]['bidPrice'],
            'close':         ticks[0]['bidPrice'],
            'volume':        0
        }

        for tick in ticks:
            ticksAggregated['low']     = min(ticksAggregated['low'],  tick['bidPrice'])
            ticksAggregated['high']    = max(ticksAggregated['high'], tick['bidPrice'])
            ticksAggregated['volume'] += tick['bidVolume'] + tick['askVolume']

        ticksAggregated['close'] = tick['bidPrice']

        self.path.write(self._packUniBar(ticksAggregated))

    def _packUniBar(self, uniBar):
        bar = bytearray()
        bar += pack('<i', uniBar['barTimestamp'])           # Time
        bar += bytearray(4)                                 # Add 4 bytes of padding.
        # OHLCV values.
        bar += pack('<d', uniBar['open'])                   # Open
        bar += pack('<d', uniBar['high'])                   # High
        bar += pack('<d', uniBar['low'])                    # Low
        bar += pack('<d', uniBar['close'])                  # Close
        bar += pack('<Q', max(int(uniBar['volume']), 1))    # Volume
        bar += pack('<i', 0)                                # Spread
        bar += pack('<Q', 0)                                # Real volume

        return bar

class FXT(Output):
    def __init__(self, path, path_suffix, output_dir, timeframe, symbol, server, spread, model):
        # Initialize variables in parent constructor
        super().__init__(timeframe, path_suffix, symbol, output_dir)

        self._priv = (timeframe, server, symbol, spread, model)
        self._firstUniBar = self._lastUniBar = None

        # Build header (728 Bytes in total).
        header = bytearray()
        header += pack('<I', 405)                                                       # FXT header version: 405
        header += bytearray('Copyright 2001-2015, MetaQuotes Software Corp.'.ljust(64,  # Copyright text.
                            '\x00'), 'latin1', 'ignore')
        header += bytearray(server.ljust(128, '\x00'), 'latin1', 'ignore')              # Account server name.
        header += bytearray(symbol.ljust(12, '\x00'), 'latin1', 'ignore')               # Symbol pair.
        header += pack('<I', timeframe)                                                 # Period of data aggregation in minutes (timeframe).
        header += pack('<I', model)                                                     # Model type: 0 - every tick, 1 - control points, 2 - bar open.
        header += pack('<I', 0)                                                         # Bars - amount of bars in history.
        header += pack('<I', 0)                                                         # Modelling start date - date of the first tick.
        header += pack('<I', 0)                                                         # Modelling end date - date of the last tick.
        header += bytearray(4)                                                          # Add 4 bytes of padding. This potentially can be totalTicks.
        header += pack('<d', 99.9)                                                      # Modeling quality (max. 99.9).
        # General parameters.
        header += bytearray('EUR'.ljust(12, '\x00'), 'latin1', 'ignore')                # Base currency (12 bytes).
        header += pack('<I', spread)                                                    # Spread in points.
        header += pack('<I', 5)                                                         # Digits, using the default value of FXT format.
        header += bytearray(4)                                                          # Add 4 bytes of padding.
        header += pack('<d', 1e-5)                                                      # Point size (e.g. 0.00001).
        header += pack('<I', 1)                                                         # Minimal lot size in centi lots (hundredths).
        header += pack('<I', 50000)                                                     # Maximal lot size in centi lots (hundredths).
        header += pack('<I', 1)                                                         # Lot step in centi lots (hundredths).
        header += pack('<I', 10)                                                        # Stops level value (orders stop distance in points).
        header += pack('<I', 1)                                                         # GTC (Good till cancel) - instruction to close pending orders at end of day (default: True).
        header += bytearray(4)                                                          # Add 4 bytes of padding.
        # Profit Calculation parameters.
        header += pack('<d', 100000.0)                                                  # ContractSize - contract size
        header += pack('<d', 0.0)                                                       # Tick value in quote currency (empty).
        header += pack('<d', 0.0)                                                       # Size of one tick (empty).
        header += pack('<I', 0)                                                         # Profit calculation mode: 0 - Forex, 1 - CFD, 2 - Futures.
        # Swap calculation
        header += pack('<i', 0)                                                         # Enable swap (default: False).
        header += pack('<I', 0)                                                         # Swap calculation method: 0 - in points, 1 - in the symbol base currency, 2 - by interest, 3 - in the margin currency.
        header += bytearray(4)                                                          # Add 4 bytes of padding.
        header += pack('<d', 0.0)                                                       # Swap of the buy order - long overnight swap value.
        header += pack('<d', 0.0)                                                       # Swap of the sell order - short overnight swap value.
        header += pack('<I', 3)                                                         # Day of week to charge 3 days swap rollover. Default: WEDNESDAY (3).
        # Margin calculation.
        header += pack('<I', 100)                                                       # Account leverage (default: 100).
        header += pack('<I', 1)                                                         # Free margin calculation mode {MARGIN_DONT_USE, MARGIN_USE_ALL, MARGIN_USE_PROFIT, MARGIN_USE_LOSS}
        header += pack('<I', 0)                                                         # Margin calculation mode: 0 - Forex, 1 - CFD, 2 - Futures, 3 - CFD for indexes.
        header += pack('<I', 30)                                                        # Margin stopout level (default: 30).
        header += pack('<I', 0)                                                         # Margin stop out check mode {MARGIN_TYPE_PERCENT, MARGIN_TYPE_CURRENCY}
        header += pack('<d', 0.0)                                                       # Margin requirements.
        header += pack('<d', 0.0)                                                       # Margin maintenance requirements.
        header += pack('<d', 50000.0)                                                   # Margin requirements for hedged positions.
        header += pack('<d', 1.25)                                                      # Margin divider used for leverage calculation.
        header += bytearray('USD'.ljust(12, '\x00'), 'latin1', 'ignore')                # Margin currency.
        header += bytearray(4)                                                          # Padding space - add 4 bytes to align the next double.
        # Commission calculation.
        header += pack('<d', 0.0)                                                       # Basic commission.
        header += pack('<i', 1)                                                         # Basic commission type {COMM_TYPE_MONEY, COMM_TYPE_PIPS, COMM_TYPE_PERCENT}.
        header += pack('<i', 0)                                                         # Commission per lot or per deal {COMMISSION_PER_LOT, COMMISSION_PER_DEAL}.
        # For internal use.
        header += pack('<I', 1)                                                         # Index of the first bar at which modeling started (0 for the first bar).
        header += pack('<I', 0)                                                         # Index of the last bar at which modeling started (0 for the last bar).
        header += pack('<I', 0)                                                         # Bar index where modeling started using M1 bars (0 for the first bar).
        header += pack('<I', 0)                                                         # Bar index where modeling started using M5 bars (0 for the first bar).
        header += pack('<I', 0)                                                         # Bar index where modeling started using M15 bars (0 for the first bar).
        header += pack('<I', 0)                                                         # Bar index where modeling started using M30 bars (0 for the first bar).
        header += pack('<I', 0)                                                         # Bar index where modeling started using H1 bars (0 for the first bar).
        header += pack('<I', 0)                                                         # Bar index where modeling started using H4 bars (0 for the first bar).
        header += pack('<I', 0)                                                         # Begin date from tester settings (must be zero).
        header += pack('<I', 0)                                                         # End date from tester settings (must be zero).
        header += pack('<I', 0)                                                         # Order's freeze level in points.
        header += pack('<I', 0)                                                         # Number of errors during model generation which needs to be fixed before testing.
        header += bytearray(60*4)                                                       # Reserved - Space for future use.

        self.path.write(header)

    def write_unibar(self, tick):
        # We're getting an array
        uniBar = {
            'barTimestamp': tick['barTimestamp'],
           'tickTimestamp': tick['timestamp'],
                    'open': tick['bidPrice'],
                    'high': tick['bidPrice'],
                     'low': tick['bidPrice'],
                   'close': tick['bidPrice'],
                  'volume': tick['bidVolume']
        }
        if not self._firstUniBar: self._firstUniBar = uniBar             # Store first and ...
        self._lastUniBar = uniBar                                        # ... last bar data for header.
        self.path.write(pack('<iiddddQii',
                int(uniBar['barTimestamp']),                                 # Bar datetime.
                0,                                                           # Add 4 bytes of padding.
                uniBar['open'],uniBar['high'],uniBar['low'],uniBar['close'], # OHLCV values.
                max(int(uniBar['volume']), 1),                               # Volume (documentation says it's a double, though it's stored as a long int).
                int(uniBar['tickTimestamp']),                                # The current time within a bar.
                4))                                                          # Flag to launch an expert (0 - bar will be modified, but the expert will not be launched).

    def pack_ticks(self, ticks):
        # Transform universal bar list to binary bar data (56 Bytes per bar)
        model = self._priv[4]

        # Every tick model
        if model == 0:
            for tick in ticks:
                self.write_unibar(tick)
        # Control points model
        elif model == 1:
            startTimestamp = None
            self.write_unibar(ticks[0])
            lowPrice = highPrice = ticks[0]['bidPrice']
            for tick in ticks[1:]:
                # Beginning of the M1 bar's timeline.
                tick['barTimestamp'] = int(tick['timestamp']) - int(tick['timestamp']) % 60

                if not startTimestamp:
                    startTimestamp = tick['barTimestamp']

                # Determines the end of the M1 bar.
                endTimestampTimeline  = startTimestamp + 60

                if tick['bidPrice'] < lowPrice:
                    lowPrice = tick['bidPrice']
                    self.write_unibar(tick)
                elif tick['bidPrice'] > highPrice:
                    highPrice = tick['bidPrice']
                    self.write_unibar(tick)
                elif tick['timestamp'] >= endTimestampTimeline:
                    startTimestamp   = tick['barTimestamp']
                    self.write_unibar(tick)
        # Open price model
        elif model == 2:
            self.write_unibar(ticks[0])

    def finalize(self):
        # Fixup the header.
        self.path.seek(216)
        fix  = bytearray()
        fix += pack('<III',
                self.barCount,
                int(self._firstUniBar['barTimestamp']),                    # Modelling start date - date of the first tick.
                int(self._lastUniBar['barTimestamp']))                     # Modelling end date - date of the last tick.
        self.path.write(fix)

        self.path.seek(472)
        fix  = bytearray()
        fix += pack('<II',
                int(self._firstUniBar['barTimestamp']),                    # Tester start date - date of the first tick.
                int(self._lastUniBar['barTimestamp']))                     # Tester end date - date of the last tick.
        self.path.write(fix)


class HCC(Output):
    """Output ticks in HCC file format."""

    def __init__(self, path_suffix, output_dir, timeframe, symbol):
        """Create file and write headers."""

        super().__init__(timeframe, path_suffix, symbol, output_dir)

        # Build header (228 Bytes in total)
        header = bytearray()
        header += pack('<I', 501)                                                      # Magic
        header += bytearray('Copyright 2001-2016, MetaQuotes Software Corp.'.ljust(64, # Copyright
                            '\x00'),'utf-16', 'ignore')[2:]
        header += bytearray('History'.ljust(16, '\x00'), 'utf-16', 'ignore')[2:]       # Name
        header += bytearray('EURUSD'.ljust(32, '\x00'), 'utf-16', 'ignore')[2:]        # Title
        assert 228 == self.path.write(header)

        # Build EMPTY table (18 Bytes in total)
        table = bytearray()
        table += pack('<i', 0) # unknown_0
        table += pack('<i', 0) # unknown_1
        table += pack('<h', 0) # unknown_2
        table += pack('<i', 0) # size
        table += pack('<i', 0) # off

        # write main table (18 Bytes in total)
        assert 18 == self.path.write(table)
        self.table_end = self.path.tell()
        # write an empty table record to indicate that there are no more tables
        assert 18 == self.path.write(table)

        # Build record header (189 Bytes in total)
        record_header = bytearray()
        record_header += pack('<H',0x81)                                               # magic
        record_header += bytearray('LABEL'.ljust(32, '\x00'), 'utf-16', 'ignore')[2:]  # label
        record_header += bytearray('UN0'.ljust(9, '\x00'), 'utf-16', 'ignore')[2:]     # unknown_0
        record_header += pack('<I', 0)                                                 # rows
        record_header += bytearray('UN1'.ljust(50, '\x00'), 'utf-16', 'ignore')[2:]    # unknown_1
        record_header += pack('<c', b'0')
        self.record_header_begin = self.path.tell()
        assert 189 == self.path.write(record_header)
        self.record_header_end = self.path.tell()

    def pack_ticks(self, ticks):
        """Prepare and write ticks in file."""

        self.count_ticks = len(ticks)

        # Transform universal bar list to binary bar data (40 Bytes per bar)
        for tick in ticks:
            # We're getting an array
            uniBar = {
                'barTimestamp': tick['barTimestamp'],
               'tickTimestamp': tick['timestamp'],
                        'open': tick['bidPrice'],
                        'high': tick['bidPrice'],
                         'low': tick['bidPrice'],
                       'close': tick['bidPrice'],
                      'volume': tick['bidVolume']
            }

            self.path.write(pack('<iidddd',
                    0x00088884,                                                   # Separator
                    int(uniBar['barTimestamp']),                                  # Bar datetime.
                    uniBar['open'],uniBar['high'],uniBar['low'],uniBar['close'])) # Values.

    def finalize(self):
        """Write data count in headers."""

        # fixup the table
        fix = pack('<i', self.record_header_begin)
        self.path.seek(self.table_end-4)
        self.path.write(fix)

        # fixup the record header
        fix = pack('<I', self.count_ticks)
        self.path.seek(self.record_header_end-101-4)
        self.path.write(fix)


def config_argparser():
    argumentParser = argparse.ArgumentParser(add_help=False)
    argumentParser.add_argument('-i', '--input-file',
        action='store',      dest='inputFile', help='input file', default=None, required=True)
    argumentParser.add_argument('-f', '--output-format',
        action='store',      dest='outputFormat', help='format of output file (FXT/HST/Old HST/HCC), as: fxt4/hst4/hst4_509/hcc', default='fxt4')
    argumentParser.add_argument('-s', '--symbol',
        action='store',      dest='symbol', help='symbol code (maximum 12 characters)', default='EURUSD')
    argumentParser.add_argument('-t', '--timeframe',
        action='store',      dest='timeframe', help='one of the timeframe values: M1, M5, M15, M30, H1, H4, D1, W1, MN', default='M1')
    argumentParser.add_argument('-p', '--spread',
        action='store',      dest='spread', help='spread value in points', default=20)
    argumentParser.add_argument('-d', '--output-dir',
        action='store',      dest='outputDir', help='destination directory to save the output file', default='.')
    argumentParser.add_argument('-S', '--server',
        action='store',      dest='server', help='name of FX server', default='default')
    argumentParser.add_argument('-v', '--verbose',
        action='store_true', dest='verbose', help='increase output verbosity')
    argumentParser.add_argument('-m', '--model',
        action='store',      dest='model', help='one of the model values: 0, 1, 2', default='0')
    argumentParser.add_argument('-h', '--help',
        action='help', help='Show this help message and exit')

    return argumentParser


def construct_queue(timeframe_list):
    """Select the apropriate classes and begin the work."""

    for timeframe in timeframe_list:
        if multiple_timeframes:
            print('[INFO] Queueing the {}m timeframe for conversion'.format(timeframe))
        # Checking output file format argument and doing conversion
        if outputFormat == 'hst4_509':
            yield HST509(None, '.hst', args.outputDir, timeframe, symbol)
        elif outputFormat == 'hst4':
            yield HST574(None, '.hst', args.outputDir, timeframe, symbol)
        elif outputFormat == 'fxt4':
            for m in args.model.split(','):
                yield FXT(None, '_{0}.fxt'.format(m), args.outputDir, timeframe, symbol, server, spread, int(m))
        elif outputFormat == 'hcc':
            yield HCC('.hcc', args.outputDir, timeframe, symbol)
        else:
            print('[ERROR] Unknown output file format!')
            sys.exit(1)


def process_queue(queue):
    """Process the queue, process all the timeframes at the same time to amortize the cost of the parsing."""

    queue = list(queue)

    try:
        for obj in queue:

            ticks = CSV(args.inputFile);

            startTimestamp = None

            # We will retrieve all ticks in the timeframe into following array and update their LowBid/HighBid
            ticksToJoin      = [];
            ticksToAggregate = [];

            for (tick, isLastRow) in ticks:
                # Beginning of the bar's timeline.
                tick['barTimestamp'] = int(tick['timestamp']) - int(tick['timestamp']) % obj.deltaTimestamp

                # Tick's timestamp will be rounded to 1 for M1 and 60 for other.
                tick['timestamp'] = int(tick['timestamp']) #- int(tick['timestamp']) % (1 if obj.deltaTimestamp == 60 else 60)

                if not startTimestamp:
                    startTimestamp = tick['barTimestamp']

                # Tick after this time won't be used for LowBid/HighBid aggregation.
                endTimestampAggregate = startTimestamp + 60

                # Determines the end of the current bar.
                endTimestampTimeline  = startTimestamp + obj.deltaTimestamp

                if tick['timestamp'] < endTimestampTimeline:
                    # Tick is within the current bar's timeline, queuing for
                    # aggregation.
                    ticksToAggregate.append(tick)
                else:
                    # Tick is beyond current bar's timeline, aggregating unaggregated
                    # ticks:
                    if len(ticksToAggregate) > 0:
                        obj.pack_ticks(ticksToAggregate)

                    # Next bar's timeline will begin from this new tick's bar
                    # timestamp.
                    startTimestamp   = tick['barTimestamp']

                    # Tick beyond delta timeframe will be aggregated in the next
                    # timeframe
                    ticksToAggregate = [tick]

                spinner.spin()

            # Writting the last tick if not yet written.
            if len(ticksToAggregate) > 0:
                obj.pack_ticks(ticksToAggregate)

        if args.verbose:
            print('[INFO] Finalizing...')
        for obj in queue:
            obj.finalize()
        if args.verbose:
            print('[INFO] Done.')
    except KeyboardInterrupt as e:
        print('\n[INFO] Exiting by user request...')
        sys.exit()


if __name__ == '__main__':
    # Parse the arguments
    arg_parser = config_argparser()
    args = arg_parser.parse_args()

    # Checking input file argument
    if args.verbose:
        print('[INFO] Input file: %s' % args.inputFile)

    # Checking symbol argument
    if len(args.symbol) > 12:
        print('[WARNING] Symbol is more than 12 characters, cutting its end off!')
        symbol = args.symbol[0:12]
    else:
        symbol = args.symbol
    if args.verbose:
        print('[INFO] Symbol name: %s' % symbol)

    # Converting timeframe argument to minutes
    timeframe_list = []



    timeframe_conv = {
        'M': 1,
        'H': 60,
        'D': 24 * 60,
        'W': 7 * 24 * 60,
        'MN': 30 * 24 * 60
    }

    for arg in args.timeframe.lower().split(','):
        match_obj = re.match(r'(M|H|D|W|MN)(\d+)', arg, re.I)
        if match_obj:
            model = match_obj.group(1).upper()
            value = int(match_obj.group(2))

            timeframe_list.append(
                timeframe_conv[model] * value
            )
        else:
            print('[ERROR] Bad timeframe setting \'{}\'!'.format(arg))
            sys.exit(1)

    if args.verbose:
        print('[INFO] Timeframe: %s - %s minute(s)' % (args.timeframe.upper(), timeframe_list))

    # Checking spread argument
    spread = int(args.spread)
    if args.verbose:
        print('[INFO] Spread: %d' % spread)

    # Create output directory
    os.makedirs(args.outputDir, 0o755, True)
    if args.verbose:
        print('[INFO] Output directory: %s' % args.outputDir)

    # Checking server argument
    if len(args.server) > 128:
        print('[WARNING] Server name is longer than 128 characters, cutting its end off!')
        server = args.server[0:128]
    else:
        server = args.server
    if args.verbose:
        print('[INFO] Server name: %s' % server)

    outputFormat = args.outputFormat.lower()
    if args.verbose:
        print('[INFO] Output format: %s' % outputFormat)

    multiple_timeframes = len(timeframe_list) > 1

    queue = construct_queue(timeframe_list)
    process_queue(queue)
