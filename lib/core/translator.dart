import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/store.dart';

/// The Bengali and Arabic dictionary of the web app (js/lang.js + js/lang-data.js), kept in assets/data/translations.json:
///  * rows  - exact phrases ("Add to cart"), matched against a whole piece of text;
///  * pats  - sentences with numbers or names in them ("12 items", "Free delivery over SAR 150.00");
///  * units - the words inside pack sizes ("250 g", "6 × 330 ml").
class TranslationData {
  TranslationData._(this.bn, this.ar, this._pats, this._units);

  factory TranslationData.fromJson(Map<String, dynamic> j) {
    final bn = <String, String>{}, ar = <String, String>{};
    for (final r in j['rows'] as List) {
      final row = r as List;
      if ((row[1] as String).isNotEmpty) bn[row[0] as String] = row[1] as String;
      if ((row[2] as String).isNotEmpty) ar[row[0] as String] = row[2] as String;
    }
    final pats = [
      for (final p in j['pats'] as List)
        _Pattern(RegExp((p as List)[0] as String), _Template.from(p[2]), _Template.from(p[3])),
    ];
    // longest unit words first, so "pieces" is read before "pcs" or "s"
    final units = [for (final u in j['units'] as List) u as List]..sort((a, b) => (b[0] as String).length.compareTo((a[0] as String).length));
    return TranslationData._(bn, ar, pats, [
      for (final u in units)
        _Unit(RegExp('(?<![A-Za-z])${RegExp.escape(u[0] as String)}(?![A-Za-z])'), u[1] as String, u[2] as String),
    ]);
  }

  static Future<TranslationData> load() async =>
      TranslationData.fromJson(jsonDecode(await rootBundle.loadString('assets/data/translations.json')) as Map<String, dynamic>);

  final Map<String, String> bn, ar;
  final List<_Pattern> _pats;
  final List<_Unit> _units;
}

class _Pattern {
  _Pattern(this.re, this.bn, this.ar);

  final RegExp re;
  final _Template? bn, ar;
}

/// Either a text with $1, $2 ... for the captured parts, or the name of a function that builds the text.
class _Template {
  _Template(this.text, this.fn);

  static _Template? from(Object? v) {
    if (v == null) return null;
    if (v is String) return _Template(v, null);
    return _Template(null, (v as Map)['fn'] as String);
  }

  final String? text, fn;
}

class _Unit {
  _Unit(this.re, this.bn, this.ar);

  final RegExp re;
  final String bn, ar;
}

const Map<String, String> _bnMonths = {
  'Jan': 'জানুয়ারি', 'Feb': 'ফেব্রুয়ারি', 'Mar': 'মার্চ', 'Apr': 'এপ্রিল', 'May': 'মে', 'Jun': 'জুন', 'Jul': 'জুলাই',
  'Aug': 'আগস্ট', 'Sep': 'সেপ্টেম্বর', 'Sept': 'সেপ্টেম্বর', 'Oct': 'অক্টোবর', 'Nov': 'নভেম্বর', 'Dec': 'ডিসেম্বর',
};
const Map<String, String> _arMonths = {
  'Jan': 'يناير', 'Feb': 'فبراير', 'Mar': 'مارس', 'Apr': 'أبريل', 'May': 'مايو', 'Jun': 'يونيو', 'Jul': 'يوليو',
  'Aug': 'أغسطس', 'Sep': 'سبتمبر', 'Sept': 'سبتمبر', 'Oct': 'أكتوبر', 'Nov': 'نوفمبر', 'Dec': 'ديسمبر',
};
const Map<String, String> _bnSuffix = {'chilled': ' (ঠান্ডায়)', 'unopened': ' (না খুললে)', 'frozen': ' (ফ্রিজে)', 'if unopened': ' (না খুললে)'};
const Map<String, String> _arSuffix = {'chilled': ' (مبرّد)', 'unopened': ' (قبل الفتح)', 'frozen': ' (مجمّد)', 'if unopened': ' (إن لم يُفتح)'};

final RegExp _sar = RegExp(r'\bSAR\b');
final RegExp _twoLetters = RegExp(r'[A-Za-z]{2,}');

/// Translates the app's English text into [lang] ('en', 'bn' or 'ar'). English is the source, exactly as in the web app:
/// text without a translation stays English, so a missing translation never breaks a screen.
class Translator {
  Translator(this.lang, this._data);

  /// Without a dictionary (tests, or before it is loaded) everything stays English.
  Translator.english() : this('en', null);

  final String lang;
  final TranslationData? _data;
  final Map<String, String?> _cache = {};

  bool get isRtl => lang == 'ar';

  /// Bengali and Arabic are joined scripts: the web app turns off letter-spacing and capitals for them.
  bool get isComplexScript => lang != 'en';

  String get _currency => lang == 'ar' ? 'ر.س' : 'SAR';

  String call(String english) {
    if (lang == 'en' || _data == null) return english;
    final core = english.trim();
    if (core.isEmpty) return english;
    // nothing to translate: no letters, an ID / code, or an e-mail address
    if (!RegExp(r'[A-Za-z]').hasMatch(core) ||
        (RegExp(r'^[A-Z0-9#_.\-]+$').hasMatch(core) && core != 'SAR') ||
        RegExp(r'^\S+@\S+$').hasMatch(core)) {
      return english;
    }
    final out = lookup(core);
    if (out == null) return english;
    final lead = english.substring(0, english.indexOf(core));
    return lead + out + english.substring(lead.length + core.length);
  }

  /// The translation of exactly [core], or null when there is none.
  String? lookup(String core) {
    if (lang == 'en' || _data == null || core.isEmpty) return null;
    if (_cache.containsKey(core)) return _cache[core];
    var out = _lookupRaw(core);
    if (out != null) out = out.replaceAll(_sar, _currency);
    return _cache[core] = out;
  }

  String _sub(String? x) => x == null ? '' : (lookup(x) ?? x);

  String? _lookupRaw(String core) {
    final data = _data!;
    final hit = (lang == 'bn' ? data.bn : data.ar)[core];
    if (hit != null) return hit;
    for (final p in data._pats) {
      final m = p.re.firstMatch(core);
      if (m == null) continue;
      final tpl = lang == 'bn' ? p.bn : p.ar;
      if (tpl == null) continue;
      if (tpl.fn != null) return _fn(tpl.fn!, m);
      return tpl.text!.replaceAllMapped(RegExp(r'\$(\d)'), (x) => _sub(m.group(int.parse(x[1]!))));
    }
    final u = _unitize(core);
    if (u != null) return u;
    // a bare amount ("SAR 12.00") only needs its currency translated; a sentence that contains SAR must come from the dictionary
    if (_sar.hasMatch(core) && !_twoLetters.hasMatch(core.replaceAll(_sar, ''))) return core.replaceAll(_sar, _currency);
    return null;
  }

  /// Pack sizes: "250 g", "6 × 330 ml", "Dozen" - only when every word in it is a known unit.
  String? _unitize(String s) {
    if (!RegExp(r'\d|^Each$|^Dozen$').hasMatch(s)) return null;
    var out = s;
    var hit = false;
    for (final u in _data!._units) {
      out = out.replaceAllMapped(u.re, (_) {
        hit = true;
        return lang == 'bn' ? u.bn : u.ar;
      });
    }
    if (!hit || _twoLetters.hasMatch(out.replaceAll('SAR', ''))) return null;
    return out;
  }

  // ---- patterns that need code (the web app uses functions for these) ----

  static String _arCount(String n, String one, String two, String few, String many) {
    final v = int.tryParse(n) ?? 0;
    if (v == 1) return one;
    if (v == 2) return two;
    return v >= 3 && v <= 10 ? '$v $few' : '$v $many';
  }

  String _fn(String name, RegExpMatch m) {
    switch (name) {
      case 'arItems':
        return _arCount(m.group(1)!, 'منتج واحد', 'منتجان', 'منتجات', 'منتجًا');
      case 'arReviews':
        return _arCount(m.group(1)!, 'مراجعة واحدة', 'مراجعتان', 'مراجعات', 'مراجعة');
      case 'arRatings':
        return _arCount(m.group(1)!, 'تقييم واحد', 'تقييمان', 'تقييمات', 'تقييمًا');
      case 'arStars':
        final n = m.group(1)!;
        return n == '1' ? 'نجمة واحدة' : (n == '2' ? 'نجمتان' : '$n نجوم');
      case 'date':
        final months = lang == 'bn' ? _bnMonths : _arMonths;
        return '${m.group(1)} ${months[m.group(2)] ?? m.group(2)} ${m.group(3)}';
      case 'spanDays':
        return _span(m, 'দিন', 'يومًا', 'أيام');
      case 'spanMonths':
        return _span(m, 'মাস', 'شهرًا', 'أشهر');
    }
    return m.group(0)!;
  }

  /// "5–21 days", "12 months", "2–3 days chilled"
  /// (the web app reads the wrong group for the "chilled / unopened / frozen" note and drops it; here it is kept).
  String _span(RegExpMatch m, String unitBn, String arOne, String arMany) {
    final from = m.group(1)!, to = m.group(2);
    final note = (m.groupCount >= 4 ? m.group(4) : null)?.trim() ?? '';
    if (lang == 'bn') return '$from${to != null ? '–$to' : ''} $unitBn${_bnSuffix[note] ?? ''}';
    final n = int.parse(to ?? from);
    final word = n <= 10 ? arMany : arOne;
    final range = to != null ? 'من $from إلى $to' : from;
    return '$range $word${_arSuffix[note] ?? ''}';
  }
}

/// Overridden in main() with the loaded dictionary.
final translationDataProvider = Provider<TranslationData?>((ref) => null);

/// The translator for the language chosen in the app.
final translatorProvider = Provider<Translator>((ref) {
  final lang = ref.watch(storeProvider.select((s) => s.lang));
  return Translator(lang, ref.watch(translationDataProvider));
});
