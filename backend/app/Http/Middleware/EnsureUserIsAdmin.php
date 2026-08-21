<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

/**
 * Panel admin hanya untuk role admin yang berstatus aktif.
 *
 * Sebelumnya role hanya diperiksa di Web\AuthController::login, sedangkan
 * route-nya cuma memakai middleware 'auth'. Akibatnya sesi karyawan yang
 * sudah terbentuk tetap bisa membuka seluruh panel admin, dan user yang
 * dinonaktifkan tetap masuk sampai sesinya berakhir.
 */
class EnsureUserIsAdmin
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (!$user || !$user->isAdmin() || !$user->is_active) {
            Auth::logout();
            $request->session()->invalidate();
            $request->session()->regenerateToken();

            return redirect()->route('login')
                ->with('error', 'Anda tidak punya akses ke panel admin.');
        }

        return $next($request);
    }
}
