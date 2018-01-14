//+------------------------------------------------------------------+
//| Analyse quality of the test.
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

input bool SaveCSV = False;

int handle;
long bar_counter = 0;
long tick_counter = 0;

//+------------------------------------------------------------------+
//| Calculate modelling quality.
//| See:
//| - https://www.mql5.com/en/articles/1486
//| - https://www.mql5.com/en/articles/1513
//+------------------------------------------------------------------+
double CalculateModellingQuality(int TimePr) {

  int nBarsInM1     = 0;
  int nBarsInPr     = 0;
  int nBarsInNearPr = 0;
  int TimeNearPr = PERIOD_M1;
  double ModellingQuality = 0;
  long   StartGen     = 0;
  long   StartBar     = 0;
  long   StartGenM1   = 0;
  long   HistoryTotal = 0;
  datetime modeling_start_time =  D'1971.01.01 00:00';

  if (TimePr == PERIOD_M1)  TimeNearPr = PERIOD_M1;
  if (TimePr == PERIOD_M5)  TimeNearPr = PERIOD_M1;
  if (TimePr == PERIOD_M15) TimeNearPr = PERIOD_M5;
  if (TimePr == PERIOD_M30) TimeNearPr = PERIOD_M15;
  if (TimePr == PERIOD_H1)  TimeNearPr = PERIOD_M30;
  if (TimePr == PERIOD_H4)  TimeNearPr = PERIOD_H1;
  if (TimePr == PERIOD_D1)  TimeNearPr = PERIOD_H4;
  if (TimePr == PERIOD_W1)  TimeNearPr = PERIOD_D1;
  if (TimePr == PERIOD_MN1) TimeNearPr = PERIOD_W1;

  // 1 minute.
  double nBars = fmin(iBars(NULL,TimePr) * TimePr, iBars(NULL,PERIOD_M1));
  for (int i = 0; i < nBars;i++) {
    if (iOpen(NULL,PERIOD_M1, i) >= 0.000001) {
      if (iTime(NULL, PERIOD_M1, i) >= modeling_start_time)
      {
        nBarsInM1++;
      }
    }
  }

  // Nearest time.
  nBars = iBars(NULL,TimePr);
  for (int i = 0; i < nBars;i++) {
    if (iOpen(NULL,TimePr, i) >= 0.000001) {
      if (iTime(NULL, TimePr, i) >= modeling_start_time)
        nBarsInPr++;
    }
  }

  // Period time.
  nBars = fmin(iBars(NULL, TimePr) * TimePr/TimeNearPr, iBars(NULL, TimeNearPr));
  for (int i = 0; i < nBars;i++) {
    if (iOpen(NULL, TimeNearPr, i) >= 0.000001) {
      if (iTime(NULL, TimeNearPr, i) >= modeling_start_time)
        nBarsInNearPr++;
    }
  }

  HistoryTotal   = nBarsInPr;
  nBarsInM1      = nBarsInM1 / TimePr;
  nBarsInNearPr  = nBarsInNearPr * TimeNearPr / TimePr;
  StartGenM1     = HistoryTotal - nBarsInM1;
  StartBar       = HistoryTotal - nBarsInPr;
  StartBar       = 0;
  StartGen       = HistoryTotal - nBarsInNearPr;

  if(TimePr == PERIOD_M1) {
    StartGenM1 = HistoryTotal;
    StartGen   = StartGenM1;
  }
  if((HistoryTotal - StartBar) != 0) {
    ModellingQuality = ((0.25 * (StartGen-StartBar) +
          0.5 * (StartGenM1 - StartGen) +
          0.9 * (HistoryTotal - StartGenM1)) / (HistoryTotal - StartBar)) * 100;
  }
  return (ModellingQuality);
}

//+------------------------------------------------------------------+
//| Expert init function                                             |
//+------------------------------------------------------------------+
int OnInit() {
  long symbol_spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
  int real_spread = (int)round((Ask - Bid) * pow(10, Digits));
  double lot_step = MarketInfo(_Symbol, MODE_LOTSTEP);
  Print("Initializing...");
  PrintFormat("Symbol:        : %s", _Symbol);
  PrintFormat("Period:        : %d", Period());
  Print("### Modelling Quality");
  printf("Modelling Quality for M1  : %.2f%%", CalculateModellingQuality(PERIOD_M1));
  printf("Modelling Quality for M5  : %.2f%%", CalculateModellingQuality(PERIOD_M5));
  printf("Modelling Quality for M15 : %.2f%%", CalculateModellingQuality(PERIOD_M15));
  printf("Modelling Quality for M30 : %.2f%%", CalculateModellingQuality(PERIOD_M30));
  printf("Modelling Quality for H1  : %.2f%%", CalculateModellingQuality(PERIOD_H1));
  printf("Modelling Quality for H4  : %.2f%%", CalculateModellingQuality(PERIOD_H4));
  // Init file.
  if (SaveCSV) {
    handle = FileOpen(_Symbol + "_ticks.csv", FILE_CSV|FILE_WRITE,',');
    if (handle > 0) {
      FileWrite(handle, "Datatime", "Bid", "Ask", "Volume");
    }
    else {
      Alert("Failed to create a file!");
      return INIT_FAILED;
    }
  }
  return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
  static long last_bar = 0;
  tick_counter++;
  if (SaveCSV && handle > 0) {
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
  if (SaveCSV && handle > 0) {
    FileClose(handle);
  }
  Print("### Statistics");
  PrintFormat("Bars         : %d", bar_counter);
  PrintFormat("Ticks        : %d", tick_counter);
  PrintFormat("Ticks per bar: %g", tick_counter/bar_counter);
  PrintFormat("Ticks per min: %g", tick_counter/bar_counter/Period());
  PrintFormat("Ticks per sec: %.2f", (double)tick_counter/bar_counter/Period()/60);
}
