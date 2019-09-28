//+------------------------------------------------------------------+
//|                                                     TestLeverage |
//|                       Copyright 2016-2019, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Test whether account leverage is correct.
//| @docs: https://www.mql5.com/en/docs/constants/environment_state/accountinformation
//+------------------------------------------------------------------+

#property strict

/**
 * Implements Init even handler.
 */
int OnInit() {
    long leverage = AccountInfoInteger(ACCOUNT_LEVERAGE);
    PrintFormat("Account leverage : %d", leverage);
    return INIT_SUCCEEDED;
}
