//+------------------------------------------------------------------+
//| JapanHolidays.mqh                                                |
//| Japan Public Holidays 2015–2035 (Cabinet Office of Japan)        |
//| Includes national holidays, substitute holidays, and bank        |
//| year-end holidays (Dec 31, Jan 2-3).                             |
//+------------------------------------------------------------------+
#ifndef JAPAN_HOLIDAYS_MQH
#define JAPAN_HOLIDAYS_MQH

// Holiday dates stored as YYYYMMDD integers for fast lookup
static const int JAPAN_HOLIDAYS[] =
{
   // 2015
   20150101, // New Year's Day
   20150102, // Bank holiday
   20150103, // Bank holiday
   20150112, // Coming-of-Age Day
   20150211, // National Foundation Day
   20150321, // Vernal Equinox Day
   20150429, // Showa Day
   20150503, // Constitution Day
   20150504, // Greenery Day
   20150505, // Children's Day
   20150720, // Marine Day
   20150922, // Autumnal Equinox Day
   20151012, // Health and Sports Day
   20151103, // Culture Day
   20151123, // Labor Thanksgiving Day
   20151223, // Emperor's Birthday
   20151231, // Bank holiday

   // 2016
   20160101, // New Year's Day
   20160102, // Bank holiday
   20160103, // Bank holiday
   20160111, // Coming-of-Age Day
   20160211, // National Foundation Day
   20160320, // Vernal Equinox Day
   20160321, // Substitute holiday (Vernal Equinox)
   20160429, // Showa Day
   20160503, // Constitution Day
   20160504, // Greenery Day
   20160505, // Children's Day
   20160718, // Marine Day
   20160811, // Mountain Day (new from 2016)
   20160919, // Respect for the Aged Day
   20160922, // Autumnal Equinox Day
   20161010, // Health and Sports Day
   20161103, // Culture Day
   20161123, // Labor Thanksgiving Day
   20161223, // Emperor's Birthday
   20161231, // Bank holiday

   // 2017
   20170101, // New Year's Day
   20170102, // Bank holiday
   20170103, // Bank holiday
   20170109, // Coming-of-Age Day
   20170211, // National Foundation Day
   20170320, // Vernal Equinox Day
   20170429, // Showa Day
   20170503, // Constitution Day
   20170504, // Greenery Day
   20170505, // Children's Day
   20170717, // Marine Day
   20170811, // Mountain Day
   20170918, // Respect for the Aged Day
   20170923, // Autumnal Equinox Day
   20171009, // Health and Sports Day
   20171103, // Culture Day
   20171123, // Labor Thanksgiving Day
   20171223, // Emperor's Birthday
   20171231, // Bank holiday

   // 2018
   20180101, // New Year's Day
   20180102, // Bank holiday
   20180103, // Bank holiday
   20180108, // Coming-of-Age Day
   20180211, // National Foundation Day
   20180212, // Substitute holiday
   20180321, // Vernal Equinox Day
   20180429, // Showa Day
   20180430, // Substitute holiday (Showa Day)
   20180503, // Constitution Day
   20180504, // Greenery Day
   20180505, // Children's Day
   20180716, // Marine Day
   20180811, // Mountain Day
   20180917, // Respect for the Aged Day
   20180923, // Autumnal Equinox Day
   20180924, // Substitute holiday
   20181008, // Health and Sports Day
   20181103, // Culture Day
   20181123, // Labor Thanksgiving Day
   20181224, // Substitute holiday (Emperor's Birthday)
   20181231, // Bank holiday

   // 2019
   20190101, // New Year's Day
   20190102, // Bank holiday
   20190103, // Bank holiday
   20190114, // Coming-of-Age Day
   20190211, // National Foundation Day
   20190321, // Vernal Equinox Day
   20190429, // Showa Day
   20190430, // Bridge holiday (Emperor abdication eve)
   20190501, // Emperor Enthronement Day
   20190502, // Bridge holiday
   20190503, // Constitution Day
   20190504, // Greenery Day
   20190505, // Children's Day
   20190506, // Substitute holiday
   20190715, // Marine Day
   20190811, // Mountain Day
   20190812, // Substitute holiday
   20190916, // Respect for the Aged Day
   20190923, // Autumnal Equinox Day
   20191014, // Sports Day (formerly Health and Sports Day)
   20191022, // Enthronement Ceremony Day (special)
   20191103, // Culture Day
   20191104, // Substitute holiday
   20191123, // Labor Thanksgiving Day
   20191231, // Bank holiday

   // 2020
   20200101, // New Year's Day
   20200102, // Bank holiday
   20200103, // Bank holiday
   20200113, // Coming-of-Age Day
   20200211, // National Foundation Day
   20200223, // Emperor's Birthday (new)
   20200324, // Vernal Equinox Day (moved for Olympics, then back)
   20200429, // Showa Day
   20200503, // Constitution Day
   20200504, // Greenery Day
   20200505, // Children's Day
   20200506, // Substitute holiday
   20200720, // Marine Day (moved from Olympics schedule)
   20200810, // Mountain Day (moved from Olympics schedule)
   20200921, // Respect for the Aged Day
   20200922, // Substitute holiday
   20201001, // (Olympics moved) Sports Day
   20201103, // Culture Day
   20201123, // Labor Thanksgiving Day
   20201231, // Bank holiday

   // 2021
   20210101, // New Year's Day
   20210102, // Bank holiday
   20210103, // Bank holiday
   20210111, // Coming-of-Age Day
   20210211, // National Foundation Day
   20210223, // Emperor's Birthday
   20210320, // Vernal Equinox Day
   20210429, // Showa Day
   20210503, // Constitution Day
   20210504, // Greenery Day
   20210505, // Children's Day
   20210722, // Marine Day (moved for Olympics)
   20210723, // Sports Day (moved for Olympics)
   20210809, // Mountain Day (moved for Olympics)
   20210920, // Respect for the Aged Day
   20210923, // Autumnal Equinox Day
   20211103, // Culture Day
   20211123, // Labor Thanksgiving Day
   20211231, // Bank holiday

   // 2022
   20220101, // New Year's Day
   20220103, // Substitute holiday (New Year's Day)
   20220110, // Coming-of-Age Day
   20220211, // National Foundation Day
   20220223, // Emperor's Birthday
   20220321, // Vernal Equinox Day
   20220429, // Showa Day
   20220503, // Constitution Day
   20220504, // Greenery Day
   20220505, // Children's Day
   20220718, // Marine Day
   20220811, // Mountain Day
   20220919, // Respect for the Aged Day
   20220923, // Autumnal Equinox Day
   20221010, // Sports Day
   20221103, // Culture Day
   20221123, // Labor Thanksgiving Day
   20221231, // Bank holiday

   // 2023
   20230101, // New Year's Day
   20230102, // Bank holiday
   20230103, // Bank holiday
   20230109, // Coming-of-Age Day
   20230211, // National Foundation Day
   20230223, // Emperor's Birthday
   20230321, // Vernal Equinox Day
   20230429, // Showa Day
   20230503, // Constitution Day
   20230504, // Greenery Day
   20230505, // Children's Day
   20230717, // Marine Day
   20230811, // Mountain Day
   20230918, // Respect for the Aged Day
   20230923, // Autumnal Equinox Day
   20231009, // Sports Day
   20231103, // Culture Day
   20231123, // Labor Thanksgiving Day
   20231231, // Bank holiday

   // 2024
   20240101, // New Year's Day
   20240102, // Bank holiday
   20240103, // Bank holiday
   20240108, // Coming-of-Age Day
   20240211, // National Foundation Day
   20240212, // Substitute holiday
   20240223, // Emperor's Birthday
   20240320, // Vernal Equinox Day
   20240429, // Showa Day
   20240503, // Constitution Day
   20240504, // Greenery Day (Saturday)
   20240505, // Children's Day
   20240506, // Substitute holiday
   20240715, // Marine Day
   20240811, // Mountain Day
   20240812, // Substitute holiday
   20240916, // Respect for the Aged Day
   20240922, // Autumnal Equinox Day
   20240923, // Substitute holiday
   20241014, // Sports Day
   20241103, // Culture Day
   20241104, // Substitute holiday
   20241123, // Labor Thanksgiving Day
   20241231, // Bank holiday

   // 2025
   20250101, // New Year's Day
   20250102, // Bank holiday
   20250103, // Bank holiday
   20250113, // Coming-of-Age Day
   20250211, // National Foundation Day
   20250223, // Emperor's Birthday (Sunday)
   20250224, // Substitute holiday
   20250320, // Vernal Equinox Day
   20250429, // Showa Day
   20250503, // Constitution Day
   20250504, // Greenery Day
   20250505, // Children's Day
   20250506, // Substitute holiday
   20250721, // Marine Day
   20250811, // Mountain Day
   20250915, // Respect for the Aged Day
   20250923, // Autumnal Equinox Day
   20251013, // Sports Day
   20251103, // Culture Day
   20251123, // Labor Thanksgiving Day (Sunday)
   20251124, // Substitute holiday
   20251231, // Bank holiday

   // 2026
   20260101, // New Year's Day
   20260102, // Bank holiday
   20260103, // Bank holiday
   20260112, // Coming-of-Age Day
   20260211, // National Foundation Day
   20260223, // Emperor's Birthday
   20260320, // Vernal Equinox Day
   20260429, // Showa Day
   20260503, // Constitution Day
   20260504, // Greenery Day
   20260505, // Children's Day
   20260720, // Marine Day
   20260811, // Mountain Day
   20260921, // Respect for the Aged Day
   20260922, // Autumnal Equinox Day
   20261012, // Sports Day
   20261103, // Culture Day
   20261123, // Labor Thanksgiving Day
   20261231, // Bank holiday

   // 2027
   20270101, // New Year's Day
   20270102, // Bank holiday
   20270103, // Bank holiday
   20270111, // Coming-of-Age Day
   20270211, // National Foundation Day
   20270223, // Emperor's Birthday
   20270322, // Vernal Equinox Day
   20270429, // Showa Day
   20270503, // Constitution Day
   20270504, // Greenery Day
   20270505, // Children's Day
   20270719, // Marine Day
   20270811, // Mountain Day
   20270920, // Respect for the Aged Day
   20270923, // Autumnal Equinox Day
   20271011, // Sports Day
   20271103, // Culture Day
   20271123, // Labor Thanksgiving Day
   20271231, // Bank holiday

   // 2028
   20280101, // New Year's Day
   20280102, // Bank holiday
   20280103, // Bank holiday
   20280110, // Coming-of-Age Day
   20280211, // National Foundation Day
   20280223, // Emperor's Birthday
   20280320, // Vernal Equinox Day
   20280429, // Showa Day
   20280503, // Constitution Day
   20280504, // Greenery Day
   20280505, // Children's Day
   20280717, // Marine Day
   20280811, // Mountain Day
   20280918, // Respect for the Aged Day
   20280923, // Autumnal Equinox Day
   20281009, // Sports Day
   20281103, // Culture Day
   20281123, // Labor Thanksgiving Day
   20281231, // Bank holiday

   // 2029
   20290101, // New Year's Day
   20290102, // Bank holiday
   20290103, // Bank holiday
   20290108, // Coming-of-Age Day
   20290211, // National Foundation Day
   20290223, // Emperor's Birthday
   20290320, // Vernal Equinox Day
   20290429, // Showa Day (Sunday)
   20290430, // Substitute holiday
   20290503, // Constitution Day
   20290504, // Greenery Day
   20290505, // Children's Day
   20290716, // Marine Day
   20290811, // Mountain Day (Sunday)
   20290812, // Substitute holiday
   20290917, // Respect for the Aged Day
   20290923, // Autumnal Equinox Day (Sunday)
   20290924, // Substitute holiday
   20291008, // Sports Day
   20291103, // Culture Day (Sunday)
   20291104, // Substitute holiday
   20291123, // Labor Thanksgiving Day
   20291231, // Bank holiday

   // 2030
   20300101, // New Year's Day
   20300102, // Bank holiday
   20300103, // Bank holiday
   20300114, // Coming-of-Age Day
   20300211, // National Foundation Day
   20300223, // Emperor's Birthday
   20300320, // Vernal Equinox Day
   20300429, // Showa Day
   20300503, // Constitution Day
   20300504, // Greenery Day (Saturday)
   20300505, // Children's Day (Sunday)
   20300506, // Substitute holiday
   20300715, // Marine Day
   20300811, // Mountain Day (Sunday)
   20300812, // Substitute holiday
   20300916, // Respect for the Aged Day
   20300923, // Autumnal Equinox Day
   20301014, // Sports Day
   20301103, // Culture Day (Sunday)
   20301104, // Substitute holiday
   20301123, // Labor Thanksgiving Day
   20301231, // Bank holiday

   // 2031
   20310101, // New Year's Day
   20310102, // Bank holiday
   20310103, // Bank holiday
   20310113, // Coming-of-Age Day
   20310211, // National Foundation Day
   20310223, // Emperor's Birthday (Sunday)
   20310224, // Substitute holiday
   20310320, // Vernal Equinox Day
   20310429, // Showa Day
   20310503, // Constitution Day
   20310504, // Greenery Day (Sunday)
   20310505, // Children's Day
   20310506, // Substitute holiday
   20310721, // Marine Day
   20310811, // Mountain Day
   20310915, // Respect for the Aged Day
   20310923, // Autumnal Equinox Day
   20311013, // Sports Day
   20311103, // Culture Day
   20311123, // Labor Thanksgiving Day (Sunday)
   20311124, // Substitute holiday
   20311231, // Bank holiday

   // 2032
   20320101, // New Year's Day
   20320102, // Bank holiday
   20320103, // Bank holiday (Saturday - adjust for bank holiday)
   20320112, // Coming-of-Age Day
   20320211, // National Foundation Day
   20320223, // Emperor's Birthday
   20320320, // Vernal Equinox Day (Saturday)
   20320321, // Substitute holiday
   20320429, // Showa Day
   20320503, // Constitution Day (Sunday)
   20320504, // Greenery Day
   20320505, // Children's Day
   20320506, // Substitute holiday
   20320719, // Marine Day
   20320811, // Mountain Day
   20320920, // Respect for the Aged Day
   20320921, // Autumnal Equinox Day (Tuesday)
   20321011, // Sports Day
   20321103, // Culture Day
   20321123, // Labor Thanksgiving Day
   20321231, // Bank holiday

   // 2033
   20330101, // New Year's Day (Saturday)
   20330103, // Substitute holiday
   20330110, // Coming-of-Age Day
   20330211, // National Foundation Day
   20330223, // Emperor's Birthday
   20330321, // Vernal Equinox Day
   20330429, // Showa Day
   20330503, // Constitution Day
   20330504, // Greenery Day
   20330505, // Children's Day
   20330718, // Marine Day
   20330811, // Mountain Day
   20330919, // Respect for the Aged Day
   20330923, // Autumnal Equinox Day
   20331010, // Sports Day
   20331103, // Culture Day
   20331123, // Labor Thanksgiving Day
   20331231, // Bank holiday

   // 2034
   20340101, // New Year's Day
   20340102, // Bank holiday
   20340103, // Bank holiday
   20340109, // Coming-of-Age Day
   20340211, // National Foundation Day
   20340212, // Substitute holiday
   20340223, // Emperor's Birthday
   20340320, // Vernal Equinox Day
   20340429, // Showa Day (Saturday)
   20340430, // Substitute holiday
   20340503, // Constitution Day
   20340504, // Greenery Day
   20340505, // Children's Day
   20340506, // Substitute holiday
   20340717, // Marine Day
   20340811, // Mountain Day
   20340918, // Respect for the Aged Day
   20340923, // Autumnal Equinox Day (Saturday)
   20340924, // Substitute holiday
   20341009, // Sports Day
   20341103, // Culture Day
   20341123, // Labor Thanksgiving Day
   20341231, // Bank holiday

   // 2035
   20350101, // New Year's Day
   20350102, // Bank holiday
   20350103, // Bank holiday
   20350108, // Coming-of-Age Day
   20350211, // National Foundation Day
   20350223, // Emperor's Birthday
   20350321, // Vernal Equinox Day
   20350429, // Showa Day
   20350503, // Constitution Day
   20350504, // Greenery Day
   20350505, // Children's Day
   20350506, // Substitute holiday (Children's Day Sunday)
   20350716, // Marine Day
   20350811, // Mountain Day
   20350917, // Respect for the Aged Day
   20350923, // Autumnal Equinox Day
   20351008, // Sports Day
   20351103, // Culture Day
   20351104, // Substitute holiday
   20351123, // Labor Thanksgiving Day (Saturday)
   20351124, // Substitute holiday
   20351231, // Bank holiday
};

static const int JAPAN_HOLIDAYS_COUNT = ArraySize(JAPAN_HOLIDAYS);

//--- Check if a given MQL5 datetime is a Japan public holiday
bool IsJapanHoliday(datetime dtUtc)
{
   MqlDateTime st;
   TimeToStruct(dtUtc, st);
   int key = st.year * 10000 + (st.mon) * 100 + st.day;
   for(int i = 0; i < JAPAN_HOLIDAYS_COUNT; i++)
   {
      if(JAPAN_HOLIDAYS[i] == key) return true;
   }
   return false;
}

//--- Check if date (as YYYYMMDD int) is a Japan public holiday
bool IsJapanHolidayByInt(int yyyymmdd)
{
   for(int i = 0; i < JAPAN_HOLIDAYS_COUNT; i++)
   {
      if(JAPAN_HOLIDAYS[i] == yyyymmdd) return true;
   }
   return false;
}

#endif // JAPAN_HOLIDAYS_MQH
