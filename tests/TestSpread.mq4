//+------------------------------------------------------------------+
//| Test whether spread is non-zero. Fail on spread zero.
//+------------------------------------------------------------------+
#property strict
int OnInit() {
    long symbol_spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
    int real_spread = (int)MathRound((Ask - Bid) * MathPow(10, Digits));
    Print("Testing spread...");
    PrintFormat("Reported spread: %d points", symbol_spread);
    PrintFormat("Real spread    : %d points", real_spread);
    PrintFormat("Ask/Bid        : %g/%g", NormalizeDouble(Ask, Digits), NormalizeDouble(Bid, Digits));
    PrintFormat("Symbol digits  : %g", Digits);
    if (real_spread > 0 && symbol_spread == real_spread) {
        Print("Spread is correct.");
        return INIT_SUCCEEDED;
    } else {
        Print("Error: Spread is not correct!");
        return INIT_FAILED;
    }
}
