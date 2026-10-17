# PRD — Gotobi USDJPY Fixing EA (MetaTrader 5)

Versi 0.1 (draft untuk review) · Pemilik produk: Reymondo · 17 Oktober 2026

## 1. Ringkasan dan Tujuan

Expert Advisor (EA) MT5 yang menjalankan satu strategi kalender intraday: **SELL USDJPY pada fixing Tokyo 09:55 JST di hari Gotobi, ditutup oleh waktu 25 menit kemudian**, dengan Stop Loss 0,15% dari harga masuk dan tanpa Take Profit.

**Tujuan v0.1**

1. Mengeksekusi aturan strategi secara deterministik, identik di Live/Demo dan Strategy Tester.
2. Menjadi alat riset: semua parameter kunci (jam masuk, durasi hold, SL) dapat diuji sensitivitasnya.
3. Menjaga modal: risiko per trade terkontrol, tidak ada martingale, grid, atau averaging.

**Bukan tujuan v0.1**: news filter (ditunda), multi-pair, optimasi otomatis, UI panel kustom di luar input standar MT5.

**Konteks kepastian**: efek Gotobi adalah hipotesis praktisi. Durasi hold 25 menit berasal dari praktik, bukan jurnal, dan belum ada riwayat performa karena ini pengembangan pertama. Seluruh klaim edge berstatus **spekulasi** sampai lolos validasi pada bagian 8.

## 2. Ruang Lingkup

| Masuk (In scope) | Keluar (Out of scope) |
| --- | --- |
| USDJPY saja (mendukung suffix simbol broker) | Pair lain (EURJPY dll.) |
| Satu posisi, satu trade per hari Gotobi | Multi-posisi, scaling in/out |
| Time-exit, SL server-side | Take Profit, trailing, breakeven, partial close |
| Sizing berbasis risiko dan ukuran akun dari input | News filter (v1.1) |
| Mode riset (Gotobi, placebo non-Gotobi) | Optimasi otomatis, machine learning |
| Logging lengkap | Dashboard di luar panel input |

## 3. Spesifikasi Aturan Strategi

| Komponen | Aturan |
| --- | --- |
| Hari | Tanggal 5, 10, 15, 20, 25, 30. Jika jatuh pada Sabtu, Minggu, atau libur Jepang, mundur ke hari kerja sebelumnya |
| Tanggal 30 di Februari | Pakai **hari kerja terakhir bulan Februari** |
| Entry | Market SELL pada tick pertama ≥ 09:55:00 JST |
| Exit | Tutup posisi pada 10:20:00 JST (entry + 25 menit) |
| Setara jam broker | 02:55 → 03:20 (broker GMT+2) atau 03:55 → 04:20 (broker GMT+3) |
| Stop Loss | Harga masuk × (1 + 0,15%) |
| Take Profit | Tidak ada |
| Risiko | $100 per trade (lot dihitung agar rugi di SL = $100), dapat diubah dari input |
| Libur | Libur Jepang (tidak ada fixing) dan hari broker tutup (25 Des, 1 Jan): tidak trading |
| Posisi | Maksimal satu, dijalankan lurus sesuai strategi, baik sedang rugi maupun untung |

## 4. Requirement Fungsional

### FR-1 Manajemen Waktu dan Sesi Jepang

Zona Jepang: JST = UTC+9, tanpa DST. Rantai konversi: `waktu server → UTC (dikurangi offset broker) → JST (ditambah 9 jam)`.

- **FR-1.1** EA mengidentifikasi sesi Tokyo dengan rentang default **09:00 sampai 15:00 JST**, dapat diubah lewat input.
- **FR-1.2** Filter sesi dikontrol boolean `InpUseTimeFilter` (true = entry hanya valid di dalam sesi; false = filter dimatikan). Filter sesi **tidak pernah memblokir exit**.
- **FR-1.3 Mode Live/Demo**: offset broker dideteksi dinamis dari selisih `TimeTradeServer()` dan `TimeGMT()`, dibulatkan ke jam penuh terdekat. Offset dihitung ulang saat start, di setiap hari baru server, dan 5 menit sebelum jendela entry.
- **FR-1.4 Mode Strategy Tester**: jika `MqlInfoInteger(MQL_TESTER)` bernilai true, EA memakai input manual `InpManualBrokerGmt` (default: 3), tidak memakai `TimeGMT()`.
- **FR-1.5 Validasi offset (Live)**: offset harus bilangan jam bulat dan berada pada rentang wajar. Jika tidak lolos, **entry diblokir** dan peringatan dicatat (fail-safe). Opsi `InpLiveFallbackToManual` (default false) mengizinkan fallback ke input manual.
- **FR-1.6 Logging waktu**: setiap entry dan exit mencatat waktu server, UTC, JST, dan offset yang dipakai, untuk audit.

**Catatan teknis penting (perlu keputusan Anda, lihat bagian 10)**

1. `TimeGMT()` diturunkan dari jam lokal PC/VPS beserta zona waktu dan DST sistemnya. Jadi deteksi live **masih bergantung pada akurasi jam PC/VPS** (wajib tersinkron NTP), tidak sepenuhnya bebas dari jam lokal. Validasi pada FR-1.5 adalah mitigasinya.
2. Offset tetap 3 hanya benar saat broker berada pada periode DST AS (kira-kira Maret sampai November). Di musim dingin, broker umumnya GMT+2, sehingga offset tetap 3 membuat semua trade geser **1 jam** pada sekitar 4 bulan data backtest. Usulan: tambahkan `InpTesterAutoDst` (default true). Jika aktif, offset = `InpManualBrokerGmt` selama periode DST AS (Minggu ke-2 Maret sampai Minggu ke-1 November) dan `InpManualBrokerGmt − 1` di luar periode itu. Jika dimatikan, perilaku persis seperti spesifikasi awal (offset tetap).

### FR-2 Resolver Hari Gotobi

- **FR-2.1** Kandidat tiap bulan: 5, 10, 15, 20, 25, 30.
- **FR-2.2** Hari kerja = Senin sampai Jumat, bukan libur Jepang (dari tabel libur, FR-2.5).
- **FR-2.3** Kandidat yang bukan hari kerja dimundurkan **secara iteratif** ke hari kerja sebelumnya (libur berantai seperti Golden Week harus tertangani).
- **FR-2.4** Tanggal 30 pada Februari (tidak ada) diganti hari kerja terakhir bulan Februari. Bulan lain tanggal 31 tidak dipakai.
- **FR-2.5** Tabel libur Jepang disimpan sebagai data tertanam (`#resource` atau file include), bukan file eksternal, supaya identik di Tester. Sumber: daftar resmi Cabinet Office Jepang, mencakup hari libur pengganti dan libur akhir tahun bank. Cakupan 2015 sampai 2035, diperbarui tiap tahun.
- **FR-2.6** Hasil resolusi di-dedupe (dua kandidat yang mundur ke hari yang sama dihitung satu kali).
- **FR-2.7** Hari broker tutup (25 Des, 1 Jan) dikecualikan: **tidak trading dan tidak digeser**.
- **FR-2.8** Basis tanggal adalah tanggal JST pada waktu entry.

### FR-3 Entry

- **FR-3.1** Pada hari valid, EA membuka satu SELL market USDJPY pada tick pertama ≥ waktu entry.
- **FR-3.2** Jendela toleransi `InpMaxEntryDelaySec` (default 30 detik). Jika tidak terisi dalam jendela ini, hari itu **dilewati** dan dicatat. EA tidak pernah masuk terlambat.
- **FR-3.3** Entry diblokir bila: bukan hari Gotobi (kecuali mode riset), di luar sesi (jika filter aktif), spread melebihi batas (FR-5), sudah ada posisi atau sudah trading hari itu, lot tidak valid (FR-4), atau offset waktu tidak tervalidasi.
- **FR-3.4** SL dipasang bersamaan dengan order (server-side): `SL = Bid_entry × (1 + InpSlPercent/100)`, dinormalisasi ke tick size.

### FR-4 Ukuran Akun dan Position Sizing

- **FR-4.1** Mode risiko `InpRiskMode`: `FIXED_USD` (default, sesuai sheet: 100) atau `PERCENT_EQUITY`.
- **FR-4.2** Basis ukuran akun `InpAccountSizeMode`: `ACCOUNT_REAL` (equity akun) atau `ACCOUNT_MANUAL` (nilai `InpManualAccountSize`). Basis ini dipakai pada mode persen dan pada pengecekan batas risiko.
- **FR-4.3** Lot = uang risiko ÷ (jarak SL dalam tick × `SYMBOL_TRADE_TICK_VALUE_LOSS`). Opsi `InpIncludeSpreadInRisk` (default true) menambahkan spread ke jarak SL karena SL SELL dipicu oleh Ask.
- **FR-4.4** Lot dibulatkan **ke bawah** ke `VOLUME_STEP` dan dibatasi `VOLUME_MAX`. Jika hasil < `VOLUME_MIN`, trade **dilewati** (default) dan dicatat. Opsi `InpAllowMinLotOverRisk` (default false) mengizinkan memakai lot minimum.
- **FR-4.5 Pagar keamanan (usulan)**: `InpMaxRiskPercentOfEquity` (default 2). Jika uang risiko melebihi persentase ini terhadap ukuran akun, entry diblokir. Ini melindungi dari salah input saat nilai $100 tetap dipakai pada akun kecil.
- **FR-4.6** Nilai uang risiko dalam mata uang akun.

### FR-5 Spread dan Eksekusi

- **FR-5.1** Filter spread `InpUseSpreadFilter` (default true) dan `InpMaxSpreadPoints` (default 20 poin, usulan; untuk USDJPY 3 digit, 10 poin = 1 pip). Jika spread melebihi batas pada saat entry, EA menunggu sampai akhir jendela `InpMaxEntryDelaySec`, lalu melewati hari itu.
- **FR-5.2** Spread selama backtest ditentukan pengaturan Strategy Tester (spread tetap atau data real ticks), tidak dapat dioverride EA. Input EA hanya mengatur batas filter. Ini asumsi interpretasi, lihat bagian 10.
- **FR-5.3** Deviasi maksimum `InpMaxDeviationPoints` (default 20). Filling mode dideteksi otomatis dari `SYMBOL_FILLING_MODE`. Retry maksimal 3 kali dalam jendela entry untuk requote atau off quotes.
- **FR-5.4** Validasi simbol: nama harus diawali USDJPY (suffix broker diizinkan). Selain itu EA menolak berjalan.
- **FR-5.5** Mendukung akun hedging dan netting. Pada netting, jika sudah ada posisi lain pada simbol yang sama (bukan milik EA), entry dilewati dan dicatat agar posisi tidak bergabung.

### FR-6 Manajemen Posisi dan Exit

- **FR-6.1** Maksimal **satu posisi** per magic number. Tidak ada martingale, grid, averaging, hedging, trailing stop, breakeven, partial close, atau penutupan dini karena profit.
- **FR-6.2** Posisi berjalan lurus sesuai strategi, baik rugi maupun untung. Satu-satunya penutup: SL atau time-exit.
- **FR-6.3** Time-exit pada jadwal tetap (entry terjadwal + `InpHoldMinutes`, default 25), **bukan** dihitung dari waktu fill.
- **FR-6.4** Exit digerakkan `OnTimer` (1 detik) ditambah `OnTick`. Jika penutupan gagal, retry setiap detik sampai berhasil, dan setiap kegagalan dicatat.

### FR-7 Pemulihan (Recovery)

- **FR-7.1** Saat `OnInit`, EA memindai posisi dengan magic number miliknya.
- **FR-7.2** Jika posisi masih terbuka setelah jadwal exit, tutup segera.
- **FR-7.3** Status “sudah trading hari ini” diturunkan dari histori deal (`HistorySelect`) pada hari JST berjalan, bukan dari variabel memori, sehingga aman terhadap restart.

### FR-8 Logging dan Telemetri

Setiap keputusan (entry, skip beserta alasannya, exit, error) dicatat. Per trade disimpan: waktu server/UTC/JST, offset, harga acuan fixing, harga fill, slippage, spread entry, latensi, lot, uang risiko, harga exit, MAE/MFE, dan hasil dalam R.

## 5. Parameter Input

| Kelompok | Parameter | Default | Keterangan |
| --- | --- | --- | --- |
| Waktu | `InpUseTimeFilter` | true | Aktif/nonaktif filter sesi |
| Waktu | `InpSessionStartJst` / `InpSessionEndJst` | 09:00 / 15:00 | Rentang sesi Tokyo |
| Waktu | `InpManualBrokerGmt` | 3 | Offset broker di Tester |
| Waktu | `InpTesterAutoDst` | true | Usulan, lihat FR-1 catatan 2 |
| Waktu | `InpLiveFallbackToManual` | false | Fallback bila deteksi offset live gagal |
| Strategi | `InpEntryTimeJst` | 09:55 | Jam entry (JST) |
| Strategi | `InpHoldMinutes` | 25 | Durasi hold |
| Strategi | `InpSlPercent` | 0.15 | SL dari harga masuk |
| Strategi | `InpDayMode` | GOTOBI\_ONLY | GOTOBI\_ONLY, NON\_GOTOBI\_PLACEBO, ALL\_DAYS (dua terakhir hanya untuk riset) |
| Risiko | `InpRiskMode` | FIXED\_USD | FIXED\_USD atau PERCENT\_EQUITY |
| Risiko | `InpRiskUsd` | 100 | Risiko per trade (mata uang akun) |
| Risiko | `InpRiskPercent` | 0.5 | Dipakai jika mode persen (usulan default) |
| Risiko | `InpAccountSizeMode` | ACCOUNT\_REAL | ACCOUNT\_REAL atau ACCOUNT\_MANUAL |
| Risiko | `InpManualAccountSize` | 10000 | Dipakai jika ACCOUNT\_MANUAL |
| Risiko | `InpMaxRiskPercentOfEquity` | 2 | Pagar keamanan |
| Risiko | `InpIncludeSpreadInRisk` | true | Spread masuk hitungan jarak SL |
| Risiko | `InpAllowMinLotOverRisk` | false | Izinkan lot minimum melebihi risiko |
| Eksekusi | `InpUseSpreadFilter` | true | Aktif/nonaktif filter spread |
| Eksekusi | `InpMaxSpreadPoints` | 20 | Batas spread entry |
| Eksekusi | `InpMaxDeviationPoints` | 20 | Slippage maksimum |
| Eksekusi | `InpMaxEntryDelaySec` | 30 | Jendela entry |
| Sistem | `InpMagic` | tetapkan | Magic number unik |

Semua default bertanda “usulan” ditetapkan oleh penulis PRD dan menunggu konfirmasi.

## 6. Requirement Non-Fungsional

- **Keandalan**: SL selalu terpasang server-side. Tidak ada trade tanpa SL. EA tahan terhadap restart (FR-7).
- **Determinisme**: hasil Tester dan Live konsisten untuk aturan waktu dan tanggal yang sama.
- **Performa**: hanya memproses logika berat pada hari valid dan sekitar jendela entry/exit.
- **Keamanan operasional**: berjalan di VPS dengan jam tersinkron NTP. Login dan akun terpisah dari akun utama selama fase demo.
- **Maintainability**: modul terpisah (CalendarService, TimeService, SignalGate, RiskSizer, Executor, ExitManager, Logger) dan unit test untuk resolver tanggal dan konversi waktu.

## 7. Edge Case

| Kasus | Perilaku yang diharapkan |
| --- | --- |
| Tanggal 30 Februari | Hari kerja terakhir Februari (contoh 2026: 28 Feb jatuh Sabtu, sehingga Jumat 27 Feb) |
| 5 Mei (Golden Week) | Mundur iteratif sampai hari kerja (contoh 2026: 3–6 Mei libur, sehingga Jumat 1 Mei) |
| 25 Desember | Broker tutup, skip tanpa digeser |
| Libur akhir tahun | Ikuti tabel libur yang divalidasi (bank Jepang libur 31 Des dan 2–3 Jan di samping 1 Jan) |
| Transisi DST AS/EU | Waktu JST tetap benar karena dihitung dari UTC, bukan dari jam server mentah |
| EA restart di tengah posisi | Posisi dipulihkan, ditutup jika lewat jadwal exit |
| EA hidup setelah jendela entry | Tidak masuk terlambat, hari dicatat sebagai skip |
| Spread melebar saat fixing | Tunggu sampai akhir jendela, lalu skip |
| Lot < minimum | Skip dan catat (default) |
| Market ditutup saat jadwal exit | Retry tiap detik dan peringatan |
| Jam VPS melenceng | Validasi offset gagal, entry diblokir |

Contoh tanggal di atas adalah nilai harapan untuk uji QA dan harus diverifikasi ulang terhadap kalender resmi.

## 8. Validasi, Backtest, dan Kriteria Penerimaan

**Data dan metode**: Strategy Tester “Every tick based on real ticks” dengan spread variabel dari broker target. Sisihkan periode terbaru sebagai out-of-sample.

**Uji riset wajib**

1. **Placebo**: jalankan `NON_GOTOBI_PLACEBO` dengan parameter identik. Jika hasilnya mirip, yang terukur adalah pola intraday Tokyo umum, bukan efek Gotobi.
2. **Sensitivitas parameter**: durasi hold 10 sampai 60 menit (kelipatan 5), jam entry ±5 menit, SL 0,10 sampai 0,25%. Cari dataran stabil, bukan satu puncak. Jika hanya 25 menit yang bagus, anggap overfitting.
3. **Metrik**: ekspektansi per trade (R), profit factor, Sharpe, max drawdown, win rate, rata-rata slippage dan spread entry, MAE/MFE.

**Kriteria penerimaan teknis**

| ID | Kriteria |
| --- | --- |
| AC-1 | Pada mode produksi, nol trade di hari non-Gotobi |
| AC-2 | Log entry menunjukkan 09:55 JST (dalam toleransi `InpMaxEntryDelaySec`) pada periode DST maupun non-DST, di Tester dan Live |
| AC-3 | Exit terjadi dalam ≤ 2 detik dari 10:20 JST pada kondisi pasar normal |
| AC-4 | 100% trade memiliki SL server-side sesuai `InpSlPercent` |
| AC-5 | Risiko riil per trade ≤ target (pembulatan lot ke bawah) |
| AC-6 | Resolver tanggal lolos unit test (termasuk Februari, Golden Week, Desember) |
| AC-7 | Tidak pernah ada lebih dari satu posisi terbuka |
| AC-8 | Uji recovery: restart EA di tengah posisi tidak menghasilkan posisi ganda atau posisi tertinggal |

**Gerbang menuju live**: lolos AC-1 sampai AC-8, hasil riset tidak gagal pada placebo dan sensitivitas, lalu forward-test demo minimal 3 bulan (sekitar 15 sampai 18 trade). Masuk live dengan risiko kecil dan naik bertahap.

## 9. Risiko dan Mitigasi

| Risiko | Tingkat | Mitigasi |
| --- | --- | --- |
| Edge tidak valid atau sudah terkikis | Tinggi | Placebo, sensitivitas parameter, out-of-sample |
| Biaya (spread dan slippage di jam fixing) memakan edge | Tinggi | Filter spread, telemetri slippage, real-ticks |
| Kesalahan waktu (DST, libur) | Tinggi | Konversi via UTC, validasi offset, unit test |
| Sampel kecil (sekitar 60–70 trade per tahun) | Sedang | Horizon data panjang, jangan menyimpulkan dari sedikit trade |
| Salah ukuran risiko ($100 pada akun kecil) | Sedang–Tinggi | Pagar `InpMaxRiskPercentOfEquity` dan mode persen |
| VPS/EA mati saat hold | Sedang | SL server-side, recovery, monitoring VPS |
| Gap atau spike sisi atas USDJPY | Sedang | SL server-side, pantau slippage, risiko kecil di awal |

## 10. Keputusan Terbuka dan Asumsi

1. **Offset Tester**: setujukah memakai `InpTesterAutoDst` (default true)? Tanpa ini, offset tetap 3 salah 1 jam di musim dingin.
2. **Deteksi live**: `TimeGMT()` bergantung pada jam PC/VPS. Setujukah dengan perilaku fail-safe (blokir entry bila validasi gagal)?
3. **Spread di panel input**: diasumsikan sebagai **batas maksimum spread untuk entry**. Jika yang dimaksud adalah simulasi spread di backtest, itu diatur di Strategy Tester dan bukan dari EA.
4. **Mode risiko**: sheet memakai $100 tetap. Disarankan mode persen dengan pagar 2%. Ukuran akun Anda belum diketahui, sehingga default belum final.
5. **Definisi libur Jepang**: libur nasional resmi ditambah libur bank akhir tahun. Tabel perlu divalidasi terhadap sumber resmi.
6. **Akun**: tipe (hedging/netting), broker, spread, dan komisi USDJPY belum diketahui.
7. **Default usulan**: `InpMaxEntryDelaySec` = 30, `InpMaxSpreadPoints` = 20, `InpMaxDeviationPoints` = 20, `InpMaxRiskPercentOfEquity` = 2.
8. **News filter**: ditunda ke v1.1 (±15 menit sebelum/sesudah berita penting USD/JPY). Verifikasi dulu ketersediaan Economic Calendar MQL5 di Strategy Tester, atau gunakan file CSV berita.

## 11. Roadmap

| Versi | Isi |
| --- | --- |
| v0.1 | Core: resolver Gotobi, time manager, entry/exit, sizing, filter spread dan sesi, logging, recovery |
| v0.2 | Mode riset (placebo, ALL\_DAYS), telemetri dan laporan, uji sensitivitas |
| v1.0 | Lolos gerbang live setelah forward-test demo |
| v1.1 | News filter |
