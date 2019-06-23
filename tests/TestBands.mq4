//+------------------------------------------------------------------+
//|                                                    TestBands.mq4 |
//|                       Copyright 2016-2019, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Test whether Bands indicator values are correct.
//+------------------------------------------------------------------+

#property strict

int OnInit() {
  double bands[3] = {};
  int tf[5] = { 1, 5, 15, 30, 60 };
  int modes[3] = { MODE_LOWER, MODE_MAIN, MODE_UPPER };
  bool correct, result = TRUE;

  Print("Testing values for Bands indicator...");
  PrintFormat("Symbol            : %s", _Symbol);
  PrintFormat("Current timeframe : %d", _Period);
  PrintFormat("Bid/Ask           : %g/%g", NormalizeDouble(Bid, Digits), NormalizeDouble(Ask, Digits));
  for (int p = 0; p < ArraySize(tf); p++) {
    for (int m = 0; m < ArraySize(modes); m++) {
      bands[m] = iBands(_Symbol, tf[p], 20, 2.0, 0, 0, modes[m], 0);
    }
    correct = (bands[0] > 0 && bands[1] > 0 && bands[2] > 0 && bands[0] < bands[1] && bands[1] < bands[2]);
    PrintFormat("Bands M%d          : %g/%g/%g => %s", tf[p], bands[0], bands[1], bands[2], correct ? "CORRECT" : "INCORRECT");
    result &= correct;
  }
  if (result) {
    Print("Bands values are correct!");
    return INIT_SUCCEEDED;
  } else {
    Print("Error: Bands values are not correct!");
    return INIT_FAILED;
  }
}
