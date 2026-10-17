//+------------------------------------------------------------------+
//| RiskSizer.mqh                                                    |
//| FR-4: Position sizing logic                                      |
//+------------------------------------------------------------------+
#ifndef RISK_SIZER_MQH
#define RISK_SIZER_MQH

enum ENUM_RISK_MODE
{
   RISK_FIXED_USD     = 0,   // Fixed amount in account currency
   RISK_PERCENT_EQUITY = 1   // Percent of equity
};

enum ENUM_ACCOUNT_SIZE_MODE
{
   ACCOUNT_REAL   = 0,   // Use actual account equity
   ACCOUNT_MANUAL = 1    // Use manually specified account size
};

struct RiskResult
{
   double lots;
   double riskMoney;
   double slDistancePips;
   string reason;     // empty = OK, non-empty = fail reason
};

//--- Compute lot size for SELL position
//    slPercent: e.g. 0.15 means 0.15%
//    Returns RiskResult; check reason=="OK" for success
RiskResult CalcLotSize(
   double bidPrice,
   double slPercent,
   bool   includeSpreadInRisk,
   int    riskMode,          // ENUM_RISK_MODE
   double riskUsd,
   double riskPercent,
   int    accountSizeMode,   // ENUM_ACCOUNT_SIZE_MODE
   double manualAccountSize,
   double maxRiskPctOfEquity,
   bool   allowMinLotOverRisk
)
{
   RiskResult res;
   res.lots          = 0;
   res.riskMoney     = 0;
   res.slDistancePips = 0;
   res.reason        = "";

   // Determine account size for safety check
   double equity      = AccountInfoDouble(ACCOUNT_EQUITY);
   double accountSize = (accountSizeMode == ACCOUNT_MANUAL) ? manualAccountSize : equity;
   if(accountSize <= 0) accountSize = equity;

   // Determine risk money
   double riskMoney = 0;
   if(riskMode == RISK_FIXED_USD)
      riskMoney = riskUsd;
   else
      riskMoney = accountSize * riskPercent / 100.0;

   res.riskMoney = riskMoney;

   // Safety gate (FR-4.5)
   if(maxRiskPctOfEquity > 0 && equity > 0)
   {
      double maxAllowed = equity * maxRiskPctOfEquity / 100.0;
      if(riskMoney > maxAllowed)
      {
         res.reason = StringFormat("Risk $%.2f exceeds max %.1f%% of equity ($%.2f)", riskMoney, maxRiskPctOfEquity, maxAllowed);
         return res;
      }
   }

   // SL distance for SELL: SL = Bid * (1 + slPercent/100)
   double slPrice    = bidPrice * (1.0 + slPercent / 100.0);
   double tickSize   = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE_LOSS);
   if(tickSize <= 0 || tickValue <= 0)
   {
      res.reason = "Invalid tick size or tick value";
      return res;
   }

   // SL distance in price
   double slDistPrice = slPrice - bidPrice;

   // Optionally include spread (SELL: open at Bid, SL triggered at Ask = Bid + spread)
   if(includeSpreadInRisk)
   {
      double spread = SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID);
      if(spread > 0) slDistPrice += spread;
   }

   // Convert distance to ticks
   double slDistTicks = slDistPrice / tickSize;
   res.slDistancePips = slDistPrice / SymbolInfoDouble(_Symbol, SYMBOL_POINT) / 10.0; // approx pips

   if(slDistTicks <= 0)
   {
      res.reason = "SL distance is zero or negative";
      return res;
   }

   // Lot = riskMoney / (slDistTicks * tickValuePerLot)
   double rawLots = riskMoney / (slDistTicks * tickValue);

   // Normalize lot
   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(lotStep <= 0) lotStep = 0.01;

   // Round DOWN to lot step (FR-4.4)
   double lots = MathFloor(rawLots / lotStep) * lotStep;
   lots = MathMin(lots, maxLot);
   lots = NormalizeDouble(lots, 2);

   if(lots < minLot)
   {
      if(allowMinLotOverRisk)
      {
         lots = minLot;
         res.reason = "OK_MINLOT"; // Mark as over-risk but allowed
      }
      else
      {
         res.reason = StringFormat("Calculated lots %.5f < min lot %.5f, trade skipped", rawLots, minLot);
         return res;
      }
   }
   else
   {
      res.reason = "OK";
   }

   res.lots = lots;
   return res;
}

#endif // RISK_SIZER_MQH
