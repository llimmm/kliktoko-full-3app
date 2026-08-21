<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\API\AuthController;
use App\Http\Controllers\API\ShiftController;
use App\Http\Controllers\API\CategoryController;
use App\Http\Controllers\API\SizeController;
use App\Http\Controllers\API\ProductController;
use App\Http\Controllers\API\PayrollController;
use App\Http\Controllers\API\SalesController;
use App\Http\Controllers\API\TimeController;
use App\Http\Controllers\API\UserController;
use App\Http\Controllers\TimezoneController;
use App\Http\Controllers\LocationController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/


// Authentication Routes
Route::post('login', [AuthController::class, 'login']);
Route::post('register', [AuthController::class, 'register']);

// Public Timezone Routes (No Authentication Required)
Route::get('timezone/current', [TimezoneController::class, 'getCurrentTime']);
Route::get('timezone/options', [TimezoneController::class, 'getTimezoneOptions']);

// Public Location Routes (No Authentication Required)
Route::get('location/active', [LocationController::class, 'getActiveLocation']);
Route::post('location/check', [LocationController::class, 'checkLocation']);
Route::get('location/check/{latitude}/{longitude}', [LocationController::class, 'checkLocationGet']);

// Protected Routes
Route::middleware('auth:sanctum')->group(function () {
    // Category Management Routes
    Route::prefix('categories')->group(function () {
        Route::get('/', [CategoryController::class, 'index']);
        Route::post('/', [CategoryController::class, 'store']);
        Route::get('/{id}', [CategoryController::class, 'show']);
        Route::put('/{id}', [CategoryController::class, 'update']);
        Route::delete('/{id}', [CategoryController::class, 'destroy']);
    });

    // Size Management Routes
    Route::prefix('sizes')->group(function () {
        Route::get('/', [SizeController::class, 'index']);
        Route::post('/', [SizeController::class, 'store']);
        Route::get('/{size}', [SizeController::class, 'show']);
        Route::put('/{size}', [SizeController::class, 'update']);
        Route::delete('/{size}', [SizeController::class, 'destroy']);
    });

    // Product Management Routes
    Route::prefix('products')->group(function () {
        Route::get('/', [ProductController::class, 'index']);
        Route::post('/', [ProductController::class, 'store']);
        Route::get('/{id}', [ProductController::class, 'show']);
        Route::put('/{id}', [ProductController::class, 'update']);
        Route::delete('/{id}', [ProductController::class, 'destroy']);
    });
    // User Routes
    Route::get('user', [AuthController::class, 'user']);
    Route::post('logout', [AuthController::class, 'logout']);
    Route::put('user/update-password/{id}', [AuthController::class, 'updatePassword']);

    // User Management Routes (New API with Code Field)
    Route::prefix('users')->group(function () {
        Route::get('/', [UserController::class, 'index']);
        Route::post('/', [UserController::class, 'store']);
        Route::get('/generate-code', [UserController::class, 'generateCode']);
        Route::get('/by-code', [UserController::class, 'getByCode']);
        Route::get('/{user}', [UserController::class, 'show']);
        Route::put('/{user}', [UserController::class, 'update']);
        Route::delete('/{user}', [UserController::class, 'destroy']);
        Route::put('/{user}/toggle-status', [UserController::class, 'toggleStatus']);
    });

    // Legacy User Management Routes (AuthController - Old API)
    Route::prefix('legacy-users')->group(function () {
        Route::get('/', [AuthController::class, 'getAllUsers']);
        // Route::get('/search', [AuthController::class, 'searchUsers']);
        // Dihapus: searchUsers tidak pernah didefinisikan, jadi rute ini
        // membalas 500. Nol pemakaian di app employee maupun kasir.
        // whereNumber: tanpa ini segmen non-angka apa pun (mis. /search yang
        // rutenya sudah dihapus) tertangkap sebagai {id}, lalu getUser gagal
        // dengan 500 alih-alih 404 yang jujur.
        Route::get('/{id}', [AuthController::class, 'getUser'])->whereNumber('id');
        Route::put('/{id}', [AuthController::class, 'updateUser'])->whereNumber('id');
        Route::delete('/{id}', [AuthController::class, 'deleteUser'])->whereNumber('id');
        Route::put('/{id}/password', [AuthController::class, 'updatePassword'])->whereNumber('id');
    });

    // Shift Management Routes
    Route::get('shifts', [ShiftController::class, 'getShifts']);
    Route::get('shifts/status', [ShiftController::class, 'getUserShiftStatus']);
    Route::get('shifts/history', [ShiftController::class, 'getMonthlyShiftHistory']);
    Route::post('attendance/check-in', [ShiftController::class, 'checkIn']);
    Route::post('attendance/check-out', [ShiftController::class, 'checkOut']);
    Route::post('leave/request', [ShiftController::class, 'requestLeave']);
    Route::get('attendance/history', [ShiftController::class, 'getAttendanceHistory']);
    Route::get('leave/history', [ShiftController::class, 'getLeaveHistory']);

    // Slip Gaji. Tabel payrolls sudah ada sejak awal tapi tidak pernah punya
    // controller maupun rute, jadi slip gaji mustahil ditampilkan di app.
    // 'history' didaftarkan sebelum '{id}' supaya tidak tertelan sebagai id.
    Route::get('payroll/history', [PayrollController::class, 'index']);
    Route::get('payroll/{id}', [PayrollController::class, 'show'])->whereNumber('id');
    
    // Sales Data Routes
    Route::get('sales-data', [SalesController::class, 'getSalesHistory']);
    Route::get('sales-summary', [SalesController::class, 'getSalesSummary']);
    Route::get('sales/{id}', [SalesController::class, 'show']);
    Route::post('sales', [SalesController::class, 'store']);
    
    // Time API Routes (Real-time)
    Route::get('time/current', [TimeController::class, 'getCurrentTime']);
    Route::get('time/shifts', [TimeController::class, 'getTimeWithShifts']);
    Route::get('time/attendance', [TimeController::class, 'getTimeWithAttendance']);
    Route::get('time/all-attendance', [TimeController::class, 'getTimeWithAllAttendance']);
    
    // Timezone API Routes (Protected)
    Route::post('timezone/update', [TimezoneController::class, 'updateTimezone']);
    
    // Location API Routes (Protected)
    Route::get('location/all', [LocationController::class, 'getAllLocations']);
    Route::put('location/{locationSetting}/update', [LocationController::class, 'updateLocation']);
});
