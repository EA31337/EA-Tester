//+------------------------------------------------------------------+
//|                                               TestTimeframes.mq4 |
//|                       Copyright 2016-2019, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Test whether timeframes are active.
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
  bool init = INIT_SUCCEEDED;

  if (!iMA(_Symbol, PERIOD_M1, 13, 8, MODE_SMMA, PRICE_MEDIAN, 0) > 0) {
    Alert("Timeframe M1 is not active!");
    init = INIT_FAILED;
  }
  if (!iMA(_Symbol, PERIOD_M5, 13, 8, MODE_SMMA, PRICE_MEDIAN, 0) > 0) {
    Alert("Timeframe M5 is not active!");
    init = INIT_FAILED;
  }
  if (!iMA(_Symbol, PERIOD_M15, 13, 8, MODE_SMMA, PRICE_MEDIAN, 0) > 0) {
    Alert("Timeframe M15 is not active!");
    init = INIT_FAILED;
  }
  if (!iMA(_Symbol, PERIOD_M30, 13, 8, MODE_SMMA, PRICE_MEDIAN, 0) > 0) {
    Alert("Timeframe M30 is not active!");
    init = INIT_FAILED;
  }
  if (init == INIT_SUCCEEDED) {
    Print("Timeframes are correct!");
  }
  return (init);
}
