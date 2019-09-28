//+------------------------------------------------------------------+
//|                                                   TestSpread.mq4 |
//|                       Copyright 2016-2019, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Test whether spread is non-zero. Fail on spread zero.
//+------------------------------------------------------------------+

#property strict

int OnInit() {
    long symbol_spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
    int real_spread = (int)MathRound((Ask - Bid) * MathPow(10, Digits));
    double lot_step = MarketInfo(_Symbol, MODE_LOTSTEP);
    Print("Testing spread...");
    PrintFormat("Reported spread: %d points", symbol_spread);
    PrintFormat("Real spread    : %d points", real_spread);
    PrintFormat("Ask/Bid        : %g/%g", NormalizeDouble(Ask, Digits), NormalizeDouble(Bid, Digits));
    PrintFormat("Symbol digits  : %g", Digits);
    PrintFormat("Lot step       : %g", lot_step);
    if (real_spread > 0 && symbol_spread == real_spread) {
        Print("Spread is valid.");
        return INIT_SUCCEEDED;
    } else {
        Print("Error: Spread is not correct!");
        return INIT_FAILED;
    }
}
