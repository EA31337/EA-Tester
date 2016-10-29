//+------------------------------------------------------------------+
//| Test adequacy of HST file.
//| Documentation on the format can be found in terminal Help
//| (Client terminal - Auto Trading - Strategy Testing - History Files)
//+------------------------------------------------------------------+

//---- Imports.
#property show_inputs
#import "kernel32.dll"
 int _lopen(string patg,int of);
 int _lcreat(string path,int attrib);
 int _llseek(int handle,int offset,int origin);
 int _lread(int handle,int& buffer[],int bytes);
 int _lwrite(int handle,string buffer,int bytes);
 int _lclose(int handle);
#import

//---- Header version.
#define HST_VERSION 405

struct HistoryHeader
{
  int version; // database version
  char copyright[64]; // copyright info
  char symbol[12]; // symbol name
  int period; // symbol timeframe
  int digits; // the amount of digits after decimal point in the symbol
  time_t timesign; // timesign of the database creation
  time_t last_sync; // the last synchronization time
  int unused[13]; // to be used in future
};

// then goes the bars array (single-byte justification)
#pragma pack(push,1)
//---- standard representation of the quote in the database struct RateInfo
{
  time_t ctm; // current time in seconds double open;
  double low;
  double high;
  double close;
  double vol;
};
#pragma pack(pop)

//+------------------------------------------------------------------+
//| Read and check HST header.
//+------------------------------------------------------------------+
int ReadDigits(int handle) {
/*
    int buffer[2];
    int adjustCursor1 = _llseek(handle, 0xfc, 0); // 16
    int ret_read1 = _lread(handle, buffer, 8);
    Print("digits = ", buffer[1]);
*/
}

int OnInit() {
    // string HST_="USDJPYFXF5_0.hst"; // @todo: Find the file name automatically?
    string path = TerminalPath() + "\\tester\\history\\" + HST_;
    Print("win32api_File_Path= ", path);
    int fileHandle = _lopen(path, 0);
    if (ReadAndCheckHeader(fileHandle, period, bars)) {
        Print("HST header is correct!");
    } else {
        int ret_close=_lclose(fileHandle);
        ExpertRemove();
    }
    int ret_close=_lclose(fileHandle);
}
