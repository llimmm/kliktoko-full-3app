<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class ProductController extends Controller
{
    public function index()
    {
        // variants disertakan supaya klien mobile bisa menampilkan stok per
        // ukuran. Kunci lama (stock_quantity, size_id) tetap ada apa adanya,
        // jadi klien yang belum diperbarui tidak berubah perilakunya.
        $products = Product::with('variants.size')->get();

        $products->transform(function ($product) {
            if ($product->image_path) {
                $product->image_path = asset('storage/' . $product->image_path);
            }
            return $product;
        });

        return response()->json(['products' => $products]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'price' => 'required|numeric|min:0',
            'stock_quantity' => 'required|integer|min:0',
            'image' => 'nullable|image|mimes:jpeg,png,jpg|max:2048'
        ]);

        $imagePath = null;
        if ($request->hasFile('image')) {
            $image = $request->file('image');
            $imagePath = $image->store('products', 'public');
        }

        $product = Product::create([
            'name' => $request->name,
            'price' => $request->price,
            'stock_quantity' => 0,
            'code' => $this->generateProductCode(),
            'image_path' => $imagePath,
            'size_id' => $request->size_id,
        ]);

        // stock_quantity adalah kolom cermin — hanya boleh ditulis oleh
        // syncStockFromVariants(). Angka dari klien disimpan sebagai stok
        // varian; tanpa ini, sinkronisasi berikutnya menghapusnya diam-diam.
        if ($request->filled('size_id')) {
            $product->variants()->create([
                'size_id' => $request->size_id,
                'stock_quantity' => (int) $request->stock_quantity,
            ]);
            $product->syncStockFromVariants();
        }

        return response()->json(['product' => $product->load('variants.size')], 201);
    }

    public function show($id)
    {
        $product = Product::with('variants.size')->findOrFail($id);

        if ($product->image_path) {
            $product->image_path = asset('storage/' . $product->image_path);
        }

        return response()->json(['product' => $product]);
    }

    public function update(Request $request, $id)
    {
        $product = Product::findOrFail($id);

        $request->validate([
            'name' => 'required|string|max:255',
            'price' => 'required|numeric|min:0',
            'stock_quantity' => 'required|integer|min:0',
            'image' => 'nullable|image|mimes:jpeg,png,jpg|max:2048'
        ]);

        if ($request->hasFile('image')) {
            if ($product->image_path) {
                Storage::disk('public')->delete($product->image_path);
            }
            $image = $request->file('image');
            $imagePath = $image->store('products', 'public');
            $product->image_path = $imagePath;
        }

        $product->update([
            'name' => $request->name,
            'price' => $request->price,
        ]);

        // Sama seperti store(): stok masuk lewat varian, bukan kolom cermin.
        // Kalau produk punya lebih dari satu ukuran, angka tunggal dari klien
        // tidak bisa dipetakan tanpa menebak — jadi ditolak.
        $variants = $product->variants()->with('size')->get();

        if ($variants->count() === 1) {
            $variants->first()->update(['stock_quantity' => (int) $request->stock_quantity]);
            $product->syncStockFromVariants();
        } elseif ($variants->count() > 1) {
            return response()->json([
                'message' => 'Produk ini punya ' . $variants->count() . ' ukuran ('
                    . $variants->pluck('size.code')->implode(', ')
                    . '). Ubah stoknya per ukuran lewat panel admin.',
            ], 422);
        }

        return response()->json(['product' => $product->load('variants.size')]);
    }

    public function destroy($id)
    {
        $product = Product::findOrFail($id);
        
        if ($product->image_path) {
            Storage::disk('public')->delete($product->image_path);
        }
        
        $product->delete();
        return response()->json(['message' => 'Product deleted successfully']);
    }

    /**
     * Kode unik produk.
     *
     * Dulu memeriksa kolom `isbn_code` yang tidak pernah ada di tabel products,
     * sehingga setiap POST /api/products gagal dengan "Unknown column".
     * Formatnya juga diselaraskan dengan yang dipakai panel admin (PRD-xxxxx).
     */
    private function generateProductCode(): string
    {
        do {
            $code = 'PRD-' . str_pad((string) mt_rand(1, 99999), 5, '0', STR_PAD_LEFT);
        } while (Product::where('code', $code)->exists());

        return $code;
    }
}