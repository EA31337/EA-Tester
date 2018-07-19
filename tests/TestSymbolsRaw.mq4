//+------------------------------------------------------------------+
//|                                               TestSymbolsRaw.mq4 |
//|                       Copyright 2016-2018, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Test MT4 structure SYMBOL (file format "symbols.raw").
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

/*
struct SYMBOL {                                    // -- offset ---- size --- description ----------------------------------------------------------------------------
   char   name        [MAX_SYMBOL_LENGTH+1];       //         0        12     symbol      (szchar) ie. "AUDCAD.mkt"
   char   description [64];                        //        12        64     description (szchar)
   char   altName     [MAX_SYMBOL_LENGTH+1];       //        76        12     alt name    (szchar) ie. "AUDCAD" (if not equal 'name')
   char   baseCurrency[MAX_SYMBOL_LENGTH+1];       //        88        12     base currency
   UINT   group;                                   //       100         4     index of group in "symgroups.raw"
   UINT   digits;                                  //       104         4     digits

   UINT   tradeMode;                               //       108         4     0=No|1=CloseOnly|2=Full
   UINT   backgroundColor;                         //       112         4     color in "Market Watch" window
   UINT   id;                                      //       116         4     unique symbol id

   BYTE   unknown_1[1508];                         //       120      1508
   UINT   unknown_2;                               //      1628         4     ?
   BYTE   unknown_3[8];                            //      1632         8
   double unknown_4;                               //      1640         8     ?
   BYTE   unknown_5[12];                           //      1648        12

   UINT   spread;                                  //      1660         4     spread in points: 0=current online spread (variable)
   BYTE   unknown_6[16];                           //      1664        16

   double swapLong;                                //      1680         8     swap long
   double swapShort;                               //      1688         8     swap short

   UINT   unknown_7;                               //      1696         4     ?
   DWORD  unknown_8;                               //      1700         4
   double contractSize;                            //      1704         8     lot size in units
   BYTE   unknown_9[16];                           //      1712        16

   UINT   stopDistance;                            //      1728         4     stop distance level
   BYTE   unknown_10[12];                          //      1732        12

   double marginInit;                              //      1744         8     margin init        (0 = ContractSize)
   double marginMaintenance;                       //      1752         8     margin maintenance (0 = ContractSize)
   double marginHedged;                            //      1760         8     margin hedged
   double marginDivider;                           //      1768         8     leverage calculation: 0...5 = relative to account leverage (ie. 0.83333 = AccountLeverage/MarginDivider)
                                                   //                                               > 10  = absolute custom leverage     (ie. 100     = 1:100)
   double pointSize;                               //      1776         8     point size
   double pointsPerUnit;                           //      1784         8     points per unit

   BYTE   unknown_11[24];                          //      1792        24
   char   marginCurrency[MAX_SYMBOL_LENGTH+1];     //      1816        12     margin currency (szchar)

   BYTE   unknown_12[104];                         //      1828       104
   UINT   unknown_13;                              //      1932         4     ?
};                                                 // ----------------------------------------------------------------------------------------------------------------
*/

int OnInit() {
    // @todo Find symbols.raw file.
    // @todo Check the values based on struct.
    /*
    if (CheckFormat()) {
        Print("Success!");
    } else {
        ExpertRemove();
    }
    */
    return (INIT_FAILED);
}
