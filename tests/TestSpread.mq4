int OnInit() {
    int symbol_spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
    int real_spread = MathRound((Ask - Bid) * MathPow(10, Digits));
    Print("Testing spread...");
    PrintFormat("Reported spread: %d points", symbol_spread);
    PrintFormat("Real spread    : %d points", real_spread);
    PrintFormat("Ask/Bid: %.5f/%.5f", Ask, Bid);
    if (real_spread > 0 && symbol_spread == real_spread) {
        Print("Success!");
    } else {
        ExpertRemove();
    }
}
