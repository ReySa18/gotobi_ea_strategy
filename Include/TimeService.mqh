//+------------------------------------------------------------------+
//| TimeService.mqh                                                  |
//| Handles broker offset detection, JST conversion, DST logic      |
//+------------------------------------------------------------------+
#ifndef TIME_SERVICE_MQH
#define TIME_SERVICE_MQH

//--- JST = UTC+9, no DST
#define JST_OFFSET_SEC  32400   // 9 * 3600

//--- US DST: 2nd Sunday March → 1st Sunday November
bool IsUsDstActive(datetime dtUtc)
{
   MqlDateTime st;
   TimeToStruct(dtUtc, st);
   int year  = st.year;
   int month = st.mon;
   int day   = st.day;

   if(month < 3 || month > 11) return false;
   if(month > 3 && month < 11) return true;

   if(month == 3)
   {
      // 2nd Sunday of March
      // Find day-of-week for March 1
      MqlDateTime tmp; datetime d1 = (datetime)StringToTime(IntegerToString(year)+".03.01 00:00:00");
      TimeToStruct(d1, tmp);
      int dow = tmp.day_of_week; // 0=Sun
      int firstSun = (dow == 0) ? 1 : (8 - dow);
      int secondSun = firstSun + 7;
      return (day >= secondSun);
   }
   // month == 11
   // 1st Sunday of November
   datetime d1 = (datetime)StringToTime(IntegerToString(year)+".11.01 00:00:00");
   MqlDateTime tmp;
   TimeToStruct(d1, tmp);
   int dow = tmp.day_of_week;
   int firstSun = (dow == 0) ? 1 : (8 - dow);
   return (day < firstSun);
}

//--- Compute effective broker GMT offset for tester (with auto-DST)
int GetTesterBrokerOffset(datetime dtUtc, int inpManualGmt, bool autoDst)
{
   if(!autoDst) return inpManualGmt;
   if(IsUsDstActive(dtUtc))
      return inpManualGmt;       // DST period: use configured value (e.g. 3)
   else
      return inpManualGmt - 1;   // Winter: GMT+2 (one hour less)
}

//--- Convert server time → JST
//    Params: serverTime, brokerGmtOffset (hours)
datetime ServerToJst(datetime serverTime, int brokerGmtOffsetHours)
{
   datetime utc = serverTime - (datetime)(brokerGmtOffsetHours * 3600);
   return utc + JST_OFFSET_SEC;
}

//--- Convert JST → server time
datetime JstToServer(datetime jstTime, int brokerGmtOffsetHours)
{
   datetime utc = jstTime - JST_OFFSET_SEC;
   return utc + (datetime)(brokerGmtOffsetHours * 3600);
}

//--- Detect live broker GMT offset from TimeTradeServer() and TimeGMT()
//    Returns INT_MIN on failure
int DetectLiveBrokerOffset()
{
   datetime srv = TimeTradeServer();
   datetime gmt = TimeGMT();
   if(srv == 0 || gmt == 0) return INT_MIN;
   long diffSec = (long)srv - (long)gmt;
   long hours = diffSec / 3600;
   long rem   = diffSec % 3600;
   // Validate: must be integer hours
   if(rem < -60 && rem > 60) return INT_MIN;
   // Validate: reasonable forex broker range [-3, +5] (including DST variants)
   if(hours < -3 || hours > 5) return INT_MIN;
   return (int)hours;
}

//--- Validate the offset from DetectLiveBrokerOffset
bool IsOffsetValid(int offset)
{
   if(offset == INT_MIN) return false;
   if(offset < -3 || offset > 5) return false;
   return true;
}

#endif // TIME_SERVICE_MQH
