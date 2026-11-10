import 'package:material_ui/material_ui.dart';

import 'translator.dart';

export 'translator.dart' show Translator;

/// The three languages of the web app (js/i18n.js): English, Bengali and right-to-left Arabic.
class Language {
  const Language(this.id, this.short, this.name, {this.rtl = false});

  final String id, short, name;
  final bool rtl;

  Locale get locale => Locale(id);
}

const List<Language> kLanguages = [
  Language('en', 'EN', 'English'),
  Language('bn', 'BN', 'বাংলা'),
  Language('ar', 'AR', 'العربية', rtl: true),
];

Language languageById(String id) => kLanguages.firstWhere((l) => l.id == id, orElse: () => kLanguages.first);

/// Hands the current [Translator] down the widget tree. Widgets that call `context.tr(...)` rebuild when the language changes.
class I18nScope extends InheritedWidget {
  const I18nScope({super.key, required this.translator, required super.child});

  final Translator translator;

  static Translator of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<I18nScope>()?.translator ?? Translator.english();

  @override
  bool updateShouldNotify(I18nScope old) => old.translator.lang != translator.lang;
}

extension I18nContext on BuildContext {
  /// Translate [english] into the language chosen in the app (English stays as it is).
  String tr(String english) => I18nScope.of(this)(english);
}
