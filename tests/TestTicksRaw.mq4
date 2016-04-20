//+------------------------------------------------------------------+
//| Test MT4 structure TICK (file format "ticks.raw").
//+------------------------------------------------------------------+

struct TICK {                                      // -- offset ---- size --- description ------------
   char   symbol[MAX_SYMBOL_LENGTH+1];             //         0        12     symbol (szchar)
   UINT   time;                                    //        12         4     timestamp
   double bid;                                     //        16         8     bid
   double ask;                                     //        24         8     ask
   UINT   counter;                                 //        32         4     consecutive tick counter
   BYTE   unknown[4];                              //        36         4     ?
};                                                 // ------------------------------------------------
                                                   //                = 40
int OnInit() {
    // @todo Find ticks.raw file.
    // @todo Check the values based on struct.
    /*
    if (CheckFormat()) {
        Print("Success!");
    } else {
        ExpertRemove();
    }
    */
}
