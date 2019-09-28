//+------------------------------------------------------------------+
//|                                               TestTimeframes.mq4 |
//|                       Copyright 2016-2019, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Test whether timeframes are active.
//+------------------------------------------------------------------+

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
