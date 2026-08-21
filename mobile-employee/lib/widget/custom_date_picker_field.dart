import 'package:flutter/material.dart';
import 'package:kliktoko/theme/app_theme.dart';

class CustomDatePickerField extends StatelessWidget {
  final DateTime? selectedDate;
  final VoidCallback onTap;

  const CustomDatePickerField({
    super.key,
    required this.selectedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TANGGAL',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.secondaryText),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDate == null
                      ? 'Pilih tanggal'
                      : '${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}',
                  style: const TextStyle(color: AppTheme.primaryText),
                ),
                const Icon(Icons.calendar_today, color: AppTheme.secondaryText),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
