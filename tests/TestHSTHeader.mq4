//+------------------------------------------------------------------+
//| Test adequacy of HST file.
//| Documentation on the format can be found in terminal Help
//| (Client terminal - Auto Trading - Strategy Testing - History Files)
//+------------------------------------------------------------------+

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
#define INVALID_FILE_ATTRIBUTES     -1
#define FORMAT_MESSAGE_FROM_SYSTEM  0x00001000
//---
#define OPEN_EXISTING               3
//--- Header version
#define HST_VERSION                 401
//+------------------------------------------------------------------+
//|   HistoryHeader                                                  |
//+------------------------------------------------------------------+
struct HistoryHeader
  {
   int               version; // database version
   char              copyright[64]; // copyright info
   char              symbol[12]; // symbol name
   int               period; // symbol timeframe
   int               digits; // the amount of digits after decimal point in the symbol
   int               timesign; // timesign of the database creation
   int               last_sync; // the last synchronization time
   int               unused[13]; // to be used in future
  };
//+------------------------------------------------------------------+
//|   Import                                                         |
//+------------------------------------------------------------------+
#import "kernel32.dll"
int CreateFileW(string name,uint desiredAccess,int SharedMode,int security,int creation,int flags,int templateFile);
int SetFilePointer(int fileHandle,int lDistanceToMove,int &lpDistanceToMoveHigh,int dwMoveMethod);
bool ReadFile(int fileHandle,HistoryHeader &buffer,int bytes,int &numOfBytes,int overlapped);
bool ReadFile(int fileHandle,MqlRates &buffer[],int bytes,int &numOfBytes,int overlapped);
int GetFileSize(int hFile,int &lpFileSizeHigh);
int CloseHandle(int FileHandle);
int GetLastError(void);
void SetLastError(int dwErrCode);
int GetFileAttributesW(string lpFileName);
int FormatMessageW(uint dwFlags,int lpSource,uint dwMessageId,uint dwLanguageId,short &lpBuffer[],uint nSize,int Arguments);
#import
//+------------------------------------------------------------------+
//|   OnInit                                                         |
//+------------------------------------------------------------------+
int OnInit()
  {

   kernel32::SetLastError(0);

//--- DLL calls must be allowed
   if(!MQLInfoInteger(MQL_DLLS_ALLOWED))
     {
      Print("DLL call is not allowed. The Expert cannot run.");
      return(INIT_FAILED);
     }

//--- Build file path
   string path=StringFormat("%s\\history\\default\\%s%d.hst",TerminalInfoString(TERMINAL_PATH),_Symbol,_Period);
   printf("File Path=%s",path);

//--- open file for reading
   int fileHandle=CreateFileW(path,GENERIC_READ,FILE_SHARE_READ_|FILE_SHARE_WRITE_,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0);
   if(fileHandle==INVALID_HANDLE)
     {
      printf("Invalid file handle, Error: %s ",GetErrorDescription(kernel32::GetLastError()));
      return(INIT_FAILED);
     }

//--- Check file size
   int size_high;
   int size_low=kernel32::GetFileSize(fileHandle,size_high);
   if(size_low==INVALID_FILE_SIZE){ Print("Error: Invalid get file size."); return(false); }

//---
   long file_size=((long)size_high<<32)+size_low;
   if(file_size<sizeof(HistoryHeader)+sizeof(MqlRates) ||
      fmod(file_size-sizeof(HistoryHeader),sizeof(MqlRates))!=0.0)
     {
      CloseHandle(fileHandle);
      Print("Error: Wrong file size.");
      return(false);
     }

//--- check content
   int ExtBars=0;
   datetime ExtLastTime=0;
   if(HstCheckHeader(fileHandle) &&
      HstCheckBars(fileHandle,ExtBars))
     {
      CloseHandle(fileHandle);
      Print("Success: HST header is correct!");
      return(INIT_SUCCEEDED);
     }
   else
     {
      CloseHandle(fileHandle);
      Print("Error: Invalid HST format.");
      return(INIT_FAILED);
     }
  }
//+------------------------------------------------------------------+
//|   ReadAndCheckHeader                                             |
//+------------------------------------------------------------------+
bool HstCheckHeader(const int handle)
  {

//--- file seek
   kernel32::SetLastError(0);
   int distance=0;
   if(kernel32::SetFilePointer(handle,0,distance,0)==INVALID_SET_FILE_POINTER)
     {
      PrintFormat("Failed to seek on file handle (%d), Error: %s",handle,GetErrorDescription(kernel32::GetLastError()));
      return(FALSE);
     }

//--- read header
   HistoryHeader header;
   ZeroMemory(header);
   int numOfBytes=0;
   if(!kernel32::ReadFile(handle,header,sizeof(header),numOfBytes,0))
     {
      PrintFormat("Failed to read, Error: %s",GetErrorDescription(kernel32::GetLastError()));
      return(FALSE);
     }

//--- check version
   if(header.version!=HST_VERSION) { PrintFormat("Error: HST Version (%d != %d) FILE HST Version.",HST_VERSION,header.version); return(false); }
//--- check symbol
   if(CharArrayToString(header.symbol)!=_Symbol) { Print("Error: Wrong Symbol."); return(false); }
//--- check period
   if(header.period!=_Period) { Print("Error: Wrong period."); return(false); }
//--- check digits
   if(header.digits!=_Digits) { Print("Error: Wrong digits."); return(false); }
//---
   return(true);
  }
//+------------------------------------------------------------------+
//|   HstCheckBars                                                   |
//+------------------------------------------------------------------+
bool HstCheckBars(const int handle,int &ExtBars)
  {
   ExtBars=0;
//---
   int distance=0;
   if(kernel32::SetFilePointer(handle,sizeof(HistoryHeader),distance,0)==INVALID_SET_FILE_POINTER)
     {
      printf("Failed to seek on file handle (%d), Error: %s",handle,GetErrorDescription(kernel32::GetLastError()));
      return(false);
     }

//---
#define BARS_COUNT 5000
//---
   int errors=0;
   int bars_count=0;
   while(!_StopFlag)
     {
      MqlRates bar[BARS_COUNT];
      ZeroMemory(bar);
      int num_of_bars=0;

      if(!ReadFile(handle,bar,sizeof(MqlRates)*BARS_COUNT,num_of_bars,0))
         break;

      if(num_of_bars==0 || fmod(num_of_bars,sizeof(MqlRates)!=0))
         break;

      //---
      int total=num_of_bars/sizeof(MqlRates);
      for(int i=0;i<total;i++)
        {
         //--- check time
         if(bar[i].time>TimeCurrent())
           {
            printf("Invalid time %s. Should be less than current time %s",TimeToString(bar[i].time),TimeToString(TimeCurrent()));
            errors++;
           }

         //--- check Low
         if(bar[i].low>bar[i].open ||
            bar[i].low>bar[i].close ||
            bar[i].low>bar[i].high)
           {
            printf("Invalid low price %s. Should be less than open %s, close %s, high %s",
                   DoubleToString(bar[i].low,_Digits),
                   DoubleToString(bar[i].open,_Digits),
                   DoubleToString(bar[i].close,_Digits),
                   DoubleToString(bar[i].high,_Digits));
            errors++;
           }

         //--- check High
         if(bar[i].high<bar[i].open ||
            bar[i].high<bar[i].close ||
            bar[i].high<bar[i].low)
           {
            printf("Invalid high price %s. Should be less than open %s, close %s, low %s",
                   DoubleToString(bar[i].high,_Digits),
                   DoubleToString(bar[i].open,_Digits),
                   DoubleToString(bar[i].close,_Digits),
                   DoubleToString(bar[i].low,_Digits));
            errors++;
           }

         ExtBars++;
        }

     }
   if(errors>0)
      return(false);
//---
   return(true);
  }
//+------------------------------------------------------------------+
//|   GetErrorDescription                                            |
//+------------------------------------------------------------------+
string GetErrorDescription(const int error)
  {
//--- WinInet Error
   if(error>=12000 && error<13000)
     {
      return("Internet error " + IntegerToString(error));
     }
   short msg[256];
   ZeroMemory(msg);
   FormatMessageW(FORMAT_MESSAGE_FROM_SYSTEM,0,error,1024,msg,256,0);
   return(ShortArrayToString(msg));
  }
//+------------------------------------------------------------------+
