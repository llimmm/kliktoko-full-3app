<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\SaleItem;
use App\Models\Size;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class ProductController extends Controller
{
    public function index(Request $request)
    {
        $query = Product::with(['category', 'variants.size']);

        if ($request->has('search')) {
            $search = $request->get('search');
            $query->where(function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('code', 'like', "%{$search}%");
            });
        }
        
        // Order products: Low stock (1-5) first, then out of stock (0), then normal stock (>5)
        $query->orderByRaw('CASE 
            WHEN stock_quantity BETWEEN 1 AND 5 THEN 1
            WHEN stock_quantity = 0 THEN 2
            ELSE 3
        END');
        
        $products = $query->paginate(10);
        return view('products.index', compact('products'));
    }

    public function create()
    {
        return view('products.create', ['sizes' => Size::orderBy('id')->get()]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'price' => 'required|numeric|min:0',
            'image' => 'required|image|mimes:jpeg,png,jpg,gif|max:2048',
            'category_id' => 'required|exists:categories,id',
            // variants[<size_id>] = jumlah stok. Ukuran yang dikosongkan diabaikan.
            'variants' => 'required|array',
            'variants.*' => 'nullable|integer|min:0',
        ]);

        $stockBySize = $this->stockBySize($request);

        if ($stockBySize->isEmpty()) {
            return back()->withInput()
                ->with('error', 'Isi stok untuk minimal satu ukuran.');
        }

        $imagePath = null;
        if ($request->hasFile('image')) {
            $imagePath = $request->file('image')->store('products', 'public');
        }

        // Generate unique code
        do {
            $code = 'PRD-' . str_pad(mt_rand(1, 99999), 5, '0', STR_PAD_LEFT);
        } while (Product::where('code', $code)->exists());

        DB::transaction(function () use ($request, $code, $imagePath, $stockBySize) {
            $product = Product::create([
                'name' => $request->name,
                'code' => $code,
                'price' => $request->price,
                'stock_quantity' => $stockBySize->sum(),
                'image_path' => $imagePath,
                // Kolom lama: diisi ukuran pertama supaya API lama tetap punya nilai.
                'size_id' => $stockBySize->keys()->first(),
                'category_id' => $request->category_id
            ]);

            foreach ($stockBySize as $sizeId => $stock) {
                $product->variants()->create([
                    'size_id' => $sizeId,
                    'stock_quantity' => $stock,
                ]);
            }
        });

        return redirect()->route('products.index')
            ->with('success', 'Produk berhasil ditambahkan.');
    }

    /**
     * Ambil input variants[] menjadi map size_id => stok, membuang ukuran kosong.
     */
    private function stockBySize(Request $request)
    {
        return collect($request->input('variants', []))
            ->filter(fn ($stock) => $stock !== null && $stock !== '')
            ->mapWithKeys(fn ($stock, $sizeId) => [(int) $sizeId => (int) $stock]);
    }

    public function show(Product $product)
    {
        $product->load(['category', 'variants.size']);

        return view('products.show', compact('product'));
    }

    public function edit(Product $product)
    {
        $product->load('variants');

        return view('products.edit', [
            'product' => $product,
            'sizes' => Size::orderBy('id')->get(),
            // size_id => stok, untuk mengisi ulang form.
            'stockBySize' => $product->variants->pluck('stock_quantity', 'size_id'),
        ]);
    }

    public function update(Request $request, Product $product)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'price' => 'required|numeric|min:0',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
            'category_id' => 'required|exists:categories,id',
            'variants' => 'required|array',
            'variants.*' => 'nullable|integer|min:0',
        ]);

        $stockBySize = $this->stockBySize($request);

        if ($stockBySize->isEmpty()) {
            return back()->withInput()
                ->with('error', 'Isi stok untuk minimal satu ukuran.');
        }

        $imagePath = $product->image_path;
        if ($request->hasFile('image')) {
            // Delete old image
            if ($product->image_path) {
                Storage::disk('public')->delete($product->image_path);
            }
            $imagePath = $request->file('image')->store('products', 'public');
        }

        DB::transaction(function () use ($request, $product, $imagePath, $stockBySize) {
            $product->update([
                'name' => $request->name,
                'price' => $request->price,
                'image_path' => $imagePath,
                'size_id' => $stockBySize->keys()->first(),
                'category_id' => $request->category_id
            ]);

            // Ukuran yang dihapus dari form ikut dibuang, sisanya ditimpa.
            $product->variants()
                ->whereNotIn('size_id', $stockBySize->keys())
                ->delete();

            foreach ($stockBySize as $sizeId => $stock) {
                $product->variants()->updateOrCreate(
                    ['size_id' => $sizeId],
                    ['stock_quantity' => $stock],
                );
            }

            $product->syncStockFromVariants();
        });

        return redirect()->route('products.index')
            ->with('success', 'Produk berhasil diperbarui.');
    }

    public function destroy(Product $product)
    {
        // Produk yang pernah terjual tidak boleh dihapus: baris sale_items
        // menunjuk ke sini, dan riwayat transaksi harus tetap utuh. Tanpa
        // pemeriksaan ini foreign key yang menolak, dan admin hanya melihat 500.
        if (SaleItem::where('product_id', $product->id)->exists()) {
            return back()->with('error',
                'Produk ini sudah pernah terjual, jadi tidak bisa dihapus tanpa merusak riwayat transaksi.');
        }

        if ($product->image_path) {
            Storage::disk('public')->delete($product->image_path);
        }

        $product->delete();

        return redirect()->route('products.index')
            ->with('success', 'Produk berhasil dihapus.');
    }

    /**
     * Restock kini per ukuran, bukan per produk: yang habis biasanya hanya
     * ukuran tertentu, bukan seluruh produk.
     */
    public function restock()
    {
        $variants = ProductVariant::with(['product.category', 'size'])
            ->join('products', 'products.id', '=', 'product_variants.product_id')
            ->orderBy('product_variants.stock_quantity')
            ->orderBy('products.name')
            ->select('product_variants.*')
            ->get();

        $lowStockVariants = $variants->whereBetween('stock_quantity', [1, 5]);
        $outOfStockVariants = $variants->where('stock_quantity', 0);

        return view('products.restock', compact('variants', 'lowStockVariants', 'outOfStockVariants'));
    }

    public function bulkRestock(Request $request)
    {
        $request->validate([
            'stock_add' => 'required|array',
            'stock_add.*' => 'nullable|integer|min:1|max:1000',
        ]);

        // Baris yang dikosongkan berarti tidak direstock — tidak perlu checkbox terpisah.
        $additions = collect($request->input('stock_add', []))
            ->filter(fn ($qty) => $qty !== null && $qty !== '')
            ->mapWithKeys(fn ($qty, $id) => [(int) $id => (int) $qty]);

        if ($additions->isEmpty()) {
            return back()->with('error', 'Isi jumlah tambahan untuk minimal satu ukuran.');
        }

        DB::transaction(function () use ($additions) {
            $variants = ProductVariant::with('product')
                ->whereIn('id', $additions->keys())
                ->get();

            foreach ($variants as $variant) {
                $variant->increment('stock_quantity', $additions[$variant->id]);
            }

            $variants->pluck('product')->unique('id')
                ->each(fn ($product) => $product->syncStockFromVariants());
        });

        return redirect()->route('products.restock')
            ->with('success', "Stok berhasil ditambahkan untuk {$additions->count()} ukuran.");
    }
}