<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Web\AuthController;
use App\Http\Controllers\Web\UserController;
use App\Http\Controllers\Web\ShiftController;
use App\Http\Controllers\Web\ProductController;
use App\Http\Controllers\Web\SizeController;
use App\Http\Controllers\Web\CategoryController;
use App\Http\Controllers\Web\SalesDataController;
use App\Http\Controllers\Web\DashboardController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\TimezoneController;
use App\Http\Controllers\LocationController;
use Illuminate\Support\Facades\Artisan;



Route::middleware('guest')->group(function () {
    Route::get('/login', [AuthController::class, 'showLoginForm'])->name('login');
    Route::post('/login', [AuthController::class, 'login'])->name('login.post');
});

// Public Timezone Routes (No Authentication Required)
Route::get('/api/timezone/current', [TimezoneController::class, 'getCurrentTime'])->name('timezone.current');
Route::get('/api/timezone/options', [TimezoneController::class, 'getTimezoneOptions'])->name('timezone.options');

// 'admin' memeriksa role di setiap request, bukan hanya saat login.
Route::middleware(['auth', 'admin'])->group(function () {

    Route::get('/', [DashboardController::class, 'index'])->name('home');
    Route::post('/logout', [AuthController::class, 'logout'])->name('logout');

    // User Management Routes
    Route::resource('users', UserController::class);
    Route::post('/users/{user}/toggle-status', [UserController::class, 'toggleStatus'])->name('users.toggle-status');

    // Shift Management Routes
    Route::get('/shifts', [ShiftController::class, 'index'])->name('shifts.index');
    Route::put('/shifts/settings/update-times', [ShiftController::class, 'updateTimes'])->name('shifts.update_times');
    Route::get('/shifts/{user}', [ShiftController::class, 'detail'])->name('shifts.detail');

    // Product Management Routes
    Route::get('products/restock', [ProductController::class, 'restock'])->name('products.restock');
    Route::post('products/bulk-restock', [ProductController::class, 'bulkRestock'])->name('products.bulk-restock');
    Route::resource('products', ProductController::class);

    // Category Management Routes
    Route::resource('categories', CategoryController::class);
    // Size Management Routes
    Route::resource('sizes', SizeController::class);

    // Sales Data Routes
    Route::get('/sales-data', [SalesDataController::class, 'index'])->name('sales-data.index');
    Route::get('/sales-data/{id}/details', [SalesDataController::class, 'getTransactionDetails'])->name('sales-data.details');

    // Notification Routes
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::post('/notifications/{notification}/mark-as-read', [NotificationController::class, 'markAsRead']);
    Route::post('/notifications/mark-all-as-read', [NotificationController::class, 'markAllAsRead']);

    // Timezone Management Routes
    Route::get('/timezone', [TimezoneController::class, 'index'])->name('timezone.index');
    Route::post('/timezone/update', [TimezoneController::class, 'updateTimezone'])->name('timezone.update');
    Route::post('/api/timezone/update', [TimezoneController::class, 'updateTimezone'])->name('api.timezone.update');
    Route::post('/timezone/update-web', [TimezoneController::class, 'updateTimezone'])->name('timezone.update.web');
    Route::post('/timezone/update-form', [TimezoneController::class, 'updateTimezoneForm'])->name('timezone.update.form');

    // Location Management Routes
    Route::get('/location', [LocationController::class, 'index'])->name('location.index');
    Route::post('/location', [LocationController::class, 'store'])->name('location.store');
    Route::put('/location/{locationSetting}', [LocationController::class, 'update'])->name('location.update');
    Route::post('/location/{locationSetting}/activate', [LocationController::class, 'setActive'])->name('location.activate');
    Route::delete('/location/{locationSetting}', [LocationController::class, 'destroy'])->name('location.destroy');
});

