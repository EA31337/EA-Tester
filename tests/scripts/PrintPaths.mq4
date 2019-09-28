//+------------------------------------------------------------------+
//|                                                   PrintPaths.mq4 |
//|                       Copyright 2016-2019, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Script to print terminal paths.
//+------------------------------------------------------------------+

#property strict

//+------------------------------------------------------------------+
//| Script init function                                             |
//+------------------------------------------------------------------+
int OnInit() {
  Print("Initializing...");
  Print("Terminal path       : ", TerminalInfoString(TERMINAL_PATH));
  Print("Terminal data path  : ", TerminalInfoString(TERMINAL_DATA_PATH));
  Print("Terminal common path: ", TerminalInfoString(TERMINAL_COMMONDATA_PATH));
  return INIT_SUCCEEDED;
}
