# KlikToko — Setup Guide

This repository contains three applications sharing one Laravel backend:

| Folder | App | Purpose |
|---|---|---|
| `backend/` | Laravel 12 | REST API + admin panel (Blade) |
| `mobile-cashier/` | Flutter (`kasir_simoto`) | POS tablet app |
| `mobile-employee/` | Flutter (`kliktoko`) | Attendance, stock, leave, payslip |

---

## Prerequisites

Install these **exact versions** to avoid compatibility issues:

| Tool | Version | Download |
|---|---|---|
| **XAMPP** | 8.2.x (bundles PHP 8.2 + MariaDB 10.4) | https://www.apachefriends.org |
| **PHP** | 8.2+ (bundled with XAMPP) | Included in XAMPP |
| **MariaDB** | 10.4+ (bundled with XAMPP) | Included in XAMPP |
| **Composer** | 2.x | https://getcomposer.org |
| **Flutter** | 3.27.1 (Dart 3.6.0) | https://docs.flutter.dev/get-started/install |
| **Android Studio** | Latest (for SDK + emulator) | https://developer.android.com/studio |
| **Git** | 2.x+ | https://git-scm.com |
| **ADB** | Latest (for physical tablet via USB) | Included in Android SDK Platform-Tools |

### Verify installations

```bash
php --version        # Should show PHP 8.2.x
mysql --version      # Should show MariaDB 10.4.x
composer --version   # Should show Composer 2.x
flutter --version    # Should show Flutter 3.27.x, Dart 3.6.x
git --version        # Any 2.x
```

---

## 1. Clone the repository

```bash
git clone https://github.com/llimmm/kliktoko-full-3app.git
cd kliktoko-full-3app
```

---

## 2. Backend (Laravel)

### 2.1 Start MariaDB

Start MariaDB via XAMPP Control Panel, or run:

```bash
C:\xampp\mysql\bin\mysqld.exe
```

### 2.2 Create database

```bash
C:\xampp\mysql\bin\mysql.exe -u root -e "CREATE DATABASE kliktoko;"
```

### 2.3 Install PHP dependencies

```bash
cd backend
composer install
```

### 2.4 Configure environment

```bash
copy .env.example .env
```

Edit `.env` and set these values:

```env
APP_NAME=KlikToko
APP_ENV=local
APP_DEBUG=true
APP_URL=http://localhost:8000

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=kliktoko
DB_USERNAME=root
DB_PASSWORD=
```

### 2.5 Generate application key

```bash
php artisan key:generate
```

### 2.6 Run migrations and seeders

```bash
php artisan migrate:fresh --seed
```

This builds the entire database from scratch with dummy data.

### 2.7 Start the backend server

```bash
php artisan serve
```

The admin panel is now live at **http://127.0.0.1:8000**.

### Default admin credentials

| Field | Value |
|---|---|
| Username | `admin` |
| Password | `admin123` |

### Employee login (mobile apps)

| Employee | Password |
|---|---|
| `nadia` | `karyawan123` |
| `bagas` | `karyawan123` |
| `rizky` | `karyawan123` |
| `sari` | `karyawan123` |

---

## 3. Mobile Cashier (Flutter POS Tablet)

### 3.1 Install Flutter dependencies

```bash
cd mobile-cashier
flutter pub get
```

### 3.2 Run the app

**Emulator:**
```bash
flutter run --dart-define=KLIKTOKO_API=http://10.0.2.2:8000
```

**Physical tablet via USB:**
```bash
# Set up ADB reverse so tablet can reach localhost:8000
adb reverse tcp:8000 tcp:8000

flutter run --dart-define=KLIKTOKO_API=http://localhost:8000
```

> `adb` path on Windows: `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`

### Target SDK note

`targetSdkVersion` is set to **35**. Do not lower it — Google Play Protect on Android 14 blocks installation of apps built for older SDK versions.

---

## 4. Mobile Employee (Flutter Attendance/Stock/Leave/Payslip)

### 4.1 Install Flutter dependencies

```bash
cd mobile-employee
flutter pub get
```

### 4.2 Run the app

**Emulator:**
```bash
flutter run --dart-define=KLIKTOKO_API=http://10.0.2.2:8000
```

**Physical tablet via USB:**
```bash
adb reverse tcp:8000 tcp:8000
flutter run --dart-define=KLIKTOKO_API=http://localhost:8000
```

---

## 5. Run everything at once (Windows)

There is a PowerShell script that starts MariaDB, the backend server, and the USB bridge in one command:

```powershell
powershell -ExecutionPolicy Bypass -File "start-local.ps1"
```

This opens separate terminal windows for MariaDB and the Laravel server. Closing those windows stops the services.

---

## 6. Useful commands

### Backend

```bash
cd backend

# Rebuild database from scratch
php artisan migrate:fresh --seed

# Run tests
php artisan test

# Run a specific test
php artisan test --filter=NamaTest

# Query database directly
C:\xampp\mysql\bin\mysql.exe -u root kliktoko -e "SELECT * FROM users;"

# Start dev server (with queue, logs, vite)
composer dev
```

### Flutter apps

```bash
# Clean build artifacts
flutter clean

# Reinstall dependencies
flutter pub get

# Run tests
flutter test

# Run a specific test
flutter test test/product_variant_test.dart

# Build APK
flutter build apk --dart-define=KLIKTOKO_API=http://YOUR_API_URL
```

---

## 7. Architecture notes

### Database is the source of truth

- `product_variants` table holds stock per size. `products.stock_quantity` is a mirror kept in sync by `Product::syncStockFromVariants()`.
- Never write directly to `products.stock_quantity` — always go through variants.

### Timezone is database-driven

Shift and attendance logic reads timezone from the `timezone_settings` table, not from `config/app.php`. Do not use `now()` in shift/attendance code — use `Carbon::now(TimezoneSetting::getActive()->timezone)`.

### Two auth systems

- **Admin panel** (web): session-based, protected by `admin` middleware.
- **Mobile apps** (API): Laravel Sanctum tokens.

### No `composer install` on original dev machine

The original dev environment ships `vendor/` pre-installed because Composer is not available on that machine. **Your machine must have Composer** to install dependencies.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `php artisan serve` shows blank page | Check MariaDB is running and `kliktoko` database exists |
| `SQLSTATE[HY000]` connection error | Ensure MariaDB is started: `C:\xampp\mysql\bin\mysqld.exe` |
| Flutter `MissingPluginException` on Windows | `blue_thermal_printer` only works on Android/iOS/macOS |
| Tablet can't reach API | Run `adb reverse tcp:8000 tcp:8000` with USB connected |
| App blocked on Android 14 install | `targetSdkVersion` must be 35+ |
| `mbstring` or extension missing | Enable the extension in `C:\xampp\php\php.ini` |
| Port 8000 already in use | Kill the process or change the port in `start-local.ps1` |
