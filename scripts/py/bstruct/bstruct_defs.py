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
    _truncate = True
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
            ('pointSize', 'd', pretty_print_decimal_p5),
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
    _truncate = True
    _size = get_fields_size(_fields)
    assert(_size == 128)

class Symgroups(BStruct):
    _endianness = '<'
    _fields = [
            ('name', '16s', pretty_print_string),
            ('description', '60s', pretty_print_string),
            ('backgroundColor', 'I')
            ]
    _truncate = True
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
            ('marginDivider', 'd'),                         # Leverage calculation: 0...5 - relative to account leverage, > 10  - absolute custom leverage.
            ('pointSize', 'd', pretty_print_decimal_p5),    # Point size in the quote currency.
            ('pointsPerUnit', 'd'),                         # Points per unit.
            ('unknown_12', '24s', pretty_print_compact),    # ???: Reserved.
            ('marginCurrency', '12s', pretty_print_string), # Margin currency.
            ('unknown_13', 'I'),                            # ???: Always 0.
            ('unknown_14', 'I'),                            # ???: Always 1 for currencies.
            ('unknown_15', '96s', pretty_print_compact),    # ???: Reserved.
            ('unknown_16', 'I'),                            # ???: E.g. 0, 3, 4, 6, 7, 8, 9, 10, 12, 200.
            ]
    _truncate = True
    _size = get_fields_size(_fields)
    assert(_size == 1936)

# FXT Header format
# @see: https://www.metatrader4.com/en/trading-platform/help/autotrading/tester/tester_fxt
#
# Documentation on the format can be found in terminal Help (Client terminal - Auto Trading - Strategy Testing - History Files FXT).
# However the obtained data shows that the data does not match the declared format.
# In the eye catches the fact that the work is carried out over time in both formats: the new and the old MQL4.
# So, members of fromdate and todate structure TestHistoryHeader , and ctm structure TestHistory use the old (4 hbaytny) date / time format, but a member of otm structure TestHistory written in the new (8-byte) date / time format.
# It is unclear whether the correct type of selected members unknown.
# The FXT as teak prices recorded only Bid, but its spread is written in the Volume field.
# By breaking MT4 is obtained to ensure that the MT4-tester figured on each tick Ask, how the Bid + the Volume (that's the trick).
# Source: https://forum.mql4.com/ru/64199/page3
#
class FxtHeader(BStruct):
    _endianness = '<'
    _fields = [
        # Header layout.
        ('headerVersion', 'I'),                       # Version      uint32      0   4 Header version (default: 405).
        ('copyright', '64s', pretty_print_string),    # Description  [64]byte    4  64 Copyright/description (szchar).
        ('server', '128s', pretty_print_string),      # ServerName   [128]byte  68 128 Account server name (szchar).
        ('symbol', '12s', pretty_print_string),       # Symbol       [12]byte  196  12 Symbol (szchar).
        ('timeframe', 'i'),                           # Period       uint32    208   4 Timeframe in minutes.
        ('modelType', 'i'),                           # ModelType    uint32    212   4 0=EveryTick|1=ControlPoints|2=BarOpen
        ('totalBars', 'I'),                           # ModeledBars  uint32    216   4 Number of modeled bars      (w/o prolog)
        ('firstBarTime', 'I', pretty_print_time),     # FirstBarTime uint32    220   4 Bar open time of first tick (w/o prolog)
        ('lastBarTime', 'I', pretty_print_time),      # LastBarTime  uint32    224   4 Bar open time of last tick  (w/o prolog)
        ('padding1', '4s', pretty_print_ignore),      # _            [4]byte   228   4 (alignment to the next double)

        # Common parameters.
        ('modelQuality', 'd'),                        # ModelQuality float64   232   8 Max. 99.9
        ('baseCurrency', '12s', pretty_print_string), # BaseCurrency [12]byte  240  12 Base currency (szchar) = StringLeft(symbol, 3)
        ('spread', 'I'),                              # Spread       uint32    252   4 Spread in points: 0=zero spread = MarketInfo(MODE_SPREAD)
        ('digits', 'I'),                              # Digits       uint32    256   4 Symbol digits = MarketInfo(MODE_DIGITS)
        ('padding2', '4s', pretty_print_ignore),      # _            [4]byte   260   4 (alignment to the next double)
        ('pointSize', 'd', pretty_print_decimal_p5),  # PointSize    float64   264   8 Resolution, ie. 0.0000'1 = MarketInfo(MODE_POINT)
        ('minLotSize', 'i'),                          # MinLotsize   uint32    272   4 Min lot size in centi lots (hundredths) = MarketInfo(MODE_MINLOT)  * 100
        ('maxLotSize', 'i'),                          # MaxLotsize   uint32    276   4 Max lot size in centi lots (hundredths) = MarketInfo(MODE_MAXLOT)  * 100
        ('lotStep', 'i'),                             # LotStepsize  uint32    280   4 Lot stepsize in centi lots (hundredths) = MarketInfo(MODE_LOTSTEP) * 100
        ('stopLevel', 'i'),                           # StopsLevel   uint32    284   4 Orders stop distance in points          = MarketInfo(MODE_STOPLEVEL)
        ('pendingGTC', 'i'),                          # PendingsGTC  uint32    288   4 Close pending orders at end of day or GTC
        ('padding3', '4s', pretty_print_ignore),      # _            [4]byte   292   4 (alignment to the next double)

        # Profit Calculation parameters.
        ('contractSize', 'd'),                        # ContractSize          float64   296   8 ie. 100000 = MarketInfo(MODE_LOTSIZE)
        ('tickValue', 'd'),                           # TickValue             float64   304   8 tick value in quote currency (empty) = MarketInfo(MODE_TICKVALUE)
        ('tickSize', 'd'),                            # TickSize              float64   312   8 tick size (empty) = MarketInfo(MODE_TICKSIZE)
        ('profitCalcMode', 'i'),                      # ProfitCalculationMode uint32    320   4 0=Forex|1=CFD|2=Futures = MarketInfo(MODE_PROFITCALCMODE)

        # Swap calculation parameters.
        ('swapEnabled', 'i'),                         # SwapEnabled         uint32  324   4 if swaps are to be applied
        ('swapCalcMode', 'i'),                        # SwapCalculationMode int32   328   4 0=Points|1=BaseCurrency|2=Interest|3=MarginCurrency = MarketInfo(MODE_SWAPTYPE)
        ('padding4', '4s', pretty_print_ignore),      # _                   [4]byte 332   4 (alignment to the next double)
        ('swapLong', 'd'),                            # SwapLongValue       float64 336   8 long overnight swap value   = MarketInfo(MODE_SWAPLONG)
        ('swapShort', 'd'),                           # SwapShortValue      float64 344   8 short overnight swap values = MarketInfo(MODE_SWAPSHORT)
        ('swapRollover', 'i'),                        # TripleRolloverDay   uint32  352   4 weekday of triple swaps     = WEDNESDAY (3)

        # Margin calculation parameters.
        ('accountLeverage', 'i'),                       # AccountLeverage           uint32   356    4 Account leverage = AccountLeverage(); (default: 100)
        ('freeMarginMode', 'i'),                        # FreeMarginCalculationType uint32   360    4 Free margin calculation type = AccountFreeMarginMode()
        ('marginCalcMode', 'i'),                        # MarginCalculationMode     uint32   364    4 Margin calculation mode = MarketInfo(MODE_MARGINCALCMODE)
        ('marginStopoutLevel', 'i'),                    # MarginStopoutLevel        uint32   368    4 Margin stopout level                       = AccountStopoutLevel()
        ('marginStopoutMode', 'i'),                     # MarginStopoutType         uint32   372    4 Margin stopout type                        = AccountStopoutMode()
        ('marginRequirements', 'd'),                    # MarginInit                float64  376    8 Initial margin requirement (in units)      = MarketInfo(MODE_MARGININIT)
        ('marginMaintenanceReq', 'd'),                  # MarginMaintenance         float64  384    8 Maintainance margin requirement (in units) = MarketInfo(MODE_MARGINMAINTENANCE)
        ('marginHedgedPosReq', 'd'),                    # MarginHedged              float64  392    8 Hedged margin requirement (in units)       = MarketInfo(MODE_MARGINHEDGED)
        ('marginLeverageDivider', 'd'),                 # MarginDivider             float64  400    8 Leverage calculation                         @see example in struct SYMBOL
        ('marginCurrency', '12s', pretty_print_string), # MarginCurrency            [12]byte 408   12                                            = AccountCurrency()
        ('padding5', '4s', pretty_print_ignore),        # _                         [4]byte  420    4 (alignment to the next double)

        # Commission calculation parameters.
        ('commissionValue', 'd'),                     # CommissionValue           float64 424   8 commission rate
        ('commissionCalcMode', 'i'),                  # CommissionCalculationMode int32   432   4 0=Money|1=Pips|2=Percent @see COMMISSION_MODE_*
        ('commissionType', 'i'),                      # CommissionType            int32   436   4 0=RoundTurn|1=PerDeal    @see COMMISSION_TYPE_*

        # Later additions.
        ('indexOfFirstBar', 'i'),                     # FirstBar          uint32    440   4  Bar number/index??? of first bar (w/o prolog) or 0 for first bar.
        ('indexOfLastBar', 'i'),                      # LastBar           uint32    444   4  Bar number/index??? of last bar (w/o prolog) or 0 for last bar.
        ('indexOfM1Bar', 'i'),                        # StartPeriodM1     uint32    448   4  Bar index where modeling started using M1 bars.
        ('indexOfM5Bar', 'i'),                        # StartPeriodM5     uint32    452   4  Bar index where modeling started using M5 bars.
        ('indexOfM15Bar', 'i'),                       # StartPeriodM15    uint32    456   4  Bar index where modeling started using M15 bars.
        ('indexOfM30Bar', 'i'),                       # StartPeriodM30    uint32    460   4  Bar index where modeling started using M30 bars.
        ('indexOfH1Bar', 'i'),                        # StartPeriodH1     uint32    464   4  Bar index where modeling started using H1 bars.
        ('indexOfH4Bar', 'i'),                        # StartPeriodH4     uint32    468   4  Bar index where modeling started using H4 bars.
        ('testBeginDate', 'I', pretty_print_time),    # TesterSettingFrom uint32    472   4  Begin date from tester settings.
        ('testEndDate', 'I', pretty_print_time),      # TesterSettingTo   uint32    476   4  End date from tester settings.
        ('freezeLevel', 'i'),                         # FreezeDistance    uint32    480   4  Order freeze level in points = MarketInfo(MODE_FREEZELEVEL).
        ('numberOfErrors', 'I'),                      # ModelErrors       uint32    484   4  Number of errors during model generation (fix errors showing up here before testing).
        ('reserved', '240s', pretty_print_ignore),    # _                 [240]byte 488 240  Unused.
        ]
    _truncate = False
    _size = get_fields_size(_fields)
    assert(_size == 728)

# FXT Tick data.
# The array of modeled bars.
# @see: https://www.metatrader4.com/en/trading-platform/help/autotrading/tester/tester_fxt
#
class FxtTick(BStruct):
    _endianness = '<'
    _fields = [
        ('barTimestamp', 'II', pretty_print_time), # BarTimestamp  uint64  0   8 Bar datetime, align with timeframe, unit seconds.
        ('open', 'd'),                             # Open          float64 8   8
        ('high', 'd'),                             # High          float64 16  8
        ('low', 'd'),                              # Low           float64 24  8
        ('close', 'd'),                            # Close         float64 32  8
        ('volume', 'II'),                          # Volume        uint64  40  8 Volume (documentation says it's a double, though it's stored as a long int).
        ('tickTimestamp', 'i', pretty_print_time), # TickTimestamp uint32  48  4 Tick data timestamp in seconds (the current time within a bar).
        ('launchExpert', 'i', pretty_print_time),  # LaunchExpert  uint32  52  4 Flag to launch an expert (0 - bar will be modified, but the expert will not be launched).
        ]
    _truncate = True
    _size = get_fields_size(_fields)
    assert(_size == 56)

class HccHeader(BStruct):
    _endianness = '<'
    _fields = [
            ('magic', 'I'),
            ('copyright', '128s', pretty_print_wstring),
            ('name', '32s', pretty_print_wstring),
            ('title', '64s', pretty_print_wstring)
            ]
    _truncate = False
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
    _truncate = True
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
    _truncate = True
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
    _truncate = True
    assert(_size == 40)

# Header structure for HST version 401.
class HstHeader(BStruct):
    _endianness = '<'
    _fields = [
        # Build header
        ('headerVersion', 'I'),                     # Version   uint32     //   0    4 HST version (default 401).
        ('copyright', '64s', pretty_print_string),  # Copyright [64]byte   //   4   64 Copyright info.
        ('symbol', '12s', pretty_print_string),     # Symbol    [12]byte   //  68   12 Forex symbol.
        ('timeframe', 'i'),                         # Period    uint32     //  80    4 Symbol timeframe.
        ('digits', 'I'),                            # Digits    uint32     //  84    4 The amount of digits after decimal point in the symbol.
        ('timeSign', 'I', pretty_print_time),       # TimeSign  uint32     //  88    4 Time of sign (database creation).
        ('lastSync', 'I', pretty_print_time),       # LastSync  uint32     //  92    4 Time of last synchronization.
        ('unused', '13s', pretty_print_bstring),    # _         [13]uint32 //  96   52 Unused.
        ]
    _size = get_fields_size(_fields)
    _truncate = False
    assert(_size == 109)

# HST bar data.
# @see: https://www.metatrader4.com/en/trading-platform/help/autotrading/tester/tester_fxt
class HstBar(BStruct):
    _endianness = '<'
    _fields = [
        ('barTimestamp', 'II', pretty_print_time), # CTM           uint64  0   8 Current time in seconds aligned with timeframe (MQL4 datetime).
        ('open', 'd'),                             # Open          float64 8   8
        ('high', 'd'),                             # High          float64 16  8
        ('low', 'd'),                              # Low           float64 24  8
        ('close', 'd'),                            # Close         float64 32  8
        ('volume', 'II'),                          # Volume        uint64  40  8 Volume (documentation says it's a double, though it's stored as a long int).
        ('spread', 'I'),                           # Spread        uint32  48  8 Spread in points, 0 for current online spread (variable).
        ('realVolume', 'II'),                      # Real volume   uint64  52  8
        ]
    _size = get_fields_size(_fields)
    _truncate = True
    assert(_size == 60)

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
    _truncate = False
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
    _truncate = True
    assert(_size == 160)
