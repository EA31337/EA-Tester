//+------------------------------------------------------------------+
//|                                                   TestSpread.mq4 |
//|                       Copyright 2016-2019, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Test whether spread is non-zero. Fail on spread zero.
//+------------------------------------------------------------------+

/*
 *  This file is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.

 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

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
