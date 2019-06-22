from .bstruct import *

#
# Structure definitions
#
class TicksRaw(BStruct):
    _endianness = '<'
    _fields = [
            ('symbol', '12s', pretty_print_string),
            ('time', 'I', pretty_print_time),
            ('bid', 'd'),
            ('ask', 'd'),
            ('counter', 'I'),
            ('unknown', 'I'),
            ]
    _size = get_fields_size(_fields)
    assert(_size == 40)

class SymbolSel(BStruct):
    _endianness = '<'
    _fields = [
            ('symbol', '12s', pretty_print_string),
            ('digits', 'I'),
            ('index', 'I'),
            ('unknown_1', 'I'),
            ('group', 'I'),
            ('unknown_2', 'I'),
            ('pointSize', 'd'),
            ('spread', 'I'),
            ('unknown_3', 'I'),
            ('tickType', 'I'),
            ('unknown_4', 'H'),
            ('unknown_5', 'H'),
            ('time', 'I', pretty_print_time),
            ('unknown_6', 'I'),
            ('bid', 'd'),
            ('ask', 'd'),
            ('sessionHigh', 'd'),
            ('sessionLow', 'd'),
            ('unknown_17', '16s', pretty_print_compact),
            ('bid_2', 'd'),
            ('ask_2', 'd')
            ]
    _size = get_fields_size(_fields)
    assert(_size == 128)

class Symgroups(BStruct):
    _endianness = '<'
    _fields = [
            ('name', '16s', pretty_print_string),
            ('description', '60s', pretty_print_string),
            ('backgroundColor', 'I')
            ]
    _size = get_fields_size(_fields)
    assert(_size == 80)

class SymbolsRaw(BStruct):
    _endianness = '<'
    _fields = [
            ('name', '12s', pretty_print_string),           # Symbol name.
            ('description', '65s', pretty_print_string),    # Symbol description.
            ('altName', '11s', pretty_print_string),        # Alternative name, e.g. "AUDCAD" (if not equal 'name')
            ('baseCurrency', '12s', pretty_print_string),   # Base currency.
            ('group', 'I'),                                 # Index of group in "symgroups.raw".
            ('digits', 'I'),                                # Number of digits after decimal point for the current symbol prices.
            ('tradeMode', 'I'),                             # Trade mode: 0 = No, 1 = CloseOnly, 2 = Full.
            ('backgroundColor', 'I', pretty_print_hex),     # Color in "Market Watch" window.
            ('id', 'I'),                                    # Unique symbol id.
            ('unknown_1', '1508c', pretty_print_ignore),    # ???: Some colors (use pretty_print_compact instead to print).
            ('unknown_2', 'I'),                             # ???: E.g. 8, 10, 12, 14, 20, 24, 25, 30, 40, 50, 60, 100, 10000.
            ('unknown_3', 'I'),                             # ???: 1 - Gold, _NQ100, 2 - Currencies, 3 - #IBM, #HPQ, etc.
            ('padding_1', '4s', pretty_print_compact),      # Padding space - add 4 bytes to align to the next double.
            ('unknown_4', 'd'),                             # ???: E.g. 0.0, 0.1, 0.01, 0.005.
            ('unknown_5', '12s', pretty_print_compact),     # ???: Empty.
            ('spread', 'I'),                                # Spread in points, 0 for current online spread (variable).
            ('unknown_6', 'I'),                             # ???: Always 0.
            ('unknown_7', 'I'),                             # ???: Always 1.
            ('unknown_8', 'I'),                             # ???: Always 1.
            ('profitCalcMode', 'I'),                        # ???: Profit calculation mode. 0 - Forex; 1 - CFD; 2 - Futures.
            ('swapLong', 'd'),                              # Swap of the buy order.
            ('swapShort', 'd'),                             # Swap of the sell order.
            ('3daysSwap', 'I'),                             # Day of week to charge 3 days swap rollover.
            ('padding_2', '4s', pretty_print_compact),      # Padding space - add 4 bytes to align to the next double.
            ('contractSize', 'd'),                          # Trade contract size (lot size in units).
            ('unknown_9', '16s', pretty_print_compact),     # ???: Empty.
            ('stopsLevel', 'I'),                            # Minimal indention in points from the current close price to place Stop orders.
            ('unknown_10', 'I'),                            # ???: Disabled for #HPQ, #IBM, etc.
            ('unknown_11', 'I'),                            # ???: 0 - Currencies, 1 - Futures.
            ('padding_3', '4s', pretty_print_compact),      # Padding space - add 4 bytes to align to the next double.
            ('marginInit', 'd'),                            # Margin init (0 = contractSize).
            ('marginMaintenance', 'd'),                     # Margin maintenance
            ('marginHedged', 'd'),                          # Margin hedged
            ('marginDivider', 'd'),                         # leverage calculation: 0...5 - relative to account leverage, > 10  - absolute custom leverage.
            ('pointSize', 'd'),                             # Point size in the quote currency.
            ('pointsPerUnit', 'd'),                         # Points per unit.
            ('unknown_12', '24s', pretty_print_compact),    # ???: Reserved.
            ('marginCurrency', '12s', pretty_print_string), # Margin currency.
            ('unknown_13', 'I'),                            # ???: Always 0.
            ('unknown_14', 'I'),                            # ???: Always 1 for currencies.
            ('unknown_15', '96s', pretty_print_compact),    # ???: Reserved.
            ('unknown_16', 'I'),                            # ???: E.g. 0, 3, 4, 6, 7, 8, 9, 10, 12, 200.
            ]
    _size = get_fields_size(_fields)
    assert(_size == 1936)

class FxtHeader(BStruct):
    _endianness = '<'
    _fields = [
            # Build header
            ('headerVersion', 'I'),
            ('copyright', '64s', pretty_print_string),
            ('server', '128s', pretty_print_string),
            ('symbol', '12s', pretty_print_string),
            ('timeframe', 'i'),
            ('modelType', 'i'),
            ('totalBars', 'I'),
            ('modelStart', 'I', pretty_print_time),
            ('modelEnd', 'I', pretty_print_time),
            ('padding1', '4s', pretty_print_ignore),

            # General parameters
            ('modelQuality', 'd'),
            ('baseCurrency', '12s', pretty_print_string),
            ('spread', 'I'),
            ('digits', 'I'),
            ('padding2', '4s', pretty_print_ignore),
            ('pointSize', 'd'),
            ('minLotSize', 'i'),
            ('maxLotSize', 'i'),
            ('lotStep', 'i'),
            ('stopLevel', 'i'),
            ('GTC', 'i'),
            ('padding3', '4s', pretty_print_ignore),

            # Profit Calculation parameters
            ('contractSize', 'd'),
            ('tickValue', 'd'),
            ('tickSize', 'd'),
            ('profitMode', 'i'),
            ('swapEnabled', 'i'),
            ('swapMethod', 'i'),
            ('padding4', '4s', pretty_print_ignore),
            ('swapLong', 'd'),
            ('swapShort', 'd'),
            ('swapRollover', 'i'),

            # Margin calculation
            ('accountLeverage', 'i'), # Default: 100
            ('freeMarginMode', 'i'),
            ('marginCalcMode', 'i'),
            ('marginStopoutLevel', 'i'),
            ('marginStopoutMode', 'i'),
            ('marginRequirements', 'd'),
            ('marginMaintenanceReq', 'd'),
            ('marginHedgedPosReq', 'd'),
            ('marginLeverageDivider', 'd'),
            ('marginCurrency', '12s', pretty_print_string),
            ('padding5', '4s', pretty_print_ignore),

            # Commission calculation
            ('commission', 'd'),
            ('commissionType', 'i'),
            ('commissionPerEntry', 'i'),

            # For internal use
            ('indexOfFirstBar', 'i'),
            ('indexOfLastBar', 'i'),
            ('indexOfM1Bar', 'i'),
            ('indexOfM5Bar', 'i'),
            ('indexOfM15Bar', 'i'),
            ('indexOfM30Bar', 'i'),
            ('indexOfH1Bar', 'i'),
            ('indexOfH4Bar', 'i'),
            ('beginDate', 'I', pretty_print_time),
            ('endDate', 'I', pretty_print_time),
            ('freezeLevel', 'i'),
            ('numberOfErrors', 'I'),
            ('reserved', '240s', pretty_print_ignore),
            ]
    _size = get_fields_size(_fields)
    assert(_size == 728)

class HccHeader(BStruct):
    _endianness = '<'
    _fields = [
            ('magic', 'I'),
            ('copyright', '128s', pretty_print_wstring),
            ('name', '32s', pretty_print_wstring),
            ('title', '64s', pretty_print_wstring)
            ]
    _size = get_fields_size(_fields)
    assert(_size == 228)

class HccTable(BStruct):
    _endianness = '<'
    _fields = [
            ('unknown_0', 'I'),
            ('unknown_1', 'I', pretty_print_time),
            ('unknown_2', 'H'),
            ('size', 'I'),
            ('off',  'I', pretty_print_hex),
            ]
    _size = get_fields_size(_fields)
    assert(_size == 18)

class HccRecordHeader(BStruct):
    _endianness = '<'
    _fields = [
            ('magic', 'H'),
            ('label', '64s', pretty_print_wstring),
            ('unknown_0', '18s', pretty_print_ignore),
            ('rows', 'I'),
            ('unknown_1', '101s', pretty_print_ignore),
            ]
    _size = get_fields_size(_fields)
    assert(_size == 189)

class HccRecord(BStruct):
    _endianness = '<'
    _fields = [
            ('separator', 'I', pretty_print_ignore),
            ('time', 'I', pretty_print_time),
            ('open', 'd'),
            ('high', 'd'),
            ('low', 'd'),
            ('close', 'd'),
            ]
    _size = get_fields_size(_fields)
    assert(_size == 40)

class SrvHeader(BStruct):
    _endianness = '<'
    _fields = [
            ('serverName', '64s', pretty_print_string),
            ('companyName', '128s', pretty_print_string),
            ('unknown_0', '24s', pretty_print_bstring),
            ('serverAddress', '64s', pretty_print_string),
            ('unknown_1', '72s', pretty_print_bstring),
            ]
    _size = get_fields_size(_fields)
    assert(_size == 352)

class SrvRecord(BStruct):
    _endianness = '<'
    _fields = [
            ('unknown_0', '40s', pretty_print_bstring),
            ('unknown_1', '40s', pretty_print_bstring),
            ('unknown_2', '40s', pretty_print_bstring),
            ('unknown_3', '40s', pretty_print_bstring),
            ]
    _size = get_fields_size(_fields)
    assert(_size == 160)
