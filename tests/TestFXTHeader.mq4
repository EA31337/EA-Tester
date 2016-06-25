//+------------------------------------------------------------------+
//|                                                TestFXTHeader.mq4 |
//|                                      Copyright 2012, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Test adequacy of FXT file.
//| Documentation on the format can be found in terminal Help
//| (Client terminal - Auto Trading - Strategy Testing - History Files)
//+------------------------------------------------------------------+

//#property show_inputs
//+------------------------------------------------------------------+
//|   Defines                                                        |
//+------------------------------------------------------------------+
#define GENERIC_READ                0x80000000
#define GENERIC_WRITE               0x40000000
#define FILE_SHARE_READ_            0x00000001
#define FILE_SHARE_WRITE_           0x00000002
#define FILE_ATTRIBUTE_NORMAL       0x80
#define INVALID_SET_FILE_POINTER    -1
#define INVALID_FILE_SIZE           -1
//---
#define CREATE_NEW                  1
#define CREATE_ALWAYS               2
#define OPEN_EXISTING               3
#define OPEN_ALWAYS                 4

//--- Header version.
#define FXT_VERSION                 405

//--- Profit calculation mode.
#define PROFIT_CALC_FOREX 0 // Default.
#define PROFIT_CALC_CFD 1
#define PROFIT_CALC_FUTURES 2

//--- Type of swap.
#define SWAP_BY_POINTS 0 // Default.
#define SWAP_BY_BASECURRENCY     1
#define SWAP_BY_INTEREST         2
#define SWAP_BY_MARGINCURRENCY   3

//--- Free margin calculation mode.
#define MARGIN_DONT_USE 0
#define MARGIN_USE_ALL 1 // Default.
#define MARGIN_USE_PROFIT 2
#define MARGIN_USE_LOSS 3

//--- Margin calculation mode.
#define MARGIN_CALC_FOREX 0 // Default.
#define MARGIN_CALC_CFD 1
#define MARGIN_CALC_FUTURES 2
#define MARGIN_CALC_CFDINDEX 3

//--- Basic commission type.
#define COMM_TYPE_MONEY 0
#define COMM_TYPE_PIPS 1
#define COMM_TYPE_PERCENT 2
//--- Commission per lot or per deal.
#define COMMISSION_PER_LOT 0
#define COMMISSION_PER_DEAL 1
//--- FXT file header
struct TestHistoryHeader
  {
   int               version;            // Header version: 405
   char              copyright[64];      // Copyright/description.
   char              description[128];   // Account server name.
                                         // 196
   char              symbol[12];         // Symbol pair.
   int               period;             // Period of data aggregation in minutes (timeframe).
   int               model;              // Model type: 0 - every tick, 1 - control points, 2 - bar open.
   int               bars;               // Bars - number of modeled bars in history.
   int               fromdate;           // Modelling start date - date of the first tick.
   int               todate;             // Modelling end date - date of the last tick.
   int               totalTicks;         // Total ticks. Add 4 bytes to align to the next double?
   double            modelquality;       // Modeling quality (max. 99.9).
                                         // 240
   //---- Market symbol properties.
   char              currency[12];       // Base currency (12 bytes). Same as: StringLeft(symbol, 3)
   int               spread;             // Spread in points. Same as: MarketInfo(MODE_SPREAD)
   int               digits;             // Digits (default: 5). Same as: MarketInfo(MODE_DIGITS)
   int               padding1;           // Padding space - add 4 bytes to align to the next double.
   double            point;              // Point size (e.g. 0.0000'1). Same as: MarketInfo(MODE_POINT)
   int               lot_min;            // Minimal lot size in centi lots (hundredths). Same as: MarketInfo(MODE_MINLOT)*100
   int               lot_max;            // Maximal lot size in centi lots (hundredths). Same as: MarketInfo(MODE_MAXLOT) *100
   int               lot_step;           // Lot step in centi lots (hundredths). Same as: MarketInfo(MODE_LOTSTEP)*100
   int               stops_level;        // Stops level value (orders stop distance in points). Same as: MarketInfo(MODE_STOPLEVEL)
   int               gtc_pendings;       // GTC (Good till cancel) - instruction to close pending orders at end of day (default: False).
   int               padding2;           // Padding space - add 4 bytes to align to the next double.
                                         // 296
   //---- Profit calculation parameters.
   double            contract_size;      // Contract size (e.g. 100000). Same as: MarketInfo(MODE_LOTSIZE)
   double            tick_value;         // Tick value in quote currency (empty). Same as: MarketInfo(MODE_TICKVALUE)
   double            tick_size;          // Size of one tick (empty). Same as: MarketInfo(MODE_TICKSIZE)
   int               profit_mode;        // Profit calculation mode { PROFIT_CALC_FOREX=0, PROFIT_CALC_CFD=1, PROFIT_CALC_FUTURES=2 }. Same as: MarketInfo(MODE_PROFITCALCMODE)
                                         // 324
   //---- Swap calculation.
   int               swap_enable;        // Enable swaps (default: True).
   int               swap_type;          // Type of swap { SWAP_BY_POINTS=0, SWAP_BY_BASECURRENCY=1, SWAP_BY_INTEREST=2, SWAP_BY_MARGINCURRENCY=3 }. Same as: MarketInfo(MODE_SWAPTYPE)
   int               padding3;           // Padding space - add 4 bytes to align to the next double.
   double            swap_long;          // Swap of the buy order - long overnight swap value. Same as: MarketInfo(MODE_SWAPLONG)
   double            swap_short;         // Swap of the sell order - short overnight swap value. Same as: MarketInfo(MODE_SWAPSHORT)
   int               swap_rollover3days; // Day of week to charge 3 days swap rollover. Default: WEDNESDAY (3). Same as: MarketInfo(SYMBOL_SWAP_ROLLOVER3DAYS)
                                         // 356
   //---- Margin calculation.
   int               leverage;           // Account leverage (default: 100). Same as: AccountLeverage()
   int               free_margin_mode;   // Free margin calculation mode { MARGIN_DONT_USE=0, MARGIN_USE_ALL=1, MARGIN_USE_PROFIT=2, MARGIN_USE_LOSS=3 }. Same as: AccountFreeMarginMode()
   int               margin_mode;        // Margin calculation mode { MARGIN_CALC_FOREX=0, MARGIN_CALC_CFD=1, MARGIN_CALC_FUTURES=2, MARGIN_CALC_CFDINDEX=3 }. Same as: MarketInfo(MODE_MARGINCALCMODE)
   int               margin_stopout;     // Margin Stop Out level (default: 30). Same as: AccountStopoutLevel()

   int               margin_stopout_mode;// Check mode for Stop Out level { MARGIN_TYPE_PERCENT=0, MARGIN_TYPE_CURRENCY=1 }. Same as: AccountStopoutMode()
   double            margin_initial;     // Initial margin requirement (in units). Same as: MarketInfo(MODE_MARGININIT)
   double            margin_maintenance; // Maintenance margin requirement (in units). Same as: MarketInfo(MODE_MARGINMAINTENANCE)
   double            margin_hedged;      // Hedged margin requirement for positions (in units). Same as: MarketInfo(MODE_MARGINHEDGED)
   double            margin_divider;     // Margin divider used for leverage calculation.
   char              margin_currency[12];// Margin currency. Same as: AccountCurrency().
   int               padding4;           // Padding space - add 4 bytes to align to the next double.
                                         // 424
   //--- Commission calculation.
   double            comm_base;          // Basic commission rate.
   int               comm_type;          // Basic commission type          { COMM_TYPE_MONEY=0, COMM_TYPE_PIPS=1, COMM_TYPE_PERCENT=2 }.
   int               comm_lots;          // Commission per lot or per deal { COMMISSION_PER_LOT=0, COMMISSION_PER_DEAL=1 }
                                         // 440
   //--- For internal use.
   int               from_bar;           // Index of the first bar at which modeling started (0 for the first bar).
   int               to_bar;             // Index of the last bar at which modeling started (0 for the last bar).
   int               start_period_m1;    // Bar index where modeling started using M1 bars (0 for the first bar).
   int               start_period_m5;    // Bar index where modeling started using M5 bars (0 for the first bar).
   int               start_period_m15;   // Bar index where modeling started using M15 bars (0 for the first bar).
   int               start_period_m30;   // Bar index where modeling started using M30 bars (0 for the first bar).
   int               start_period_h1;    // Bar index where modeling started using H1 bars (0 for the first bar).
   int               start_period_h4;    // Bar index where modeling started using H4 bars (0 for the first bar).
   int               set_from;           // Begin date from tester settings (must be zero).
   int               set_to;             // End date from tester settings (must be zero).
   //---
   int               freeze_level;       // Order freeze level in points. Same as: MarketInfo(MODE_FREEZELEVEL)
   int               generating_errors;  // Number of errors during model generation which needs to be fixed before testing.
   //---
   int               reserved[60];       // Reserved - space for future use.
  };
//+------------------------------------------------------------------+
//|   TestHistory                                                    |
//+------------------------------------------------------------------+
struct TestHistory
  {
   datetime          otm;                // Bar datetime.
   double            open;               // OHLCV values.
   double            high;
   double            low;
   double            close;
   long              volume;
   int               ctm;                // The current time within a bar.
   int               flag;               // Flag to launch an expert (0 - bar will be modified, but the expert will not be launched).
  };
//+------------------------------------------------------------------+
//|   Import                                                         |
//+------------------------------------------------------------------+
#import "kernel32.dll"
int CreateFileW(string name,uint desiredAccess,int SharedMode,int security,int creation,int flags,int templateFile);
int SetFilePointer(int fileHandle,int lDistanceToMove,int &lpDistanceToMoveHigh,int dwMoveMethod);
bool ReadFile(int fileHandle,TestHistoryHeader &buffer,int bytes,int &numOfBytes,int overlapped);
bool ReadFile(int fileHandle,TestHistory &buffer[],int bytes,int &numOfBytes,int overlapped);
int GetFileSize(int hFile,int &lpFileSizeHigh);
int CloseHandle(int FileHandle);
int GetLastError(void);
void SetLastError(int dwErrCode);
#import
//+------------------------------------------------------------------+
//|   OnInit                                                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   kernel32::SetLastError(0);
//---
   if(!MQLInfoInteger(MQL_DLLS_ALLOWED))
     {
      Print("DLL call is not allowed. Experts cannot run.");
      return(INIT_FAILED);
     }
//---
   string path=StringFormat("%s\\tester\\history\\%s%d_0.fxt",TerminalInfoString(TERMINAL_PATH),_Symbol,_Period);
   Print("File Path=",path);

//---
   int fileHandle=CreateFileW(path,GENERIC_READ,FILE_SHARE_READ_|FILE_SHARE_WRITE_,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0);
   if(fileHandle==INVALID_HANDLE)
     {
      Print("Invalid file handle, error ",kernel32::GetLastError());
      return(INIT_FAILED);
     }

//---
   int ExtBars=0;
   datetime ExtLastTime=0;
   if(ReadAndCheckHeader(fileHandle,_Period,ExtBars) &&
      CheckWrittenBars(fileHandle,ExtBars,ExtLastTime))
     {
      CloseHandle(fileHandle);
      Print("Success: FXT header is correct!");
      return(INIT_SUCCEEDED);
     }
   else
     {
      CloseHandle(fileHandle);
      Print("Error: Invalid FXT format.");
      return(INIT_FAILED);
     }
  }
//+------------------------------------------------------------------+
//|   ReadAndCheckHeader                                             |
//+------------------------------------------------------------------+
bool ReadAndCheckHeader(const int handle,const int _period,int &bars)
  {
   bars=0;
//---
   kernel32::SetLastError(0);
   int distance=0;
   if(kernel32::SetFilePointer(handle,0,distance,0)==INVALID_SET_FILE_POINTER)
     {
      PrintFormat("Failed to seek on file handle (%d), Error code = %d",handle,kernel32::GetLastError());
      return(FALSE);
     }
//---
   TestHistoryHeader header;
   ZeroMemory(header);
   int numOfBytes=0;
   if(!kernel32::ReadFile(handle,header,sizeof(header),numOfBytes,0))
     {
      PrintFormat("Failed to read, Error code = %d",kernel32::GetLastError());
      return(FALSE);
     }

//--- check version
   if(header.version!=FXT_VERSION){PrintFormat("Error: FXT Version (%i != %i) FILE FXT Version.",FXT_VERSION,header.version); return(false); }
//---
   if(CharArrayToString(header.symbol)!=_Symbol){ Print("Error: Wrong Symbol."); return(false);}
//---
   if(header.period!=_period) { Print("Error: Wrong period."); return(false);}
//--- Every tick model.
   if(header.model!=0) { Print("Error: Wrong tick model."); return(false); }
//--- Bars.
   if(header.bars<=0){Print("Error: Wrong numbers of bars."); return(false); }
   bars=header.bars;
//---
   if(header.modelquality<0.0 || header.modelquality>100.0){ Print("Error: Wrong number model quality."); return(false);}
//--- Currency.
   if(CharArrayToString(header.currency)!=StringSubstr(_Symbol,0,3)) { Print("Error: Wrong currency."); return(false); }
//--- Spread digits and point.
   if(header.spread<0) { Print("Error: Wrong spread."); return(false); }
//---
   if(header.digits!=_Digits) { Print("Error: Wrong spread."); return(false); }
//---
   if(header.point!=_Point) { Print("Error: Wrong spread."); return(false); }
//--- Lot min.
   if(header.lot_min<0.0) { Print("Error: Wrong lot min."); return(false); }
//--- Lot max.
   if(header.lot_max<0.0) { Print("Error: Wrong lot max."); return(false); }
//--- Lot step.
   if(header.lot_step<0.0) { Print("Error: Wrong lot step."); return(false); }
//---- Stops level.
   if(header.stops_level<0.0) { Print("Error: Wrong stops level."); return(false); }
//---- Contract size.
   if(header.contract_size<0.0) { Print("Error: Wrong contract size."); return(false); }
//---- Profit mode.
   if(header.profit_mode<0 || header.profit_mode>PROFIT_CALC_FUTURES) { Print("Error: Wrong profit mode."); return(false); }
//---- Triple rollovers.
   if(header.swap_rollover3days<0 || header.swap_rollover3days>6) { Print("Error: Wrong triple rollovers."); return(false); }
//---- Leverage.
   if(header.leverage<=0 || header.leverage>500) { Print("Error: Wrong leverage."); return(false); }
//---- Check for stored bars.
   int size_high;
   int size_low=kernel32::GetFileSize(handle,size_high);
   if(size_low==INVALID_FILE_SIZE){ Print("Error: Invalid file size."); return(false); }
//---
   long file_size=((long)size_high<<32)+size_low;
   long need_size=(long)sizeof(TestHistoryHeader)+(long)fmax(0,header.bars-1)*sizeof(TestHistory);
   if(file_size<need_size)
     {
      Print("Error: Wrong stored bars. File size: ",file_size,", need size: ",need_size); return(false);
     }
//----
   return (true);
  }
//+------------------------------------------------------------------+
//|   CheckWrittenBars                                               |
//+------------------------------------------------------------------+
bool CheckWrittenBars(const int handle,const int _bars,datetime &last_time)
  {
//---
   last_time=0;

   int distance=0;
   if(kernel32::SetFilePointer(handle,sizeof(TestHistoryHeader),distance,0)==INVALID_SET_FILE_POINTER)
     {
      PrintFormat("Failed to seek on file handle (%d), Error code = %d",handle,kernel32::GetLastError());
      return(false);
     }
//---
#define BARS_COUNT 5000
//---
   int bars_count=0;
   while(!_StopFlag)
     {
      TestHistory bar[BARS_COUNT];
      ZeroMemory(bar);
      int num_of_bars=0;

      if(!ReadFile(handle,bar,sizeof(TestHistory)*BARS_COUNT,num_of_bars,0))
         break;

      if(num_of_bars==0 || fmod(num_of_bars,sizeof(TestHistory)!=0))
         break;

      //---
      int total=num_of_bars/sizeof(TestHistory);
      for(int i=0;i<total;i++)
        {
         if(last_time!=bar[i].otm)
           {
            last_time=bar[i].otm;
            bars_count++;
           }
        }
     }

//---
   if(_bars>bars_count+1) // if(_bars!=bars_count+1) ?
     {
      Print("Wrong bars count ",bars_count+1," in the FXT-header. Should be ",_bars);
      return(false);
     }

//---
   return(true);
  }

//+------------------------------------------------------------------+
