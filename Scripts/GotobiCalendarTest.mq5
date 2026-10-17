//+------------------------------------------------------------------+
//| GotobiCalendarTest.mq5                                           |
//| Unit test script for Gotobi resolver and time conversion         |
//| Run as Script in MetaTrader 5 (not as EA)                        |
//+------------------------------------------------------------------+
#property script_show_inputs
#property strict

#include "..\Include\JapanHolidays.mqh"
#include "..\Include\TimeService.mqh"
#include "..\Include\GotobiCalendar.mqh"

//--- Test result accumulator
int g_Pass = 0;
int g_Fail = 0;

void Assert(bool cond, string testName, string detail="")
{
   if(cond)
   {
      g_Pass++;
      PrintFormat("[PASS] %s %s", testName, detail);
   }
   else
   {
      g_Fail++;
      PrintFormat("[FAIL] %s %s", testName, detail);
   }
}

//--- Expect YYYYMMDD resolved from given year/month candidate set
void TestGotobiDates(int year, int month, int expectFirst, string desc)
{
   int dates[6];
   int count = GetGotobiDates(year, month, dates, 6);
   bool found = false;
   for(int i = 0; i < count; i++)
      if(dates[i] == expectFirst) { found = true; break; }

   string allDates = "";
   for(int i = 0; i < count; i++)
      allDates += IntegerToString(dates[i]) + " ";

   Assert(found, StringFormat("Gotobi %04d/%02d first=%d", year, month, expectFirst),
      StringFormat("expect %d, got [%s] %s", expectFirst, allDates, desc));
}

void TestIsGotobiDay(int yyyymmdd, bool expected, string desc)
{
   bool result = IsGotobiDay(yyyymmdd);
   Assert(result == expected, StringFormat("IsGotobiDay(%d)=%s", yyyymmdd, expected ? "Y" : "N"), desc);
}

void TestIsWorkingDay(int yyyymmdd, bool expected, string desc)
{
   bool result = IsWorkingDay(yyyymmdd);
   Assert(result == expected, StringFormat("IsWorkingDay(%d)=%s", yyyymmdd, expected ? "Y" : "N"), desc);
}

void TestJapanHoliday(int yyyymmdd, bool expected, string desc)
{
   bool result = IsJapanHolidayByInt(yyyymmdd);
   Assert(result == expected, StringFormat("JapanHoliday(%d)=%s", yyyymmdd, expected ? "Y" : "N"), desc);
}

void TestServerToJst(int gmtOffset, datetime serverTime, datetime expectedJst, string desc)
{
   datetime got = ServerToJst(serverTime, gmtOffset);
   bool ok = (got == expectedJst);
   Assert(ok, StringFormat("ServerToJst(GMT%+d)", gmtOffset),
      StringFormat("%s | srv=%s expected=%s got=%s",
         desc,
         TimeToString(serverTime, TIME_DATE|TIME_SECONDS),
         TimeToString(expectedJst, TIME_DATE|TIME_SECONDS),
         TimeToString(got,         TIME_DATE|TIME_SECONDS)));
}

void TestUsDst(datetime utcTime, bool expectedDst, string desc)
{
   bool got = IsUsDstActive(utcTime);
   Assert(got == expectedDst, StringFormat("UsDST(%s)=%s", TimeToString(utcTime, TIME_DATE), expectedDst?"ON":"OFF"), desc);
}

void OnStart()
{
   PrintFormat("=== GotobiEA Calendar Unit Tests ===");
   PrintFormat("Running tests...");

   //--------------------------------------------------------------------
   // Japan Holiday Tests
   //--------------------------------------------------------------------
   TestJapanHoliday(20260101, true,  "New Year 2026");
   TestJapanHoliday(20260429, true,  "Showa Day 2026");
   TestJapanHoliday(20260503, true,  "Constitution Day 2026");
   TestJapanHoliday(20260504, true,  "Greenery Day 2026");
   TestJapanHoliday(20260505, true,  "Children's Day 2026");
   TestJapanHoliday(20261231, true,  "Bank year-end 2026");
   TestJapanHoliday(20260102, true,  "Bank holiday Jan 2 2026");
   TestJapanHoliday(20260103, true,  "Bank holiday Jan 3 2026");

   // Non-holidays
   TestJapanHoliday(20260401, false, "Normal working day April 1 2026");
   TestJapanHoliday(20260601, false, "Normal working day June 1 2026");

   //--------------------------------------------------------------------
   // Working Day Tests
   //--------------------------------------------------------------------
   TestIsWorkingDay(20260119, true,  "Monday Jan 19 2026 (Jan 12 = Coming-of-Age Day holiday)");  // Mon, no holiday
   TestIsWorkingDay(20260110, false, "Sat Jan 10 2026");     // Saturday
   TestIsWorkingDay(20260111, false, "Sun Jan 11 2026");     // Sunday
   TestIsWorkingDay(20260101, false, "New Year 2026");       // Holiday
   TestIsWorkingDay(20260429, false, "Showa Day 2026");      // Holiday
   TestIsWorkingDay(20260503, false, "Constitution Day 2026"); // Holiday

   //--------------------------------------------------------------------
   // Gotobi Resolver Tests
   //--------------------------------------------------------------------

   // Standard cases
   // Feb 2026: 28 Feb is Sat → roll to Fri 27 Feb
   TestIsWorkingDay(20260227, true, "2026-02-27 should be working (Fri)");
   TestIsWorkingDay(20260228, false, "2026-02-28 should NOT be working (Sat)");

   // Feb 2026 - candidate 30: use last working day of February
   TestGotobiDates(2026, 2, 20260205, "2026/02 - 5th should be Thursday");
   TestGotobiDates(2026, 2, 20260210, "2026/02 - 10th should be Tuesday");
   TestGotobiDates(2026, 2, 20260220, "2026/02 - 20th should be Friday");
   TestGotobiDates(2026, 2, 20260225, "2026/02 - 25th should be Wednesday");
   TestGotobiDates(2026, 2, 20260227, "2026/02 - 28th→27th (Sat roll to Fri)");

   // May 2026: Golden Week
   // May 3,4,5 = Constitution/Greenery/Children's Day
   // May 5 candidate: is holiday, roll to May 4 (holiday), roll to May 1 (Fri)
   TestGotobiDates(2026, 5, 20260501, "2026/05 - May 5 Golden Week roll to May 1");

   // December 25 (broker holiday — skip, not move)
   TestIsGotobiDay(20261225, false, "Dec 25 broker holiday - not Gotobi");

   // Deduplication test — in a month where two candidates roll to same day
   // Build month data and check count
   {
      int dates[6];
      int count = GetGotobiDates(2026, 2, dates, 6);
      // Feb 2026 candidates: 5,10,15,20,25,30
      // 30 and 28(Sat→27Fri) could both go to 27 if 25 and 27 differ
      // 15: Mon, 25: Wed, 30 → last WD of Feb = 27
      // 28 (30 candidate) → 27, 25 stays 25. So no dup expected
      // But 20 is Fri, 15 is Mon → all distinct
      PrintFormat("[INFO] Feb 2026 Gotobi count=%d", count);
      bool noDups = true;
      for(int i = 0; i < count; i++)
         for(int j = i+1; j < count; j++)
            if(dates[i] == dates[j]) { noDups = false; break; }
      Assert(noDups, "Feb 2026 Gotobi no duplicates");
   }

   // AC-6: Specific known dates
   TestIsGotobiDay(20261225, false, "AC-6: Dec 25 not Gotobi (broker holiday)");
   TestIsGotobiDay(20260101, false, "AC-6: Jan 1 not Gotobi (Japan holiday)");

   //--------------------------------------------------------------------
   // Time Conversion Tests
   //--------------------------------------------------------------------

   // GMT+3 broker: server 02:55 = JST 09:55 when UTC+3 → UTC = server-3h = 23:55, JST = UTC+9 = 08:55?
   // Wait: if broker is GMT+3, then:
   //   UTC = server - 3h
   //   JST = UTC + 9h = server - 3 + 9 = server + 6h
   // So server 03:55:00 → JST 09:55:00 (for GMT+3)
   {
      // 2026-10-07 03:55:00 server (GMT+3) → JST should be 09:55:00
      datetime srv  = (datetime)StringToTime("2026.10.07 03:55:00");
      datetime expJst = (datetime)StringToTime("2026.10.07 09:55:00");
      TestServerToJst(3, srv, expJst, "GMT+3 server 03:55 → JST 09:55");
   }
   {
      // GMT+2: server 02:55 → JST 09:55
      datetime srv  = (datetime)StringToTime("2026.10.07 02:55:00");
      datetime expJst = (datetime)StringToTime("2026.10.07 09:55:00");
      TestServerToJst(2, srv, expJst, "GMT+2 server 02:55 → JST 09:55");
   }

   //--------------------------------------------------------------------
   // US DST Tests
   //--------------------------------------------------------------------
   // DST 2026: starts 2nd Sun March (March 8) → ends 1st Sun Nov (Nov 1)
   TestUsDst((datetime)StringToTime("2026.01.15 12:00"), false, "Jan = no DST");
   TestUsDst((datetime)StringToTime("2026.03.07 12:00"), false, "Before 2nd Sun March");
   TestUsDst((datetime)StringToTime("2026.03.08 12:00"), true,  "2nd Sun March = DST start");
   TestUsDst((datetime)StringToTime("2026.06.01 12:00"), true,  "June = DST active");
   TestUsDst((datetime)StringToTime("2026.11.01 12:00"), false, "1st Sun Nov = DST end");
   TestUsDst((datetime)StringToTime("2026.12.01 12:00"), false, "December = no DST");

   // Tester offset with AutoDST
   {
      datetime utcSummer = (datetime)StringToTime("2026.06.01 00:00");
      int off = GetTesterBrokerOffset(utcSummer, 3, true);
      Assert(off == 3, "TesterOffset summer DST=ON → GMT+3");
   }
   {
      datetime utcWinter = (datetime)StringToTime("2026.01.15 00:00");
      int off = GetTesterBrokerOffset(utcWinter, 3, true);
      Assert(off == 2, "TesterOffset winter DST=OFF → GMT+2");
   }

   //--------------------------------------------------------------------
   // Results
   //--------------------------------------------------------------------
   PrintFormat("=== TEST RESULTS ===");
   PrintFormat("PASS: %d", g_Pass);
   PrintFormat("FAIL: %d", g_Fail);
   PrintFormat("TOTAL: %d", g_Pass + g_Fail);
   if(g_Fail == 0)
      PrintFormat(">>> ALL TESTS PASSED <<<");
   else
      PrintFormat(">>> %d TESTS FAILED — review above <<<", g_Fail);
}
