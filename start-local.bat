@echo off
REM Klik dua kali berkas ini untuk menyalakan lingkungan lokal KlikToko.
REM
REM Gunanya sebagai jaring pengaman: proses yang dinyalakan dari sesi Claude
REM Code bisa ikut dibersihkan saat sesi berakhir, sedangkan yang Anda
REM jalankan sendiri tidak. Isinya sama dengan start-local.ps1.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-local.ps1"
echo.
pause
