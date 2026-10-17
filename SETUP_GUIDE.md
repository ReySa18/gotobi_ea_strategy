# Gotobi Fixing EA — Panduan Setup & Backtest

## Struktur File

```
D:\Proyek\GOTOBI_EA\
├── PRD.md                          <- Dokumen requirement
├── Experts\
│   └── GotobiFixingEA.mq5         <- EA UTAMA (copy ke MT5 Experts folder)
├── Include\
│   ├── JapanHolidays.mqh           <- Data libur Jepang 2015-2035
│   ├── TimeService.mqh             <- Konversi waktu & deteksi GMT
│   ├── GotobiCalendar.mqh          <- Resolver hari Gotobi
│   ├── RiskSizer.mqh               <- Kalkulasi lot & position sizing
│   └── Logger.mqh                  <- Logging & telemetri
└── Scripts\
    └── GotobiCalendarTest.mq5      <- Unit test (jalankan sebagai Script)
```

## Langkah 1: Instalasi ke MetaTrader 5

### Copy File ke MT5

1. Buka MetaEditor (F4 dari MT5), lalu buka **File -> Open Data Folder**
2. Copy file-file berikut:
   - `GotobiFixingEA.mq5` -> `MQL5\Experts\`
   - Semua file di folder `Include\` -> `MQL5\Include\` (atau subfolder `GotobiEA\`)
   - `GotobiCalendarTest.mq5` -> `MQL5\Scripts\`

> **Tip**: Jika meletakkan Include di subfolder `MQL5\Include\GotobiEA\`, update `#include` di EA menjadi `#include <GotobiEA\JapanHolidays.mqh>` dst.

### Compile

1. Buka `GotobiFixingEA.mq5` di MetaEditor
2. Tekan **F7** (Compile)
3. Pastikan **0 errors, 0 warnings**

## Langkah 2: Jalankan Unit Test (AC-6)

1. Attach Script `GotobiCalendarTest` ke chart USDJPY mana saja
2. Buka tab **Experts** atau **Journal** untuk melihat hasil
3. Semua baris harus menampilkan `[PASS]`

## Langkah 3: Konfigurasi Strategy Tester

### Setting Umum

| Parameter | Nilai Rekomendasi |
|-----------|-------------------|
| Expert | GotobiFixingEA |
| Symbol | USDJPY (atau dengan suffix broker) |
| Period | M1 |
| Model | **Every tick based on real ticks** |
| Date From | 2020.01.01 |
| Date To | 2026.09.30 |
| Deposit | 10,000 USD |
| Leverage | 1:100 |
| Optimization | No (pertama kali) |

### Parameter EA di Tester

| Parameter | Nilai | Keterangan |
|-----------|-------|------------|
| `InpManualBrokerGmt` | 3 | Offset broker saat DST aktif |
| `InpTesterAutoDst` | true | **WAJIB** - auto GMT+2 di musim dingin |
| `InpDayMode` | GOTOBI_ONLY | Mode produksi |
| `InpRiskUsd` | 100 | Risiko per trade |
| `InpSlPercent` | 0.15 | Stop Loss 0.15% |
| `InpHoldMinutes` | 25 | Durasi hold 25 menit |
| `InpEntryHourJst` | 9 | Entry jam 9 JST |
| `InpEntryMinJst` | 55 | Entry menit 55 JST |
| `InpMaxSpreadPoints` | 20 | Filter spread |

## Langkah 4: Verifikasi Acceptance Criteria

### AC-1: Nol trade di hari non-Gotobi
- Buka tab Trades di hasil backtest
- Verifikasi semua tanggal entry adalah hari Gotobi (tanggal 5,10,15,20,25,30 atau pengganti)

### AC-2: Entry pukul 09:55 JST
- Di log Journal, cari baris `[GotobiEA][INFO][ENTRY]`
- Pastikan JST=... menunjukkan 09:55:xx
- Periksa periode musim panas dan musim dingin (DST vs non-DST)

### AC-3: Exit dalam 2 detik dari 10:20 JST
- Cari baris `[GotobiEA][INFO][EXIT]`
- Verifikasi waktu exit mendekati 10:20 JST

### AC-4: 100% trade memiliki SL
- Di tab Trades, kolom S/L tidak boleh kosong/0

### AC-5: Risiko riil tidak melebihi target
- Cek log: `Risk=xxx` harus <=100

### AC-6: Unit test resolver - lihat Langkah 2

### AC-7: Tidak ada posisi ganda
- Tab Open Trades tidak pernah menunjukkan lebih dari 1 posisi USDJPY

### AC-8: Recovery test
- Stop EA di tengah posisi terbuka
- Restart EA
- Verifikasi log menunjukkan "Recovery: found open position"
- Posisi ditutup tepat waktu, tidak ada posisi baru terbuka

## Langkah 5: Uji Riset (PRD Bagian 8)

### 5.1 Placebo Test
Jalankan backtest dengan `InpDayMode = NON_GOTOBI_PLACEBO` dengan semua parameter identik.
Jika hasil mirip -> yang terukur bukan efek Gotobi spesifik.

### 5.2 Sensitivitas Parameter
Gunakan fitur Optimization di Tester:

| Parameter | Min | Max | Step |
|-----------|-----|-----|------|
| `InpHoldMinutes` | 10 | 60 | 5 |
| `InpEntryMinJst` | 50 | 60 | 1 |
| `InpSlPercent` | 0.10 | 0.25 | 0.05 |

Cari **dataran stabil** (plateau), bukan satu puncak sempit. Jika hanya parameter 25 menit yang bagus, kemungkinan overfitting.

## Catatan Penting

### InpTesterAutoDst = true (KRITIS)
Tanpa ini, offset tetap GMT+3 di musim dingin di mana broker umumnya GMT+2.
Ini menggeser semua entry 1 jam pada sekitar 4 bulan data backtest.

### Model "Every tick based on real ticks"
Wajib untuk akurasi spread dan harga fill di strategi intraday.

### Data Quality
Download data tick USDJPY via Tools -> History Center sebelum backtest.

## Troubleshooting

| Masalah | Kemungkinan Penyebab | Solusi |
|---------|---------------------|--------|
| EA tidak compile | Path #include salah | Periksa path relatif file Include |
| Tidak ada trade sama sekali | Hari tidak Gotobi, atau data kosong | Cek log Journal |
| Entry jam salah (1 jam meleset) | InpTesterAutoDst=false | Aktifkan InpTesterAutoDst |
| Lot = 0 / skip | Akun terlalu kecil | Naikkan deposit atau aktifkan InpAllowMinLotOverRisk |
| Semua trade di-skip spread | InpMaxSpreadPoints terlalu kecil | Naikkan ke 30-50 untuk data historis lama |
| SL tidak terpasang | Broker tidak mendukung SL saat order | Periksa akun prop-firm/ECN |
