//+------------------------------------------------------------------+
//|                                                  TestLotstep.mq4 |
//|                       Copyright 2016-2019, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Test whether lot step is correct.
//| Notes:
//| - Lot step for 5 digit precision most likely to be 0.01
//| - Lot step for 4 digit precision most likely to be 0.1
//+------------------------------------------------------------------+

#property strict

int OnInit() {
    long symbol_spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
    int real_spread = (int)MathRound((Ask - Bid) * MathPow(10, Digits));
    double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP); // Same as: MarketInfo(symbol, MODE_LOTSTEP);
    Print("Testing lot step...");
    PrintFormat("Symbol digits  : %g", Digits);
    PrintFormat("Lot step       : %g", lot_step);
    switch (Digits) {
        case 4:
            if (lot_step != 0.1) {
                PrintFormat("Error: Expected lot step for %d digits: 0.1, found: %g", Digits, lot_step);
                return INIT_FAILED;
            }
            break;
        case 5:
            if (lot_step != 0.01) {
                PrintFormat("Error: Expected lot step for %d digits: 0.01, found: %g", Digits, lot_step);
                return INIT_FAILED;
            }
            break;
    }
    Print("Lot step is valid.");
    return INIT_SUCCEEDED;
}
