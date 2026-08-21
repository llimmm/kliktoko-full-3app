<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rules\Password;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'name' => 'required|string|max:255',
                'email' => 'required|string|email|max:255|unique:users',
                'password' => ['required', 'string', 'min:6'],
                'role' => 'nullable|in:admin,karyawan'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => false,
                    'message' => 'Validasi gagal',
                    'errors' => $validator->errors()
                ], 422);
            }

            $user = User::create([
                'name' => $request->name,
                'email' => $request->email,
                'password' => Hash::make($request->password),
                'role' => $request->role ?? 'karyawan'
            ]);

            $token = $user->createToken('auth_token')->plainTextToken;

            return response()->json([
                'status' => true,
                'message' => 'Registrasi berhasil',
                'data' => [
                    'user' => $user,
                    'token' => $token
                ]
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Terjadi kesalahan',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function login(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'name' => 'required|string',
                'password' => 'required'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => false,
                    'message' => 'Validasi gagal',
                    'errors' => $validator->errors()
                ], 422);
            }

            $user = User::where('name', $request->name)->first();

            if (!$user || !Hash::check($request->password, $user->password)) {
                return response()->json([
                    'status' => false,
                    'message' => 'Username atau password salah'
                ], 401);
            }

            $token = $user->createToken('auth_token')->plainTextToken;

            return response()->json([
                'status' => true,
                'message' => 'Login berhasil',
                'data' => [
                    'user' => $user,
                    'token' => $token
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Terjadi kesalahan',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function user(Request $request)
    {
        return response()->json([
            'status' => true,
            'data' => $request->user()
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'status' => true,
            'message' => 'Logout berhasil'
        ]);
    }

    public function getAllUsers(Request $request)
    {
        try {
            if ($request->user()->role !== 'admin') {
                return response()->json([
                    'status' => false,
                    'message' => 'Unauthorized. Hanya admin yang dapat mengakses.'
                ], 403);
            }

            $users = User::select('id', 'name', 'email', 'role', 'created_at')
                        ->orderBy('created_at', 'desc')
                        ->paginate(10); // 10 user per halaman
            
            return response()->json([
                'status' => true,
                'data' => $users
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Terjadi kesalahan',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function getUser(Request $request, $id)
    {
        try {
            if ($request->user()->role !== 'admin') {
                return response()->json([
                    'status' => false,
                    'message' => 'Unauthorized. Hanya admin yang dapat mengakses.'
                ], 403);
            }

            $user = User::findOrFail($id);
            
            return response()->json([
                'status' => true,
                'data' => $user
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Terjadi kesalahan',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function updateUser(Request $request, $id)
    {
        try {
            if ($request->user()->role !== 'admin') {
                return response()->json([
                    'status' => false,
                    'message' => 'Unauthorized. Hanya admin yang dapat mengakses.'
                ], 403);
            }

            $validator = Validator::make($request->all(), [
                'name' => 'required|string|max:255',
                'email' => 'required|string|email|max:255|unique:users,email,'.$id,
                'role' => 'required|in:admin,karyawan'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => false,
                    'message' => 'Validasi gagal',
                    'errors' => $validator->errors()
                ], 422);
            }

            $user = User::findOrFail($id);
            $user->update([
                'name' => $request->name,
                'email' => $request->email,
                'role' => $request->role
            ]);

            return response()->json([
                'status' => true,
                'message' => 'User berhasil diupdate',
                'data' => $user
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Terjadi kesalahan',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function deleteUser(Request $request, $id)
    {
        try {
            if ($request->user()->role !== 'admin') {
                return response()->json([
                    'status' => false,
                    'message' => 'Unauthorized. Hanya admin yang dapat mengakses.'
                ], 403);
            }

            $user = User::findOrFail($id);
            
            // Prevent deleting self
            if ($user->id === $request->user()->id) {
                return response()->json([
                    'status' => false,
                    'message' => 'Tidak dapat menghapus akun sendiri'
                ], 400);
            }

            $user->delete();

            return response()->json([
                'status' => true,
                'message' => 'User berhasil dihapus'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Terjadi kesalahan',
                'error' => $e->getMessage()
            ], 500);
        }
    }



    public function updatePassword(Request $request, $id)
    {
        try {
            // Cek apakah user adalah admin
            if ($request->user()->role !== 'admin') {
                return response()->json([
                    'status' => false,
                    'message' => 'Unauthorized. Hanya admin yang dapat mengubah password.'
                ], 403);
            }

            $validator = Validator::make($request->all(), [
                'new_password' => ['required', 'string', 'min:6'],
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => false,
                    'message' => 'Validasi gagal',
                    'errors' => $validator->errors()
                ], 422);
            }

            $user = User::findOrFail($id);
            $user->password = Hash::make($request->new_password);
            $user->save();

            return response()->json([
                'status' => true,
                'message' => 'Password berhasil diupdate',
                'data' => [
                    'user_id' => $user->id,
                    'name' => $user->name,
                    'new_password' => $request->new_password // menampilkan password baru dalam plain text
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Terjadi kesalahan',
                'error' => $e->getMessage()
            ], 500);
        }
    }
} 