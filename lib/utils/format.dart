/// Format Rupiah tanpa dependensi paket tambahan.
///
/// formatRupiah(12500) == 'Rp 12.500'
String formatRupiah(int amount) {
  final bool negative = amount < 0;
  final String digits = amount.abs().toString();
  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    final int fromEnd = digits.length - i;
    buffer.write(digits[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) {
      buffer.write('.');
    }
  }
  return '${negative ? '-' : ''}Rp ${buffer.toString()}';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

/// Format tanggal: 14/11/2026 13:05
String formatDateTime(DateTime? dateTime) {
  if (dateTime == null) {
    return '-';
  }
  return '${_twoDigits(dateTime.day)}/${_twoDigits(dateTime.month)}/'
      '${dateTime.year} ${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}';
}
