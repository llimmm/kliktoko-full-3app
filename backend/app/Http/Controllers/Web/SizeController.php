<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\ProductVariant;
use App\Models\Size;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class SizeController extends Controller
{
    public function index(Request $request)
    {
        $query = Size::query();
        
        if ($request->has('search')) {
            $search = $request->get('search');
            $query->where(function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('code', 'like', "%{$search}%");
            });
        }
        
        $sizes = $query->orderBy('created_at', 'desc')
                        ->paginate(10);
        
        return view('sizes.index', compact('sizes'));
    }

    public function create()
    {
        return view('sizes.create');
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string'
        ]);

        Size::create([
            'name' => $request->name,
            'code' => Str::upper(Str::slug($request->name)),
            'description' => $request->description
        ]);

        return redirect()->route('sizes.index')
            ->with('success', 'Size created successfully.');
    }

    public function edit(Size $size)
    {
        return view('sizes.edit', compact('size'));
    }

    public function update(Request $request, Size $size)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string'
        ]);

        $size->update([
            'name' => $request->name,
            'code' => Str::upper(Str::slug($request->name)),
            'description' => $request->description
        ]);

        return redirect()->route('sizes.index')
            ->with('success', 'Size updated successfully.');
    }

    public function destroy(Size $size)
    {
        // Tanpa penjagaan ini foreign key product_variants yang menolak,
        // dan admin hanya melihat 500 tanpa penjelasan.
        $dipakai = ProductVariant::where('size_id', $size->id)->count();

        if ($dipakai > 0) {
            return back()->with('error',
                "Ukuran ini dipakai {$dipakai} varian produk. Hapus ukuran itu dari produknya lebih dulu.");
        }

        $size->delete();

        return redirect()->route('sizes.index')
            ->with('success', 'Ukuran berhasil dihapus.');
    }
}