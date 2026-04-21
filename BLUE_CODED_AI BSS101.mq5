//+------------------------------------------------------------------+
//|                  BLUE CODED AI - MT5 EA                          |
//|     Smart Money Concept + Dynamic Risk + Trading Window         |
//|     Owner: Larnii Cheezy | +27 71 039 5293                       |
//+------------------------------------------------------------------+
#property strict

#include <Trade/Trade.mqh>
CTrade trade;

//--- Input Parameters
input int MA_Period = 50;
input ENUM_TIMEFRAMES TrendTF = PERIOD_H1;
input ENUM_TIMEFRAMES SignalTF = PERIOD_M15;
input double RiskPercent = 2.0;
input int StopLossPoints = 1500;
input int TakeProfitPoints = 3000;
input int MaxSpread = 20;
input int StartHour = 6;
input int EndHour = 22;
input int MaxTradesPerDay = 35;

//--- Global Variables
double LotSize;
int tradesToday = 0;
datetime lastTradeDay = 0;

//+------------------------------------------------------------------+
//| Calculate Dynamic Lot Size                                       |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = balance * RiskPercent / 100.0;
   double slValue = StopLossPoints * _Point * SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   double lot = NormalizeDouble(riskAmount / slValue, 2);
   if (lot < 0.01) lot = 0.01;
   if (lot > 0.50) lot = 0.50;
   return lot;
}

//+------------------------------------------------------------------+
//| Get start of day datetime                                        |
//+------------------------------------------------------------------+
datetime GetStartOfDay(datetime time)
{
   MqlDateTime dt;
   TimeToStruct(time, dt);
   dt.hour = dt.min = dt.sec = 0;
   return StructToTime(dt);
}

//+------------------------------------------------------------------+
//| Create Display Overlay                                           |
//+------------------------------------------------------------------+
void CreateDisplay()
{
   string labelOwner = "OwnerLabel";

   ObjectDelete(0, labelOwner);

   ObjectCreate(0, labelOwner, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, labelOwner, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, labelOwner, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, labelOwner, OBJPROP_YDISTANCE, 10);
   ObjectSetInteger(0, labelOwner, OBJPROP_FONTSIZE, 14);
   ObjectSetInteger(0, labelOwner, OBJPROP_COLOR, clrDeepSkyBlue);
   ObjectSetString(0, labelOwner, OBJPROP_TEXT,
      "BLUE CODED AI\nOwner: Larnii Cheezy\n+27 71 039 5293");
}

//+------------------------------------------------------------------+
//| OnInit                                                           |
//+------------------------------------------------------------------+
int OnInit()
{
   ChartSetInteger(0, CHART_COLOR_BACKGROUND, clrBlack);
   ChartSetInteger(0, CHART_COLOR_FOREGROUND, clrWhite);
   ChartSetInteger(0, CHART_COLOR_GRID, clrGray);

   CreateDisplay();
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| OnTick - Main Logic                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   datetime now = TimeCurrent();
   datetime today = GetStartOfDay(now);

   if (today != lastTradeDay)
   {
      tradesToday = 0;
      lastTradeDay = today;
   }

   MqlDateTime dt;
   TimeToStruct(now, dt);
   if (dt.hour < StartHour || dt.hour > EndHour) return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double spread = (ask - bid) / _Point;
   if (spread > MaxSpread) return;
   if (tradesToday >= MaxTradesPerDay) return;

   if (Bars(_Symbol, SignalTF) < MA_Period || Bars(_Symbol, TrendTF) < MA_Period) return;

   int handleFast = iMA(_Symbol, SignalTF, 20, 0, MODE_EMA, PRICE_CLOSE);
   int handleSlow = iMA(_Symbol, SignalTF, MA_Period, 0, MODE_EMA, PRICE_CLOSE);
   if (handleFast == INVALID_HANDLE || handleSlow == INVALID_HANDLE) return;

   double fastMA[], slowMA[];
   if (CopyBuffer(handleFast, 0, 0, 1, fastMA) <= 0 ||
       CopyBuffer(handleSlow, 0, 0, 1, slowMA) <= 0)
      return;

   double fast = fastMA[0];
   double slow = slowMA[0];

   LotSize = CalculateLotSize();
   double sl = StopLossPoints * _Point;
   double tp = TakeProfitPoints * _Point;

   Print("Hour: ", dt.hour, " | Spread: ", spread, " | TradesToday: ", tradesToday);
   Print("FastMA: ", fast, " | SlowMA: ", slow);

   if (fast > slow)
   {
      double slPrice = NormalizeDouble(ask - sl, _Digits);
      double tpPrice = NormalizeDouble(ask + tp, _Digits);
      if (trade.Buy(LotSize, _Symbol, ask, slPrice, tpPrice, "BLUE CODED BUY"))
         tradesToday++;
   }
   else if (fast < slow)
   {
      double slPrice = NormalizeDouble(bid + sl, _Digits);
      double tpPrice = NormalizeDouble(bid - tp, _Digits);
      if (trade.Sell(LotSize, _Symbol, bid, slPrice, tpPrice, "BLUE CODED SELL"))
         tradesToday++;
   }
}
