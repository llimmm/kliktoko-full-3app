<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Sale;
use App\Models\SaleItem;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SalesController extends Controller
{
    public function getSalesHistory(Request $request)
    {
        $query = Sale::with(['user', 'items.product', 'items.variant.size']);

        // Filter berdasarkan tanggal
        if ($request->has('date')) {
            $query->whereDate('created_at', $request->date);
        }

        // Filter berdasarkan bulan
        if ($request->has('month')) {
            $query->whereMonth('created_at', $request->month);
        }

        // Filter berdasarkan tahun
        if ($request->has('year')) {
            $query->whereYear('created_at', $request->year);
        }

        // Filter berdasarkan status
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        $sales = $query->latest()->get();

        $formattedSales = $sales->map(function ($sale) {
            return [
                'id' => $sale->id,
                'tanggal' => $sale->created_at->format('Y-m-d H:i:s'),
                'karyawan' => $sale->user->name,
                'total_harga' => number_format($sale->total_amount, 2, '.', ''),
                'metode_pembayaran' => $sale->formatted_payment_method,
                'status' => $sale->formatted_status,
                'items' => $sale->items->map(function ($item) {
                    return [
                        'nama_produk' => $item->product->name,
                        'kode_produk' => $item->product->code,
                        // Tanpa ini, penjualan ukuran M dan L tampil identik di
                        // riwayat — tidak bisa dipakai menangani retur/keluhan.
                        // Kunci baru, jadi klien lama tidak terpengaruh.
                        'ukuran' => $item->variant?->size?->code,
                        'jumlah' => $item->quantity,
                        'harga_satuan' => number_format($item->price, 2, '.', ''),
                        'subtotal' => number_format($item->subtotal, 2, '.', '')
                    ];
                })
            ];
        });

        return response()->json([
            'message' => 'Berhasil mendapatkan data penjualan',
            'data' => $formattedSales
        ]);
    }

    public function getSalesSummary(Request $request)
    {
        $groupBy = $request->input('group_by', 'day');
        $startDate = $request->input('start_date', Carbon::now()->startOfMonth());
        $endDate = $request->input('end_date', Carbon::now());

        $query = Sale::with(['items.product'])
            ->whereBetween('created_at', [$startDate, $endDate]);

        switch ($groupBy) {
            case 'month':
                $sales = $query->get()->groupBy(function ($sale) {
                    return $sale->created_at->format('Y-m');
                });
                break;

            case 'product':
                return $this->getProductSummary($startDate, $endDate);

            default: // day
                $sales = $query->get()->groupBy(function ($sale) {
                    return $sale->created_at->format('Y-m-d');
                });
        }

        $summary = $sales->map(function ($groupedSales) {
            return [
                'total_penjualan' => $groupedSales->count(),
                'total_pendapatan' => $groupedSales->sum('total_amount'),
                'rata_rata_transaksi' => $groupedSales->avg('total_amount')
            ];
        });

        return response()->json([
            'message' => 'Berhasil mendapatkan ringkasan penjualan',
            'period' => [
                'start_date' => Carbon::parse($startDate)->format('Y-m-d'),
                'end_date' => Carbon::parse($endDate)->format('Y-m-d')
            ],
            'data' => $summary
        ]);
    }

    private function getProductSummary($startDate, $endDate)
    {
        $productSummary = SaleItem::with('product')
            ->whereHas('sale', function ($query) use ($startDate, $endDate) {
                $query->whereBetween('created_at', [$startDate, $endDate]);
            })
            ->select(
                'product_id',
                DB::raw('SUM(quantity) as total_quantity'),
                DB::raw('SUM(subtotal) as total_revenue')
            )
            ->groupBy('product_id')
            ->get()
            ->map(function ($item) {
                return [
                    'nama_produk' => $item->product->name,
                    'kode_produk' => $item->product->code,
                    'jumlah_terjual' => $item->total_quantity,
                    'total_pendapatan' => number_format($item->total_revenue, 2, '.', '')
                ];
            });

        return response()->json([
            'message' => 'Berhasil mendapatkan ringkasan penjualan per produk',
            'period' => [
                'start_date' => Carbon::parse($startDate)->format('Y-m-d'),
                'end_date' => Carbon::parse($endDate)->format('Y-m-d')
            ],
            'data' => $productSummary
        ]);
    }

    public function show($id)
    {
        try {
            $sale = Sale::with(['user', 'items.product'])->findOrFail($id);
            
            $formattedSale = [
                'id' => $sale->id,
                'tanggal' => $sale->created_at->format('Y-m-d H:i:s'),
                'karyawan' => $sale->user->name,
                'total_harga' => number_format($sale->total_amount, 2, '.', ''),
                'metode_pembayaran' => $sale->formatted_payment_method,
                'status' => $sale->formatted_status,
                'items' => $sale->items->map(function ($item) {
                    return [
                        'nama_produk' => $item->product->name,
                        'kode_produk' => $item->product->code,
                        'jumlah' => $item->quantity,
                        'harga_satuan' => number_format($item->price, 2, '.', ''),
                        'subtotal' => number_format($item->subtotal, 2, '.', '')
                    ];
                })
            ];

            return response()->json([
                'message' => 'Berhasil mendapatkan detail transaksi',
                'data' => $formattedSale
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Transaksi tidak ditemukan',
                'error' => $e->getMessage()
            ], 404);
        }
    }

    public function store(Request $request)
    {
        $request->validate([
            'user_id' => 'required|exists:users,id',
            'payment_method' => 'required|in:cash,transfer,qris',
            'notes' => 'nullable|string',
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|exists:products,id',
            // Opsional supaya klien POS lama yang belum mengirim ukuran tetap jalan.
            'items.*.product_variant_id' => 'nullable|exists:product_variants,id',
            'items.*.quantity' => 'required|integer|min:1'
        ]);

        try {
            DB::beginTransaction();

            // Hitung total amount dari semua items
            $totalAmount = 0;
            foreach ($request->items as $item) {
                $product = Product::find($item['product_id']);
                if (!$product) {
                    throw new \Exception('Product with ID ' . $item['product_id'] . ' not found');
                }
                if (!$product->price) {
                    throw new \Exception('Product ' . $product->name . ' has invalid price');
                }
                $totalAmount += $item['quantity'] * $product->price;
            }

            // Validasi user
            $user = User::find($request->user_id);
            if (!$user) {
                throw new \Exception('User with ID ' . $request->user_id . ' not found');
            }

            // Buat transaksi penjualan baru
            $sale = Sale::create([
                'user_id' => $request->user_id,
                'total_amount' => $totalAmount,
                'payment_method' => $request->payment_method,
                'status' => 'completed',
                'notes' => $request->notes
            ]);

            // Buat detail item penjualan
            $touchedProducts = [];

            foreach ($request->items as $item) {
                $product = Product::find($item['product_id']);
                if (!$product) {
                    throw new \Exception('Product with ID ' . $item['product_id'] . ' not found');
                }
                if (!$product->price) {
                    throw new \Exception('Product ' . $product->name . ' has invalid price');
                }
                $subtotal = $item['quantity'] * $product->price;

                if (!empty($item['product_variant_id'])) {
                    $variant = ProductVariant::find($item['product_variant_id']);

                    if (!$variant || $variant->product_id !== $product->id) {
                        throw new \Exception('Ukuran yang dipilih bukan milik produk ' . $product->name);
                    }
                } else {
                    // Klien POS lama tidak mengirim ukuran. Kalau produk hanya punya satu
                    // ukuran, tidak ada yang ambigu. Kalau lebih, menebak akan merusak
                    // stok diam-diam — lebih baik ditolak dengan jelas.
                    $candidates = $product->variants()->with('size')->get();

                    if ($candidates->count() !== 1) {
                        throw new \Exception(
                            'Produk ' . $product->name . ' punya ' . $candidates->count()
                            . ' ukuran (' . $candidates->pluck('size.code')->implode(', ')
                            . '). Sertakan product_variant_id.'
                        );
                    }

                    $variant = $candidates->first();
                }

                SaleItem::create([
                    'sale_id' => $sale->id,
                    'product_id' => $item['product_id'],
                    'product_variant_id' => $variant?->id,
                    'quantity' => $item['quantity'],
                    'price' => $product->price,
                    'subtotal' => $subtotal
                ]);

                // Stok hanya pernah dikurangi lewat varian, supaya products.stock_quantity
                // tetap murni cermin. Penjualan ditolak bila stok tidak mencukupi —
                // sebelumnya stok bisa terdorong menjadi minus tanpa peringatan.
                if (!$variant->decrementStock((int) $item['quantity'])) {
                    throw new \Exception(
                        'Stok ' . $product->name . ' ukuran ' . $variant->size?->code
                        . ' tersisa ' . $variant->stock_quantity . ', kurang dari ' . $item['quantity']
                    );
                }

                $touchedProducts[$product->id] = $product;
            }

            // products.stock_quantity adalah cermin dari total stok varian.
            foreach ($touchedProducts as $product) {
                $product->syncStockFromVariants();
            }

            DB::commit();

            // Format response dengan informasi karyawan
            $sale->load(['user', 'items.product']);
            $formattedSale = [
                'id' => $sale->id,
                'tanggal' => $sale->created_at->format('Y-m-d H:i:s'),
                'karyawan' => $sale->user->name,
                'total_harga' => number_format($sale->total_amount, 2, '.', ''),
                'metode_pembayaran' => $sale->formatted_payment_method,
                'status' => $sale->formatted_status,
                'items' => $sale->items->map(function ($item) {
                    return [
                        'nama_produk' => $item->product->name,
                        'kode_produk' => $item->product->code,
                        'jumlah' => $item->quantity,
                        'harga_satuan' => number_format($item->price, 2, '.', ''),
                        'subtotal' => number_format($item->subtotal, 2, '.', '')
                    ];
                })
            ];

            return response()->json([
                'message' => 'Transaksi penjualan berhasil dibuat',
                'data' => $formattedSale
            ], 201);

        } catch (\Exception $e) {
            DB::rollback();
            return response()->json([
                'message' => 'Terjadi kesalahan saat membuat transaksi',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}