//+------------------------------------------------------------------+
//|                                                   TestMargin.mq4 |
//|                            Copyright 2016, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Test adequacy of user free margin value.
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
