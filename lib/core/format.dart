/// 1234.5 -> "1,234.50" (the web app's Intl.NumberFormat('en-US', 2 decimals)).
String fmt2(num n) {
  final fixed = n.abs().toStringAsFixed(2);
  final dot = fixed.indexOf('.');
  final whole = fixed.substring(0, dot);
  final buf = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
    buf.write(whole[i]);
  }
  return '${n < 0 ? '-' : ''}$buf${fixed.substring(dot)}';
}

/// "SAR 1,234.50"
String moneyText(num n, String currency) => '$currency ${fmt2(n)}';
