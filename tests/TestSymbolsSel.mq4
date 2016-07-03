//+------------------------------------------------------------------+
//|                                               TestSymbolsSel.mq4 |
//|                            Copyright 2016, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Test MT4 structure SYMBOL_SELECTED (file format "symbols.sel").
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

struct SYMBOL_SELECTED {                           // -- offset ---- size --- description -------------------------------------------------
   char   symbol[MAX_SYMBOL_LENGTH+1];             //         0        12     Symbol (szchar)
   UINT   digits;                                  //        12         4     Digits

   UINT   index;         // oder ID ?????          //        16         4     symbol id as in "symbols.raw"
   DWORD  unknown_1;                               //        20         4     always 0x0001

   UINT   group;                                   //        24         4     symbol group id as in "symgroups.raw"
   DWORD  unknown_2;                               //        28         4

   double pointSize;                               //        32         8     point size
   UINT   spread;                                  //        40         4     0=current spread (variable), otherwise fixed spread in points
   DWORD  unknown_3;                               //        44         4

   UINT   tickType;                                //        48         4     last tick type: 0=uptick, 1=downtick, 2=n/a
   WORD   unknown_4;                               //        52         2     always 0x0100
   WORD   unknown_5;                               //        54         2     variable (many times NULL)

   UINT   time;                                    //        56         4     time
   DWORD  unknown_6;                               //        60         4
   double bid;                                     //        64         8     bid
   double ask;                                     //        72         8     ask
   double sessionHigh;                             //        80         8     session high
   double sessionLow;                              //        88         8     session low

   BYTE   unknown_7[16];                           //        96        16     variable (many times NULL)
   double bid_2;                                   //       112         8     bid (repeated)
   double ask_2;                                   //       120         8     ask (repeated)
};                                                 // -------------------------------------------------------------------------------------
                                                   //               = 128

int OnInit() {
    // @todo Find symbols.sel file.
    // @todo Check the values based on struct.
    /*
    if (CheckFormat()) {
        Print("Success!");
    } else {
        ExpertRemove();
    }
    */
}
