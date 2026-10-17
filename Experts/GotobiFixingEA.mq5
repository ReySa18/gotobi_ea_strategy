//+------------------------------------------------------------------+
//|                         GotobiFixingEA.mq5                       |
//|  Gotobi USDJPY Fixing EA — v0.1                                  |
//|  Author : Reymondo (Gotobi EA)                                   |
//|  Desc   : Sells USDJPY at Tokyo fixing window (09:55 JST)        |
//|           on Gotobi calendar days, exits at entry+25 min.        |
//|  PRD    : PRD.md v0.1                                            |
//+------------------------------------------------------------------+
#property copyright "Reymondo — Gotobi EA v0.1"
#property link      ""
#property version   "0.10"
#property description "Gotobi USDJPY Fixing EA — Sells at 09:55 JST on Gotobi days"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include "..\Include\JapanHolidays.mqh"
#include "..\Include\TimeService.mqh"
#include "..\Include\GotobiCalendar.mqh"
#include "..\Include\RiskSizer.mqh"
#include "..\Include\Logger.mqh"

//=======================================================================
// INPUT PARAMETERS
//=======================================================================

//--- Waktu / Time
input group "=== WAKTU / TIME ==="
input bool   InpUseTimeFilter       = true;    // Filter sesi Tokyo
input int    InpSessionStartHourJst = 9;       // Jam mulai sesi JST
input int    InpSessionStartMinJst  = 0;       // Menit mulai sesi JST
input int    InpSessionEndHourJst   = 15;      // Jam akhir sesi JST
input int    InpSessionEndMinJst    = 0;       // Menit akhir sesi JST
input int    InpEntryHourJst        = 9;       // Jam entry JST
input int    InpEntryMinJst         = 55;      // Menit entry JST
input int    InpHoldMinutes         = 25;      // Durasi hold (menit)
input int    InpManualBrokerGmt     = 3;       // Offset broker GMT (Tester)
input bool   InpTesterAutoDst       = true;    // Auto-DST di Tester (GMT-1 di musim dingin)
input bool   InpLiveFallbackToManual = false;  // Fallback ke manual jika deteksi live gagal

//--- Strategi / Strategy
input group "=== STRATEGI / STRATEGY ==="
input double InpSlPercent           = 0.15;   // Stop Loss (% dari harga masuk)

enum ENUM_DAY_MODE { GOTOBI_ONLY = 0, NON_GOTOBI_PLACEBO = 1, ALL_DAYS = 2 };
input ENUM_DAY_MODE InpDayMode      = GOTOBI_ONLY; // Mode hari trading

//--- Risiko / Risk
input group "=== RISIKO / RISK ==="
input ENUM_RISK_MODE       InpRiskMode              = RISK_FIXED_USD;  // Mode risiko
input double               InpRiskUsd               = 100.0;           // Risiko per trade (mata uang akun)
input double               InpRiskPercent           = 0.5;             // Risiko % ekuitas
input ENUM_ACCOUNT_SIZE_MODE InpAccountSizeMode     = ACCOUNT_REAL;    // Basis ukuran akun
input double               InpManualAccountSize     = 10000.0;         // Ukuran akun manual
input double               InpMaxRiskPercentOfEquity = 2.0;            // Pagar keamanan (% ekuitas)
input bool                 InpIncludeSpreadInRisk   = true;            // Spread masuk hitungan SL
input bool                 InpAllowMinLotOverRisk   = false;           // Izinkan lot minimum

//--- Eksekusi / Execution
input group "=== EKSEKUSI / EXECUTION ==="
input bool   InpUseSpreadFilter     = true;    // Filter spread
input int    InpMaxSpreadPoints     = 20;      // Batas spread (points)
input int    InpMaxDeviationPoints  = 20;      // Deviasi maksimum (points)
input int    InpMaxEntryDelaySec    = 30;      // Jendela entry (detik)

//--- Sistem / System
input group "=== SISTEM / SYSTEM ==="
input long   InpMagic               = 20261017; // Magic Number

//=======================================================================
// GLOBAL STATE
//=======================================================================

CTrade         g_Trade;
CPositionInfo  g_PosInfo;
CAccountInfo   g_AccInfo;

bool   g_IsTester            = false;
int    g_BrokerGmtOffset     = 3;
bool   g_OffsetValidated     = false;
bool   g_TradedToday         = false;
int    g_CurrentJstDate      = 0;   // YYYYMMDD of current JST date
datetime g_EntryServerTime   = 0;   // Scheduled entry server time for today
datetime g_ExitServerTime    = 0;   // Scheduled exit server time for today
datetime g_LastOffsetCheck   = 0;

// Position tracking for MAE/MFE
double g_OpenPrice           = 0;
double g_MAE                 = 0;   // Maximum Adverse Excursion (in price)
double g_MFE                 = 0;   // Maximum Favorable Excursion (in price)
bool   g_HasPosition         = false;

// Retry state for exit
int    g_ExitRetryCount      = 0;
static const int MAX_EXIT_RETRIES = 3;

//=======================================================================
// UTILITY FUNCTIONS
//=======================================================================

//--- Get current JST datetime
datetime CurrentJst()
{
   datetime srv = TimeTradeServer();
   return ServerToJst(srv, g_BrokerGmtOffset);
}

//--- Get current JST date as YYYYMMDD
int CurrentJstDate()
{
   datetime jst = CurrentJst();
   MqlDateTime st;
   TimeToStruct(jst, st);
   return st.year * 10000 + st.mon * 100 + st.day;
}

//--- Check if our position is open
bool HasOpenPosition()
{
   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == InpMagic)
         return true;
   }
   return false;
}

//--- Get our open position ticket
ulong GetOurPositionTicket()
{
   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == InpMagic)
         return ticket;
   }
   return 0;
}

//--- Check if we have already traded today (from deal history) — FR-7.3
bool HaveTradedTodayFromHistory()
{
   datetime jst     = CurrentJst();
   MqlDateTime st;
   TimeToStruct(jst, st);
   // Build JST day start and end in UTC
   datetime jstDayStart = (datetime)StringToTime(StringFormat("%04d.%02d.%02d 00:00:00",
                           st.year, st.mon, st.day)) - 32400; // JST→UTC
   datetime jstDayEnd   = jstDayStart + 86400;
   // Convert to server time
   datetime srvStart = jstDayStart + (datetime)(g_BrokerGmtOffset * 3600);
   datetime srvEnd   = jstDayEnd   + (datetime)(g_BrokerGmtOffset * 3600);

   if(!HistorySelect(srvStart, srvEnd)) return false;
   int total = HistoryDealsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;
      if(HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol &&
         HistoryDealGetInteger(ticket, DEAL_MAGIC) == InpMagic &&
         HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_IN)
         return true;
   }
   return false;
}

//--- Normalize price to symbol tick size
double NormalizeToTickSize(double price)
{
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickSize <= 0) return price;
   return MathRound(price / tickSize) * tickSize;
}

//--- Spread in points
double GetSpreadPoints()
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double pt  = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(pt <= 0) return 0;
   return (ask - bid) / pt;
}

//--- Calculate entry and exit server times for today
void RecalcTodayTimes()
{
   datetime jst = CurrentJst();
   MqlDateTime st;
   TimeToStruct(jst, st);

   // Build entry JST time
   datetime entryJst = (datetime)StringToTime(StringFormat("%04d.%02d.%02d %02d:%02d:00",
                        st.year, st.mon, st.day,
                        InpEntryHourJst, InpEntryMinJst));
   g_EntryServerTime = JstToServer(entryJst, g_BrokerGmtOffset);

   // Exit: entry time + hold minutes (based on scheduled entry, not fill time — FR-6.3)
   datetime exitJst  = entryJst + (datetime)(InpHoldMinutes * 60);
   g_ExitServerTime  = JstToServer(exitJst, g_BrokerGmtOffset);

   LOG_DEBUG("INIT", StringFormat("Today entry=%s exit=%s (server times)",
      TimeToString(g_EntryServerTime, TIME_DATE|TIME_SECONDS),
      TimeToString(g_ExitServerTime,  TIME_DATE|TIME_SECONDS)));
}

//--- Update broker offset (live mode)
void UpdateLiveOffset()
{
   int detected = DetectLiveBrokerOffset();
   if(IsOffsetValid(detected))
   {
      if(g_BrokerGmtOffset != detected)
         LOG_INFO("TIME", StringFormat("Broker GMT offset updated: %+d → %+d", g_BrokerGmtOffset, detected));
      g_BrokerGmtOffset = detected;
      g_OffsetValidated = true;
   }
   else
   {
      LOG_WARN("TIME", StringFormat("Failed to detect broker offset (got %d). %s",
         detected,
         InpLiveFallbackToManual ? "Using manual fallback." : "Entry BLOCKED."));
      if(InpLiveFallbackToManual)
      {
         g_BrokerGmtOffset = InpManualBrokerGmt;
         g_OffsetValidated = true;
      }
      else
      {
         g_OffsetValidated = false;
      }
   }
}

//--- Update tester offset (supports auto-DST)
void UpdateTesterOffset()
{
   datetime utcNow = TimeTradeServer() - (datetime)(InpManualBrokerGmt * 3600);
   g_BrokerGmtOffset = GetTesterBrokerOffset(utcNow, InpManualBrokerGmt, InpTesterAutoDst);
   g_OffsetValidated  = true;
   LOG_DEBUG("TIME", StringFormat("Tester broker offset = %+d (AutoDst=%s)",
      g_BrokerGmtOffset, InpTesterAutoDst ? "ON" : "OFF"));
}

//--- Refresh offset (called on new day and pre-entry)
void RefreshBrokerOffset()
{
   if(g_IsTester)
      UpdateTesterOffset();
   else
      UpdateLiveOffset();
   g_LastOffsetCheck = TimeTradeServer();
}

//--- Is today a valid trading day per InpDayMode?
bool IsTodayValidTradingDay()
{
   int jstDate = CurrentJstDate();
   switch(InpDayMode)
   {
      case GOTOBI_ONLY:
         return IsGotobiDay(jstDate);
      case NON_GOTOBI_PLACEBO:
         return IsNonGotobiWorkingDay(jstDate);
      case ALL_DAYS:
         return IsWorkingDay(jstDate) && !IsBrokerHoliday(jstDate);
      default:
         return false;
   }
}

//--- Is current JST time within session window?
bool IsWithinSession()
{
   if(!InpUseTimeFilter) return true;
   datetime jst = CurrentJst();
   MqlDateTime st;
   TimeToStruct(jst, st);
   int minOfDay = st.hour * 60 + st.min;
   int sessStart = InpSessionStartHourJst * 60 + InpSessionStartMinJst;
   int sessEnd   = InpSessionEndHourJst   * 60 + InpSessionEndMinJst;
   return (minOfDay >= sessStart && minOfDay < sessEnd);
}

//--- Check if symbol is valid (starts with USDJPY) — FR-5.4
bool IsSymbolValid()
{
   string sym = _Symbol;
   return StringFind(sym, "USDJPY") == 0;
}

//--- Check hedging/netting conflict — FR-5.5
bool HasConflictingPosition()
{
   long acctType = AccountInfoInteger(ACCOUNT_MARGIN_MODE);
   if(acctType == ACCOUNT_MARGIN_MODE_RETAIL_NETTING)
   {
      // Netting: if there's ANY position on this symbol not from our magic, skip
      int total = PositionsTotal();
      for(int i = 0; i < total; i++)
      {
         ulong t = PositionGetTicket(i);
         if(t == 0) continue;
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) != InpMagic)
            return true;
      }
   }
   return false;
}

//--- Close our position with retry logic — FR-6.4
bool CloseOurPosition(string reason)
{
   ulong ticket = GetOurPositionTicket();
   if(ticket == 0) return true; // Already closed

   if(!PositionSelectByTicket(ticket))
   {
      LOG_WARN("EXIT", "Cannot select position for close");
      return false;
   }

   double closePrice = PositionGetDouble(POSITION_PRICE_CURRENT);
   double openPrc    = PositionGetDouble(POSITION_PRICE_OPEN);
   double lots       = PositionGetDouble(POSITION_VOLUME);

   g_Trade.SetDeviationInPoints(InpMaxDeviationPoints);
   bool ok = g_Trade.PositionClose(ticket, InpMaxDeviationPoints);
   if(ok)
   {
      LogExit(TimeTradeServer(), g_BrokerGmtOffset, closePrice, openPrc, lots, reason, g_MAE, g_MFE);
      g_HasPosition = false;
      g_OpenPrice   = 0;
      g_MAE         = 0;
      g_MFE         = 0;
      g_ExitRetryCount = 0;
      return true;
   }
   else
   {
      g_ExitRetryCount++;
      LOG_WARN("EXIT", StringFormat("Close failed (attempt #%d): %s [%d] Reason=%s",
         g_ExitRetryCount, g_Trade.ResultComment(), g_Trade.ResultRetcode(), reason));
      return false;
   }
}

//--- Open SELL position — FR-3, FR-3.4
bool OpenSellPosition()
{
   // Pre-entry checks
   if(!g_OffsetValidated)
   {
      LogSkip("Offset not validated — entry blocked", TimeTradeServer(), g_BrokerGmtOffset);
      return false;
   }
   if(!IsWithinSession())
   {
      LogSkip("Outside Tokyo session", TimeTradeServer(), g_BrokerGmtOffset);
      return false;
   }
   if(HasConflictingPosition())
   {
      LogSkip("Conflicting position on netting account", TimeTradeServer(), g_BrokerGmtOffset);
      return false;
   }

   // Spread check (FR-5.1)
   if(InpUseSpreadFilter)
   {
      double spread = GetSpreadPoints();
      if(spread > InpMaxSpreadPoints)
      {
         LOG_INFO("ENTRY", StringFormat("Spread %.1f pts > limit %d pts, waiting...", spread, InpMaxSpreadPoints));
         return false; // Will be retried within entry window
      }
   }

   // Calculate lot size (FR-4)
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   RiskResult rr = CalcLotSize(
      bid, InpSlPercent,
      InpIncludeSpreadInRisk,
      (int)InpRiskMode,
      InpRiskUsd, InpRiskPercent,
      (int)InpAccountSizeMode, InpManualAccountSize,
      InpMaxRiskPercentOfEquity,
      InpAllowMinLotOverRisk
   );

   if(rr.reason != "OK" && rr.reason != "OK_MINLOT")
   {
      LogSkip(StringFormat("Lot calculation failed: %s", rr.reason), TimeTradeServer(), g_BrokerGmtOffset);
      return false;
   }
   if(rr.reason == "OK_MINLOT")
      LOG_WARN("ENTRY", StringFormat("Using min lot %.2f (over-risk allowed)", rr.lots));

   // SL price (FR-3.4)
   double slPrice = NormalizeToTickSize(bid * (1.0 + InpSlPercent / 100.0));

   // Get filling mode (FR-5.3)
   ENUM_ORDER_TYPE_FILLING filling = ORDER_FILLING_IOC;
   long fillingMode = SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
   if((fillingMode & SYMBOL_FILLING_FOK) != 0)
      filling = ORDER_FILLING_FOK;
   else if((fillingMode & SYMBOL_FILLING_IOC) != 0)
      filling = ORDER_FILLING_IOC;
   else
      filling = ORDER_FILLING_RETURN;

   g_Trade.SetTypeFilling(filling);
   g_Trade.SetDeviationInPoints(InpMaxDeviationPoints);
   g_Trade.SetExpertMagicNumber(InpMagic);

   double spreadPts = GetSpreadPoints();
   bool ok = g_Trade.Sell(rr.lots, _Symbol, bid, slPrice, 0.0,
      StringFormat("GotobiEA v0.1 | SL=%.5f | Risk=%.2f", slPrice, rr.riskMoney));

   if(ok && (g_Trade.ResultRetcode() == TRADE_RETCODE_DONE ||
             g_Trade.ResultRetcode() == TRADE_RETCODE_PLACED))
   {
      g_OpenPrice   = g_Trade.ResultPrice();
      if(g_OpenPrice <= 0) g_OpenPrice = bid;
      g_MAE         = 0;
      g_MFE         = 0;
      g_HasPosition = true;
      g_TradedToday = true;
      LogEntry(TimeTradeServer(), g_BrokerGmtOffset, g_OpenPrice, slPrice, rr.lots, rr.riskMoney, spreadPts);
      return true;
   }
   else
   {
      LOG_WARN("ENTRY", StringFormat("Sell order failed: %s [%d]",
         g_Trade.ResultComment(), g_Trade.ResultRetcode()));
      return false;
   }
}

//=======================================================================
// EA LIFECYCLE
//=======================================================================

int OnInit()
{
   // Symbol validation (FR-5.4)
   if(!IsSymbolValid())
   {
      LOG_ERROR("INIT", StringFormat("Symbol '%s' is not USDJPY. EA will not run.", _Symbol));
      return INIT_FAILED;
   }

   g_IsTester = (bool)MQLInfoInteger(MQL_TESTER);
   g_Trade.SetExpertMagicNumber(InpMagic);
   g_Trade.SetDeviationInPoints(InpMaxDeviationPoints);
   g_Trade.SetAsyncMode(false);

   // Initial offset detection
   RefreshBrokerOffset();

   // Build today's schedule
   g_CurrentJstDate = CurrentJstDate();
   RecalcTodayTimes();

   // FR-7: Recovery — check if we already have a position
   bool alreadyOpen = HasOpenPosition();
   g_TradedToday    = alreadyOpen || HaveTradedTodayFromHistory();

   if(alreadyOpen)
   {
      g_HasPosition = true;
      ulong t = GetOurPositionTicket();
      if(t != 0 && PositionSelectByTicket(t))
         g_OpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);

      LOG_INFO("INIT", StringFormat("Recovery: found open position ticket=%llu, open=%.5f", t, g_OpenPrice));

      // Check if it's past exit time → close immediately (FR-7.2)
      if(TimeTradeServer() >= g_ExitServerTime)
      {
         LOG_WARN("INIT", "Past exit time with open position — closing immediately (recovery)");
         CloseOurPosition("RECOVERY_PAST_EXIT");
      }
   }

   // Start 1-second timer (FR-6.4)
   EventSetTimer(1);

   LOG_INFO("INIT", StringFormat(
      "GotobiEA v0.1 initialized | Symbol=%s | Magic=%llu | Tester=%s | GMT=%+d | Mode=%s | TradedToday=%s",
      _Symbol, InpMagic, g_IsTester ? "YES" : "NO", g_BrokerGmtOffset,
      EnumToString(InpDayMode), g_TradedToday ? "YES" : "NO"
   ));

   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   LOG_INFO("DEINIT", StringFormat("EA deinitialized. Reason=%d", reason));
}

//--- Common logic called from OnTick and OnTimer
void ProcessLogic()
{
   datetime serverNow = TimeTradeServer();

   // --- Detect new JST day ---
   int jstDateNow = CurrentJstDate();
   if(jstDateNow != g_CurrentJstDate)
   {
      LOG_INFO("DAY", StringFormat("New JST day: %d → %d", g_CurrentJstDate, jstDateNow));
      g_CurrentJstDate = jstDateNow;
      g_TradedToday    = false;
      g_HasPosition    = false;
      g_MAE            = 0;
      g_MFE            = 0;
      g_OpenPrice      = 0;
      g_ExitRetryCount = 0;
      RefreshBrokerOffset();
      RecalcTodayTimes();

      // Log today's status
      bool isGotobi  = IsGotobiDay(jstDateNow);
      bool isValid   = IsTodayValidTradingDay();
      LOG_INFO("DAY", StringFormat("JST=%d IsGotobi=%s ValidForMode=%s",
         jstDateNow, isGotobi ? "YES" : "NO", isValid ? "YES" : "NO"));
   }

   // --- Refresh offset 5 min before entry (FR-1.3) ---
   if(!g_IsTester)
   {
      datetime preEntryCheck = g_EntryServerTime - 300;
      if(serverNow >= preEntryCheck && serverNow < g_EntryServerTime &&
         serverNow - g_LastOffsetCheck > 60)
      {
         RefreshBrokerOffset();
         RecalcTodayTimes(); // Recalc in case offset changed
      }
   }

   // --- Update DST offset every tick in tester (offset can change between bars) ---
   if(g_IsTester && InpTesterAutoDst)
   {
      UpdateTesterOffset();
      // Recalc times only if date hasn't changed but offset might have shifted across DST boundary
   }

   // -----------------------------------------------------------------------
   // POSITION MANAGEMENT: Update MAE/MFE, check for SL hit
   // -----------------------------------------------------------------------
   if(g_HasPosition)
   {
      ulong ticket = GetOurPositionTicket();
      if(ticket == 0)
      {
         // Position closed externally (SL hit)
         LOG_INFO("EXIT", "Position closed externally (SL or manual close)");
         g_HasPosition = false;
         g_OpenPrice   = 0;
         g_MAE         = 0;
         g_MFE         = 0;
         g_ExitRetryCount = 0;
         return;
      }

      // Update MAE/MFE for SELL: adverse = price going up, favorable = price going down
      double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double adverse    = currentBid - g_OpenPrice; // positive = loss for SELL
      double favorable  = g_OpenPrice - currentBid; // positive = profit for SELL
      if(adverse  > g_MAE) g_MAE = adverse;
      if(favorable > g_MFE) g_MFE = favorable;

      // -----------------------------------------------------------------------
      // TIME EXIT (FR-6.3)
      // -----------------------------------------------------------------------
      if(serverNow >= g_ExitServerTime)
      {
         LOG_INFO("EXIT", StringFormat("Time exit triggered. ServerNow=%s ExitTime=%s",
            TimeToString(serverNow, TIME_DATE|TIME_SECONDS),
            TimeToString(g_ExitServerTime, TIME_DATE|TIME_SECONDS)));
         CloseOurPosition("TIME_EXIT");
         return;
      }
   }

   // -----------------------------------------------------------------------
   // ENTRY LOGIC
   // -----------------------------------------------------------------------
   if(!g_TradedToday && !g_HasPosition)
   {
      // Check if today is valid
      if(!IsTodayValidTradingDay())
         return;

      // Before entry window: do nothing
      if(serverNow < g_EntryServerTime)
         return;

      // After entry window (InpMaxEntryDelaySec): skip day (FR-3.2)
      datetime entryDeadline = g_EntryServerTime + (datetime)InpMaxEntryDelaySec;
      if(serverNow > entryDeadline)
      {
         if(!g_TradedToday) // Log once
         {
            LogSkip(StringFormat("Entry window expired. ServerNow=%s Deadline=%s",
               TimeToString(serverNow, TIME_DATE|TIME_SECONDS),
               TimeToString(entryDeadline, TIME_DATE|TIME_SECONDS)));
            g_TradedToday = true; // Prevent repeated logging
         }
         return;
      }

      // Within entry window — attempt to open
      OpenSellPosition();
   }
}

void OnTick()
{
   ProcessLogic();
}

void OnTimer()
{
   ProcessLogic();
}

//--- Chart event: show status on chart
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_CHART_CHANGE)
   {
      Comment(StringFormat(
         "GotobiEA v0.1\n"
         "JST: %s\n"
         "Mode: %s\n"
         "GMT Offset: %+d\n"
         "Traded Today: %s\n"
         "Has Position: %s\n"
         "Next Entry: %s\n"
         "Next Exit: %s",
         TimeToString(CurrentJst(), TIME_DATE|TIME_SECONDS),
         EnumToString(InpDayMode),
         g_BrokerGmtOffset,
         g_TradedToday ? "YES" : "NO",
         g_HasPosition  ? "YES" : "NO",
         TimeToString(g_EntryServerTime, TIME_DATE|TIME_SECONDS),
         TimeToString(g_ExitServerTime,  TIME_DATE|TIME_SECONDS)
      ));
   }
}

//=======================================================================
// END OF EA
//=======================================================================
