//+------------------------------------------------------------------+
//|                                                   TestMargin.mq4 |
//|                       Copyright 2016-2019, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Test adequacy of user free margin value.
//+------------------------------------------------------------------+

#property strict
int OnInit() {
    Print("Testing MODE_MARGINREQUIRED...");
    // Free margin required to open 1 lot for buying.
    double market_marginrequired = MarketInfo(_Symbol, MODE_MARGINREQUIRED);
    if (market_marginrequired > 0) {
        PrintFormat("Free margin is valid: %g", market_marginrequired);
        return INIT_SUCCEEDED;
    } else {
        PrintFormat("Error: Invalid MODE_MARGINREQUIRED: %g", market_marginrequired);
        return INIT_FAILED;
    }
}
