//+------------------------------------------------------------------+
//|                                                TestEnvelopes.mq4 |
//|                       Copyright 2016-2019, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Test whether Envelopes indicator values are correct.
//+------------------------------------------------------------------+

#property strict

int OnInit() {
  double envs[3] = {};
  int tf[5] = { 1, 5, 15, 30, 60 };
  int modes[3] = { MODE_LOWER, MODE_MAIN, MODE_UPPER };
  bool correct, result = TRUE;

  Print("Testing values for Envelopes indicator...");
  PrintFormat("Symbol            : %s", _Symbol);
  PrintFormat("Current timeframe : %d", PERIOD_CURRENT);
  PrintFormat("Bid/Ask           : %g/%g", NormalizeDouble(Bid, Digits), NormalizeDouble(Ask, Digits));
  for (int p = 0; p < ArraySize(tf); p++) {
    for (int m = 0; m < ArraySize(modes); m++) {
      envs[m] = iEnvelopes(_Symbol, tf[p], 20, MODE_SMA, 0, PRICE_CLOSE, 0.10, modes[m], 0);
    }
    correct = (envs[0] > 0 && envs[1] > 0 && envs[2] > 0 && envs[0] < envs[1] && envs[1] < envs[2]);
    PrintFormat("Envelopes M%d          : %g/%g/%g => %s", tf[p], envs[0], envs[1], envs[2], correct ? "CORRECT" : "INCORRECT");
    result &= correct;
  }
  if (result) {
    Print("Envelopes values are correct!");
    return INIT_SUCCEEDED;
  } else {
    Print("Error: Envelopes values are not correct!");
    return INIT_FAILED;
  }
}
