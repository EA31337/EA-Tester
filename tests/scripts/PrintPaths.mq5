//+------------------------------------------------------------------+
//|                                                   PrintPaths.mq4 |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Script to print terminal paths.
//+------------------------------------------------------------------+

/**
 * Implements "Init" event handler function.
 */
int OnInit() {
  Print("Initializing...");
  Print("Terminal path       : ", TerminalInfoString(TERMINAL_PATH));
  Print("Terminal data path  : ", TerminalInfoString(TERMINAL_DATA_PATH));
  Print("Terminal common path: ", TerminalInfoString(TERMINAL_COMMONDATA_PATH));
  return INIT_SUCCEEDED;
}
