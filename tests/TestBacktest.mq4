//+------------------------------------------------------------------+
//| Analyse backtest quality of the test.
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                            Copyright 2016, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
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

int handle;
long bar_counter = 0;
long tick_counter = 0;

//+------------------------------------------------------------------+
//| Expert init function                                             |
//+------------------------------------------------------------------+
int OnInit() {
  long symbol_spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
  int real_spread = (int)MathRound((Ask - Bid) * MathPow(10, Digits));
  double lot_step = MarketInfo(_Symbol, MODE_LOTSTEP);
  Print("Initializing...");
  PrintFormat("Symbol:        : %s", _Symbol);
  PrintFormat("Period:        : %d", Period());
  PrintFormat("Ask/Bid        : %g/%g", NormalizeDouble(Ask, Digits), NormalizeDouble(Bid, Digits));
  PrintFormat("Symbol digits  : %g", Digits);
  // Init file.
  handle = FileOpen(_Symbol + "_ticks.csv", FILE_CSV|FILE_WRITE,',');
  if (handle > 0) {
    FileWrite(handle, "Datatime", "Bid", "Ask", "Volume");
  }
  else {
    Alert("Failed to create a file!");
    return INIT_FAILED;
  }
  return INIT_SUCCEEDED;
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
  static long last_bar = 0;
  tick_counter++;
  if (handle > 0) {
    FileWrite(handle, TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES|TIME_SECONDS), Bid, Ask, Volume[0]);
  }
  if (last_bar != iTime(NULL, 0, 0)) {
    last_bar =  iTime(NULL, 0, 0);
    bar_counter++;
  }
}
//+------------------------------------------------------------------+
//| Expert deinit function                                           |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
  Print("Deinitializing...");
  if (handle > 0) {
    FileClose(handle);
  }
  Print("### Statistics");
  PrintFormat("Bars         : %d", bar_counter);
  PrintFormat("Ticks        : %d", tick_counter);
  PrintFormat("Ticks per bar: %g", tick_counter/bar_counter);
  PrintFormat("Ticks per min: %g", tick_counter/bar_counter/Period());
  PrintFormat("Ticks per sec: %.1f", (double)tick_counter/bar_counter/Period()/60);
}
