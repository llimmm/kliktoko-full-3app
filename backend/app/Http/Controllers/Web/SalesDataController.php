<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Sale;
use Illuminate\Http\Request;

class SalesDataController extends Controller
{
    public function index()
    {
        try {
            $sales = Sale::with(['user', 'items.product'])
                ->latest()
                ->paginate(10);

            return view('sales-data.index', compact('sales'));
        } catch (\Exception $e) {
            \Log::error('SalesDataController error: ' . $e->getMessage());
            return back()->with('error', 'Terjadi kesalahan: ' . $e->getMessage());
        }
    }

    public function getTransactionDetails($id)
    {
        try {
            $sale = Sale::with(['user', 'items.product'])->findOrFail($id);
            
            $formattedSale = [
                'id' => $sale->id,
                'tanggal' => $sale->created_at->format('d M Y, H:i'),
                'karyawan' => $sale->user->name ?? 'Unknown',
                'total_harga' => $sale->total_amount,
                'metode_pembayaran' => $sale->formatted_payment_method,
                'status' => $sale->formatted_status,
                'items' => $sale->items->map(function ($item) {
                    return [
                        'nama_produk' => $item->product->name ?? 'Unknown',
                        'kode_produk' => $item->product->code ?? 'N/A',
                        'jumlah' => $item->quantity,
                        'harga_satuan' => $item->price,
                        'subtotal' => $item->quantity * $item->price
                    ];
                })
            ];

            return response()->json($formattedSale);
        } catch (\Exception $e) {
            \Log::error('getTransactionDetails error: ' . $e->getMessage());
            return response()->json(['error' => 'Transaksi tidak ditemukan'], 404);
        }
    }
}