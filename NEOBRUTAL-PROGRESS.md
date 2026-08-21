# Kemajuan Rombak Neobrutalism — ingatan loop

Berkas ini adalah ingatan loop Fase B. Root proyek bukan git repo, jadi ini tidak
mengotori ketiga sub-repo. Tiap putaran loop menambah satu baris ke tabel di
bawah, lalu berhenti lapor ke pengguna. Putaran berikutnya mulai dari membaca
berkas ini — bisa mulai dingin setelah konteks terpangkas.

Rencana penuh: `C:\Users\asusr\.claude\plans\hey-chat-bagaimana-kalo-imperative-zebra.md`

## Perkakas (Langkah 1 — selesai)

- **Bun 1.4.0** terpasang lewat npm (`npm i -g bun`). Node v20 sudah ada.
- **243 skill terpasang** di `~/.claude/skills`:
  - gstack (55) — `/guard`, `/cso`, `/qa`, `/browse`, `/plan-design-review`
  - mattpocock (25) — `wayfinder`, `handoff`, `diagnosing-bugs`, `tdd`; tabrakan diberi awalan `mp-` (`mp-code-review`, `mp-prototype`)
  - emilkowalski (11) — `animation-vocabulary`, `review-animations`
  - cybersecurity (143) — subset: web/api/mobile/app-security, crypto, IAM. 674 sisanya sengaja TIDAK dipasang (~75k token deskripsi) — tetap di `~/.claude/skills-src/`
  - prompt-master (1)
- **Sumber repo** di `~/.claude/skills-src/` (klon dangkal). gstack butuh `./setup` diulang tiap `git pull`.
- **ReconForge** TIDAK dipasang sebagai skill — CLI Python, menganggur sampai KlikToko ter-deploy. Ada di `skills-src/ReconForge`.
- **code-graph-rag & OmniRoute** tidak dipasang: Docker tidak ada; gateway pihak ketiga bertentangan dengan metode konteks-terukur.
- gstack menambah **satu Stop hook** ke `settings.json` (backup: `settings.json.bak.20260821-154333.*`).

## Perkakas verifikasi (di scratchpad sesi ini)

`px.py` · `region.py` · `crop.py` · `drive.ps1` — di
`…/scratchpad/`. `drive.ps1` menolak memotret kalau app bukan jendela terdepan.
Build: `flutter build windows --debug --dart-define=KLIKTOKO_API=http://127.0.0.1:8000`
lalu jalankan `build/windows/x64/runner/Debug/kliktoko.exe`.

## Fase B — status per layar

Cabang target: `mobile-employee` → buat `neobrutal-fase-b` sebelum commit pertama.

| # | Layar | Status | Kontras yang diperbaiki | Commit |
|---|---|---|---|---|
| 0 | `attendance_page/AttendancePage.dart` | ✅ (sesi lalu) | coral 4,13→11,06 · nonaktif 2,56→6,09 · shift 2,46→7,41 | `8294654` |
| 1 | `home_page/Homepage/HomePage.dart` (+ HomeController) | ✅ **8 kegagalan** diperbaiki | chip luar-jangkauan 3,09→11,06 · chip terlambat 2,49→14,96 · check-out infoColor 4,10→5,93 · teks status warning 3,19→5,02 & info 4,10→5,93 · Lihat gudang (ungu di gelap) 3,11→17,72 · jam warning 2,90→4,58 · ikon kosong 2,56→16,55 | `2173cba` |
| 2a | `navigation/BottomNavBar.dart` (employee) | ✅ | ikon tab aktif 3,11→**5,70** · ikon QR 3,11→**5,70** · drawShadow blur → bayangan geser + border hitam 3px | `bf7b695` |
| 2b | `pages/main_navigation.dart` (kasir) | ✅ | tile terpilih 4,80→**17,69** · AppBar elevation 0,5→border hitam · Drawer border kanan · divider hitam | `4fae54c` (repo kasir) |
| 2c | `public/css/admin.css` sidebar | 🔄 sedang | 3 gradien ungu peninggalan Fase A dirata­kan · `::before` dibuang · hover geser-samping → tekan | — |
| 3 | `gudang_page/GudangPage/GudangPage.dart` | ⬜ berikutnya | **cabut indigo `0xFF5753EA` di :99** · 3 `LinearGradient` diratakan | — |
| 2 | `gudang_page/GudangPage/GudangPage.dart` | ⬜ | **cabut `primaryPurple = 0xFF5753EA` indigo di :99** | — |
| 3 | `ReusablePage/detailpage.dart` + `categoryPage.dart` | ⬜ | — | — |
| 4 | `camera_page/AttendanceCameraPage.dart` + `CameraPage.dart` | ⬜ | — | — |
| 5 | `profile_page/` (3 berkas) | ⬜ | **shift + jabatan 2,72 — ungu di kartu gelap, pakai blok** | — |
| 6 | `login_page/` + `start.dart` + `BottomNavBar.dart` + `splash/` | ⬜ | — | — |

## Aturan yang tidak boleh dilanggar per putaran

1. **Hitung kontras SEBELUM menyentuh**, bukan sesudah. Tiga kali sesi lalu angka ditulis dulu lalu meleset.
2. **Kontras terrender lebih buruk dari nominal** untuk teks kecil (3,09 vs 4,12). Ukur dari piksel jadi lewat `region.py`, jangan percaya nilai token.
3. **Ungu gagal di SETIAP permukaan gelap** (2,6–3,1:1). Aksen di kartu gelap wajib dari keluarga blok.
4. Satu blok warna per layar, untuk hal terpenting di layar itu.
5. Gerbang: `flutter analyze` tidak memburuk dari 0 error/12 warning/583 info · `flutter test` 15 hijau · tiap area teks ≥4,5:1 di piksel jadi. Gagal salah satu → tidak commit.

## Fase C, D, E — belum mulai

Lihat Langkah 3 & 4 di berkas rencana. Fase C mencakup: alasan terlambat wajib,
geofence 50→100 m (3 tempat), dan tolak fake GPS (`Position.isMocked`).
