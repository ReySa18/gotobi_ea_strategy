//+------------------------------------------------------------------+
//| Logger.mqh                                                       |
//| FR-8: Logging and telemetry                                      |
//+------------------------------------------------------------------+
#ifndef LOGGER_MQH
#define LOGGER_MQH

//--- Log verbosity levels
enum ENUM_LOG_LEVEL
{
   LOG_DEBUG   = 0,
   LOG_INFO    = 1,
   LOG_WARNING = 2,
   LOG_ERROR   = 3
};

static ENUM_LOG_LEVEL g_LogLevel = LOG_INFO;

void SetLogLevel(ENUM_LOG_LEVEL level) { g_LogLevel = level; }

string LogLevelStr(ENUM_LOG_LEVEL lvl)
{
   switch(lvl)
   {
      case LOG_DEBUG:   return "DEBUG";
      case LOG_INFO:    return "INFO";
      case LOG_WARNING: return "WARN";
      case LOG_ERROR:   return "ERROR";
   }
   return "?";
}

void LogMsg(ENUM_LOG_LEVEL lvl, string category, string msg)
{
   if(lvl < g_LogLevel) return;
   string line = StringFormat("[GotobiEA][%s][%s] %s", LogLevelStr(lvl), category, msg);
   Print(line);
   if(lvl >= LOG_WARNING) Alert(line);
}

#define LOG_DEBUG(cat, msg)   LogMsg(LOG_DEBUG, cat, msg)
#define LOG_INFO(cat, msg)    LogMsg(LOG_INFO,  cat, msg)
#define LOG_WARN(cat, msg)    LogMsg(LOG_WARNING, cat, msg)
#define LOG_ERROR(cat, msg)   LogMsg(LOG_ERROR, cat, msg)

//--- Format time info for logging (FR-1.6)
string FormatTimeInfo(datetime serverTime, int brokerGmtOffset)
{
   datetime utc = serverTime - (datetime)(brokerGmtOffset * 3600);
   datetime jst = utc + 32400; // JST = UTC+9
   return StringFormat("Srv=%s UTC=%s JST=%s GMTOffset=%+d",
      TimeToString(serverTime, TIME_DATE|TIME_SECONDS),
      TimeToString(utc,        TIME_DATE|TIME_SECONDS),
      TimeToString(jst,        TIME_DATE|TIME_SECONDS),
      brokerGmtOffset
   );
}

//--- Log entry event
void LogEntry(datetime serverTime, int brokerGmt, double bidFill, double slPrice,
              double lots, double riskMoney, double spread, string extra="")
{
   string timeStr = FormatTimeInfo(serverTime, brokerGmt);
   LOG_INFO("ENTRY", StringFormat(
      "SELL opened | %s | Bid=%.5f SL=%.5f Lots=%.2f Risk=%.2f Spread=%.1f pts %s",
      timeStr, bidFill, slPrice, lots, riskMoney, spread, extra
   ));
}

//--- Log exit event
void LogExit(datetime serverTime, int brokerGmt, double closePrice, double openPrice,
             double lots, string reason, double mae, double mfe)
{
   string timeStr = FormatTimeInfo(serverTime, brokerGmt);
   double pnlPips = (openPrice - closePrice) / SymbolInfoDouble(_Symbol, SYMBOL_POINT) / 10.0;
   LOG_INFO("EXIT", StringFormat(
      "SELL closed | %s | Close=%.5f Open=%.5f PnLpips=%.1f Lots=%.2f Reason=%s MAE=%.1fpips MFE=%.1fpips",
      timeStr, closePrice, openPrice, pnlPips, lots, reason, mae, mfe
   ));
}

//--- Log skip event
void LogSkip(string reason, datetime serverTime = 0, int brokerGmt = 0)
{
   if(serverTime > 0)
   {
      string timeStr = FormatTimeInfo(serverTime, brokerGmt);
      LOG_INFO("SKIP", StringFormat("%s | Reason: %s", timeStr, reason));
   }
   else
   {
      LOG_INFO("SKIP", reason);
   }
}

#endif // LOGGER_MQH
