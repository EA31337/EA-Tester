//+------------------------------------------------------------------+
//| Test MT4 structure SYMBOL_GROUP (file format "symgroups.raw").
//+------------------------------------------------------------------+

/**
 * The file contains always 32 groups and has a fixed size: 32 x sizeof(SYMBOL_GROUP) =  2560 bytes.
 * Empty groups are undefined and can appear anywhere in the file.
 */
/*
struct SYMBOL_GROUP {                              // -- offset ---- size --- description ----------------------------------------------------------------------------
   char name       [16];                           //         0        16     group name        (szchar)
   char description[60];                           //        16        60     group description (szchar); not visible in MetaTrader
   UINT backgroundColor;                           //        76         4     group color in "Market Watch" window, may be overwritten by SYMBOL.color
}; 
*/

int OnInit() {
    // @todo Find symgroups.raw file.
    // @todo Check the values based on struct.
    /*
    if (CheckFormat()) {
        Print("Success!");
    } else {
        ExpertRemove();
    }
    */
  return (INIT_FAILED);
}
