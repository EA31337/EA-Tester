//+------------------------------------------------------------------+
//|                                                     TestInitFail |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/**
 * @file
 * Runs OnInit() and make it fail.
 */

/**
 * Initialization function.
 */
int OnInit() { return INIT_FAILED; }
