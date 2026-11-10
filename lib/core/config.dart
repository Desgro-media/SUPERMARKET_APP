/// Store-wide settings: the same values as the web app's js/config.js (kept in assets/data/catalogue.json).
class AppConfig {
  AppConfig({
    required this.name,
    required this.tagline,
    required this.currency,
    required this.deliveryFee,
    required this.expressFee,
    required this.freeDeliveryAt,
    required this.pageSize,
    required this.maxPerItem,
    required this.areas,
    required this.slots,
    required this.promos,
    required this.paletteSwitcher,
    required this.palettes,
    required this.contact,
  });

  factory AppConfig.fromJson(Map<String, dynamic> j) => AppConfig(
        name: j['name'] as String,
        tagline: j['tagline'] as String,
        currency: j['currency'] as String,
        deliveryFee: (j['deliveryFee'] as num).toDouble(),
        expressFee: (j['expressFee'] as num).toDouble(),
        freeDeliveryAt: (j['freeDeliveryAt'] as num).toDouble(),
        pageSize: j['pageSize'] as int,
        maxPerItem: j['maxPerItem'] as int,
        areas: List<String>.from(j['areas'] as List),
        slots: List<String>.from(j['slots'] as List),
        promos: {
          for (final e in (j['promos'] as Map<String, dynamic>).entries) e.key: PromoDef.fromJson(e.value as Map<String, dynamic>),
        },
        paletteSwitcher: j['paletteSwitcher'] as bool,
        palettes: [for (final p in j['palettes'] as List) PaletteDef.fromJson(p as Map<String, dynamic>)],
        contact: ContactInfo.fromJson(j['contact'] as Map<String, dynamic>),
      );

  final String name, tagline, currency;
  final double deliveryFee, expressFee, freeDeliveryAt;
  final int pageSize, maxPerItem;
  final List<String> areas, slots;
  final Map<String, PromoDef> promos;
  final bool paletteSwitcher;
  final List<PaletteDef> palettes;
  final ContactInfo contact;
}

/// A promo code. [type] is 'pct' (percentage off), 'flat' (fixed amount, above [min]) or 'ship' (free delivery).
class PromoDef {
  PromoDef({required this.label, required this.type, this.value = 0, this.min = 0});

  factory PromoDef.fromJson(Map<String, dynamic> j) => PromoDef(
        label: j['label'] as String,
        type: j['type'] as String,
        value: (j['value'] as num?)?.toDouble() ?? 0,
        min: (j['min'] as num?)?.toDouble() ?? 0,
      );

  final String label, type;
  final double value, min;
}

class PaletteDef {
  PaletteDef({required this.id, required this.name, required this.color});

  factory PaletteDef.fromJson(Map<String, dynamic> j) =>
      PaletteDef(id: j['id'] as String, name: j['name'] as String, color: j['color'] as String);

  final String id, name, color;
}

class ContactInfo {
  ContactInfo({required this.email, required this.phone, required this.hours, required this.address});

  factory ContactInfo.fromJson(Map<String, dynamic> j) => ContactInfo(
        email: j['email'] as String,
        phone: j['phone'] as String,
        hours: j['hours'] as String,
        address: j['address'] as String,
      );

  final String email, phone, hours, address;
}
