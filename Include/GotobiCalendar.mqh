//+------------------------------------------------------------------+
//| GotobiCalendar.mqh                                               |
//| FR-2: Gotobi day resolver                                        |
//+------------------------------------------------------------------+
#ifndef GOTOBI_CALENDAR_MQH
#define GOTOBI_CALENDAR_MQH

#include "JapanHolidays.mqh"

//--- Broker holiday (exchange closed): Dec 25, Jan 1
bool IsBrokerHoliday(int yyyymmdd)
{
   int mmdd = yyyymmdd % 10000;
   return (mmdd == 1225 || mmdd == 101);
}

//--- Day of week: 0=Sun,1=Mon,...,6=Sat
//    Uses datetime struct
int DayOfWeekForDate(int year, int month, int day)
{
   datetime dt = (datetime)StringToTime(
      StringFormat("%04d.%02d.%02d 00:00:00", year, month, day)
   );
   MqlDateTime st;
   TimeToStruct(dt, st);
   return st.day_of_week;
}

//--- Is a given YYYYMMDD a working day (Mon-Fri, not Japan holiday, not broker holiday)
bool IsWorkingDay(int yyyymmdd)
{
   int year  = yyyymmdd / 10000;
   int month = (yyyymmdd / 100) % 100;
   int day   = yyyymmdd % 100;
   int dow   = DayOfWeekForDate(year, month, day);
   if(dow == 0 || dow == 6) return false;          // Saturday/Sunday
   if(IsJapanHolidayByInt(yyyymmdd)) return false; // Japan holiday
   // Note: broker holidays (Dec25, Jan1) are excluded from Gotobi but not "moved" (FR-2.7)
   return true;
}

//--- Days in month (leap year aware)
int DaysInMonth(int year, int month)
{
   if(month == 2)
   {
      bool leap = (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0));
      return leap ? 29 : 28;
   }
   static const int dim[] = {0,31,28,31,30,31,30,31,31,30,31,30,31};
   return dim[month];
}

//--- Roll candidate backward until working day, returns YYYYMMDD
//    Returns 0 if no working day found in the same month
int RollBackToWorkingDay(int year, int month, int day)
{
   for(int d = day; d >= 1; d--)
   {
      int yyyymmdd = year * 10000 + month * 100 + d;
      if(IsWorkingDay(yyyymmdd)) return yyyymmdd;
   }
   return 0;
}

//--- Get last working day of month
int LastWorkingDayOfMonth(int year, int month)
{
   int lastDay = DaysInMonth(year, month);
   return RollBackToWorkingDay(year, month, lastDay);
}

//--- FR-2: Build deduplicated list of Gotobi dates for a given year/month
//    Candidates: 5, 10, 15, 20, 25, 30
//    Returns count; dates[] filled with YYYYMMDD sorted ascending
int GetGotobiDates(int year, int month, int &dates[], int maxSize)
{
   static const int CANDIDATES[] = {5, 10, 15, 20, 25, 30};
   int count = 0;
   int dim = DaysInMonth(year, month);

   for(int i = 0; i < 6; i++)
   {
      int cand = CANDIDATES[i];
      int resolved = 0;

      if(cand > dim)
      {
         // e.g. Feb 30, or any month without 30/31
         if(month == 2 && cand >= 29)
         {
            // Use last working day of February
            resolved = LastWorkingDayOfMonth(year, month);
         }
         else
         {
            // Candidate doesn't exist in this month and it's not Feb special case
            // (Only 30 is a candidate, months with <30 days are: Feb only for practical purposes)
            // For safety, use last working day of month
            resolved = LastWorkingDayOfMonth(year, month);
         }
      }
      else
      {
         int yyyymmdd = year * 10000 + month * 100 + cand;
         if(IsWorkingDay(yyyymmdd))
         {
            resolved = yyyymmdd;
         }
         else
         {
            // Roll back iteratively (FR-2.3)
            resolved = RollBackToWorkingDay(year, month, cand - 1);
         }
      }

      if(resolved == 0) continue;

      // FR-2.7: Broker holidays → skip entirely (not move)
      if(IsBrokerHoliday(resolved)) continue;

      // Deduplication (FR-2.6)
      bool dup = false;
      for(int j = 0; j < count; j++)
      {
         if(dates[j] == resolved) { dup = true; break; }
      }
      if(!dup && count < maxSize)
      {
         dates[count++] = resolved;
      }
   }
   return count;
}

//--- Check if a given JST date (YYYYMMDD) is a Gotobi day
bool IsGotobiDay(int yyyymmdd)
{
   int year  = yyyymmdd / 10000;
   int month = (yyyymmdd / 100) % 100;
   int dates[6];
   int count = GetGotobiDates(year, month, dates, 6);
   for(int i = 0; i < count; i++)
   {
      if(dates[i] == yyyymmdd) return true;
   }
   return false;
}

//--- Check if a given JST date is a non-Gotobi regular working day
bool IsNonGotobiWorkingDay(int yyyymmdd)
{
   if(!IsWorkingDay(yyyymmdd)) return false;
   if(IsBrokerHoliday(yyyymmdd)) return false;
   return !IsGotobiDay(yyyymmdd);
}

#endif // GOTOBI_CALENDAR_MQH
