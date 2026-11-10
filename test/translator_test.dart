import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_android/core/translator.dart';

import 'support/test_app.dart';

void main() {
  final data = loadTranslations(); // also proves all 77 sentence patterns and 43 unit words are valid regular expressions
  Translator t(String lang) => Translator(lang, data);

  test('English is returned unchanged', () {
    expect(t('en')('Groceries'), 'Groceries');
    expect(t('en')('Anything at all'), 'Anything at all');
  });

  test('exact phrases translate into Bengali and Arabic', () {
    expect(t('ar')('Groceries'), 'البقالة');
    expect(t('bn')('Groceries'), 'মুদি পণ্য');
    expect(t('ar')('Dairy & Eggs'), 'الألبان والبيض');
  });

  test('text with no translation stays English', () {
    expect(t('bn')('Zzz unknown sentence'), 'Zzz unknown sentence');
  });

  test('sentence patterns with numbers', () {
    expect(t('bn')('12 items'), '12টি পণ্য');
    expect(t('ar')('1 item'), 'منتج واحد');
    expect(t('ar')('2 items'), 'منتجان');
    expect(t('ar')('5 items'), '5 منتجات');
    expect(t('ar')('12 items'), '12 منتجًا');
  });

  test('currency: SAR becomes the Arabic riyal sign, Bengali keeps SAR', () {
    expect(t('ar')('SAR'), 'ر.س');
    expect(t('ar')('SAR 150.00'), 'ر.س 150.00');
    expect(t('bn')('SAR 150.00'), 'SAR 150.00');
  });

  test('the free-delivery message translates as a whole sentence', () {
    expect(t('ar')('Free delivery over SAR 150.00'), isNot('Free delivery over SAR 150.00'));
    expect(t('bn')('Free delivery over SAR 150.00'), isNot('Free delivery over SAR 150.00'));
  });

  test('pack sizes are translated word by word', () {
    expect(t('ar')('500 g'), isNot('500 g'));
    expect(t('bn')('3 × 160 g cans'), isNot('3 × 160 g cans'));
  });

  test('shelf-life spans keep their chilled / unopened note', () {
    expect(t('bn')('2–3 days chilled'), contains('(ঠান্ডায়)'));
    expect(t('ar')('12 months unopened'), contains('(قبل الفتح)'));
    expect(t('bn')('5–21 days'), '5–21 দিন');
  });

  test('IDs, codes and e-mail addresses are never translated', () {
    expect(t('ar')('FN-ABC123'), 'FN-ABC123');
    expect(t('ar')('hello@nestmart.example'), 'hello@nestmart.example');
  });

  test('surrounding spaces are kept', () {
    expect(t('ar')(' Groceries '), ' البقالة ');
  });
}
