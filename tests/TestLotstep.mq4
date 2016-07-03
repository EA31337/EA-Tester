//+------------------------------------------------------------------+
//|                                                  TestLotstep.mq4 |
//|                            Copyright 2016, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Test whether lot step is correct.
//| Notes:
//| Lot step for 5 digit precision most likely to be 0.01
//| Lot step for 4 digit precision most likely to be 0.1
//+------------------------------------------------------------------+

/*
    This file is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#property strict
int OnInit() {
    long symbol_spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
    int real_spread = (int)MathRound((Ask - Bid) * MathPow(10, Digits));
    double lot_step = MarketInfo(_Symbol, MODE_LOTSTEP);
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
