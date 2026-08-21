<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class UserController extends Controller
{
    public function index(Request $request)
    {
        $query = User::query();
        
        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%")
                  ->orWhere('code', 'like', "%{$search}%");
            });
        }
        
        $users = $query->orderBy('created_at', 'desc')
                       ->paginate(10);
        
        return view('users.index', compact('users'));
    }

    public function create()
    {
        return view('users.create');
    }

    public function show(User $user)
    {
        return view('users.show', compact('user'));
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'code' => 'required|string|size:4|regex:/^[0-9]{4}$/|unique:users',
            'password' => 'required|string|min:6',
            'role' => 'required|in:admin,karyawan'
        ]);

        if ($validator->fails()) {
            return redirect()
                ->route('users.create')
                ->withErrors($validator)
                ->withInput();
        }

        User::create([
            'name' => $request->name,
            'email' => $request->email,
            'code' => $request->code,
            'password' => Hash::make($request->password),
            'role' => $request->role,
            'is_active' => true
        ]);

        return redirect()
            ->route('users.index')
            ->with('success', 'User berhasil ditambahkan');
    }

    public function edit(User $user)
    {
        return view('users.edit', compact('user'));
    }

    public function update(Request $request, User $user)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users,email,'.$user->id,
            'code' => 'required|string|size:4|regex:/^[0-9]{4}$/|unique:users,code,'.$user->id,
            'role' => 'required|in:admin,karyawan'
        ]);

        if ($validator->fails()) {
            return redirect()
                ->route('users.edit', $user)
                ->withErrors($validator)
                ->withInput();
        }

        $user->update([
            'name' => $request->name,
            'email' => $request->email,
            'code' => $request->code,
            'role' => $request->role
        ]);

        if ($request->filled('password')) {
            $user->update([
                'password' => Hash::make($request->password)
            ]);
        }

        return redirect()
            ->route('users.index')
            ->with('success', 'User berhasil diperbarui');
    }

    /**
     * Balik status aktif user.
     *
     * Menggantikan pasangan activate/deactivate yang dulu dilayani route GET —
     * GET yang mengubah data bisa terpicu prefetch browser. Statusnya dibalik
     * dari nilai saat ini, jadi tidak ada input yang perlu dipercaya.
     */
    public function toggleStatus(User $user)
    {
        if ($user->id === auth()->id()) {
            return back()->with('error', 'Anda tidak dapat menonaktifkan akun Anda sendiri');
        }

        $user->update(['is_active' => !$user->is_active]);

        return redirect()
            ->route('users.index')
            ->with('success', $user->is_active ? 'User berhasil diaktifkan' : 'User berhasil dinonaktifkan');
    }

    public function destroy(User $user)
    {
        $user->delete();

        return redirect()
            ->route('users.index')
            ->with('success', 'User berhasil dihapus secara permanen');
    }

}