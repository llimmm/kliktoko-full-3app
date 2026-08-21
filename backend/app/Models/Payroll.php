<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Payroll extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'date',
        'base_salary',
        'overtime_pay',
        'deductions',
        'bonus',
        'total_hours',
        'notes'
    ];

    // 'date:Y-m-d' bukan 'date' polos — lihat penjelasan di App\Models\Leave.
    protected $casts = [
        'date' => 'date:Y-m-d',
        'base_salary' => 'float',
        'overtime_pay' => 'float',
        'deductions' => 'float',
        'bonus' => 'float',
        'total_hours' => 'integer'
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function calculateTotalSalary()
    {
        return $this->base_salary + $this->overtime_pay + $this->bonus - $this->deductions;
    }
}