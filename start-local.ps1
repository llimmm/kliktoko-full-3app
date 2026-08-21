# Menyalakan lingkungan lokal KlikToko: MariaDB, backend Laravel, dan jembatan
# USB ke tablet.
#
# Dijalankan lewat Start-Process supaya keduanya jadi jendela milik Windows
# sendiri, bukan anak proses terminal yang memanggilnya. Ini penting: proses
# yang dijalankan dari sesi Claude Code ikut mati saat sesi berakhir, dan itu
# sudah terjadi berkali-kali.
#
# Aman dijalankan berulang — yang sudah hidup tidak dinyalakan dua kali.
#
# Pakai:
#   powershell -ExecutionPolicy Bypass -File "start-local.ps1"

$ErrorActionPreference = 'Stop'

$Root    = $PSScriptRoot
$Php     = 'C:\xampp\php\php.exe'
$Mysqld  = 'C:\xampp\mysql\bin\mysqld.exe'
$Adb     = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
$Port    = 8000
# Terikat ke localhost saja. Tablet menjangkaunya lewat `adb reverse` di kabel
# USB, jadi panel admin tidak pernah terbuka ke Wi-Fi.
$BindTo  = '127.0.0.1'

function Say($sym, $msg) { Write-Host "$sym $msg" }

# --- MariaDB -----------------------------------------------------------------
if (Get-Process mysqld -ErrorAction SilentlyContinue) {
    Say '=' "MariaDB sudah jalan (PID $((Get-Process mysqld).Id -join ', '))"
} elseif (-not (Test-Path $Mysqld)) {
    Say '!' "mysqld tidak ditemukan di $Mysqld"
} else {
    Start-Process -FilePath $Mysqld -WindowStyle Minimized
    Start-Sleep -Seconds 4
    $p = Get-Process mysqld -ErrorAction SilentlyContinue
    if ($p) { Say '+' "MariaDB dinyalakan (PID $($p.Id -join ', '))" }
    else    { Say '!' 'MariaDB gagal menyala — cek XAMPP Control Panel' }
}

# --- Backend Laravel ---------------------------------------------------------
# Sengaja BUKAN `artisan serve`. Perintah itu sebenarnya penyelia yang
# menurunkan cmd.exe lalu `php -S`; begitu penyelianya dibersihkan lingkungan,
# server ikut mati — dan itu sudah terjadi. Di sini `php -S` dipanggil langsung
# sehingga hanya ada satu proses, sama seperti mysqld yang terbukti bertahan.
#
# Router bawaan framework memakai getcwd() sebagai document root, jadi
# WorkingDirectory wajib folder public, bukan root proyek.
$Router = Join-Path $Root 'backend\vendor\laravel\framework\src\Illuminate\Foundation\resources\server.php'

$listening = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
if ($listening) {
    Say '=' "Port $Port sudah dilayani (PID $($listening.OwningProcess -join ', '))"
} else {
    # Path proyek mengandung spasi ("Kliktoko - Product"). Start-Process tidak
    # mengutip argumen sendiri, jadi tanpa tanda kutip PHP membaca router-nya
    # sebagai "D:\Kliktoko" dan setiap respons berubah jadi halaman fatal error
    # — dengan kode status tetap 200, sehingga terlihat sehat dari luar.
    Start-Process -FilePath $Php `
        -ArgumentList '-S', "${BindTo}:$Port", "`"$Router`"" `
        -WorkingDirectory (Join-Path $Root 'backend\public') `
        -WindowStyle Minimized
    Start-Sleep -Seconds 3
    $listening = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    if ($listening) { Say '+' "Backend hidup di http://${BindTo}:$Port (PID $($listening.OwningProcess -join ', '))" }
    else            { Say '!' 'Backend gagal menyala — jalankan php -S manual dari backend/public untuk melihat errornya' }
}

# --- Jembatan USB ke tablet --------------------------------------------------
# Tablet fisik tidak bisa memakai 10.0.2.2 (itu milik emulator) dan di sini
# backend tidak dibuka ke Wi-Fi. adb reverse membuat localhost:8000 milik
# tablet menembus ke komputer ini lewat kabel.
if (-not (Test-Path $Adb)) {
    Say '!' "adb tidak ditemukan di $Adb — lewati jembatan USB"
} else {
    $devices = & $Adb devices | Select-String -Pattern "`tdevice$"
    if (-not $devices) {
        Say '-' 'Tidak ada tablet terhubung — lewati adb reverse'
    } else {
        & $Adb reverse "tcp:$Port" "tcp:$Port" | Out-Null
        Say '+' "adb reverse aktif — tablet bisa memakai http://localhost:$Port"
    }
}

Write-Host ''
Say '>' 'Panel admin  : http://127.0.0.1:8000  (admin / admin123)'
Say '>' 'Jalankan app : cd mobile-cashier; flutter run --dart-define=KLIKTOKO_API=http://localhost:8000'
Say '>' 'Menghentikan : tutup dua jendela terminal yang muncul di taskbar'
