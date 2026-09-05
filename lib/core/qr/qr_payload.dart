part of '../../app/app.dart';

QrType detectQrType(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.startsWith('wifi:')) return QrType.wifi;
  if (normalized.startsWith('begin:vcard')) {
    final hasName = RegExp(r'(?:^|\n)fn(?:;[^:]*)?:', caseSensitive: false).hasMatch(value);
    final hasOrganization = RegExp(r'(?:^|\n)org(?:;[^:]*)?:', caseSensitive: false).hasMatch(value);
    return hasOrganization && !hasName ? QrType.business : QrType.contact;
  }
  if (normalized.startsWith('mecard:')) return QrType.contact;
  if (normalized.startsWith('begin:vevent')) return QrType.event;
  if (normalized.startsWith('begin:vcalendar')) return QrType.calendar;
  if (normalized.startsWith('mailto:') || normalized.startsWith('matmsg:')) return QrType.email;
  if (normalized.startsWith('tel:')) return QrType.phone;
  if (normalized.startsWith('smsto:') || normalized.startsWith('sms:')) return QrType.sms;
  if (normalized.startsWith('geo:')) return QrType.location;
  if (RegExp(r'^(bitcoin|ethereum|litecoin|dogecoin|monero|solana):').hasMatch(normalized)) return QrType.crypto;
  if (normalized.startsWith('app store:') || normalized.startsWith('play store:') || normalized.startsWith('market://') || normalized.contains('apps.apple.com/') || normalized.contains('play.google.com/store/')) return QrType.appStore;
  if (normalized.startsWith('redes sociales') || RegExp(r'(?:^|\n)(instagram|facebook|linkedin)\s*:', caseSensitive: false).hasMatch(value)) return QrType.social;
  if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
    return normalized.contains('wa.me/') || normalized.contains('whatsapp.com') ? QrType.whatsapp : QrType.url;
  }
  return QrType.text;
}

bool isValidQrPayload(String value) {
  final raw = value.trim();
  if (raw.isEmpty) return false;
  final normalized = raw.toLowerCase();
  if (normalized.startsWith('wifi:')) return RegExp(r'(?:^|;)s:', caseSensitive: false).hasMatch(raw);
  if (normalized.startsWith('begin:vcard')) return RegExp(r'(?:^|\n)(fn|org|tel|email)(?:;[^:]*)?:', caseSensitive: false).hasMatch(raw);
  if (normalized.startsWith('mecard:')) return RegExp(r'^mecard:(n|tel|email):', caseSensitive: false).hasMatch(raw);
  if (normalized.startsWith('mailto:')) return Uri.tryParse(raw)?.path.trim().isNotEmpty == true;
  if (normalized.startsWith('tel:')) return RegExp(r'tel:\s*\+?[0-9 ()-]{3,}', caseSensitive: false).hasMatch(raw);
  if (normalized.startsWith('smsto:') || normalized.startsWith('sms:')) return RegExp(r'^(?:smsto|sms):\s*\+?[0-9 ()-]{3,}', caseSensitive: false).hasMatch(raw);
  if (normalized.startsWith('geo:')) return RegExp(r'^geo:-?\d+(?:\.\d+)?,-?\d+(?:\.\d+)?', caseSensitive: false).hasMatch(raw);
  if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
    final uri = Uri.tryParse(raw);
    return uri != null && uri.host.isNotEmpty;
  }
  return true;
}

enum QrReadActionKind { open, shareFile, copy }

class QrReadAction {
  const QrReadAction({required this.label, required this.icon, required this.kind, this.uri, this.extension});
  final String label;
  final IconData icon;
  final QrReadActionKind kind;
  final Uri? uri;
  final String? extension;
}

QrReadAction qrReadActionFor(String value) {
  final type = detectQrType(value);
  switch (type) {
    case QrType.url:
    case QrType.whatsapp:
    case QrType.email:
    case QrType.phone:
    case QrType.sms:
    case QrType.location:
    case QrType.crypto:
    case QrType.appStore:
      return QrReadAction(label: 'open_${type.name}', icon: type.icon, kind: QrReadActionKind.open, uri: Uri.tryParse(value.trim()));
    case QrType.contact:
      return QrReadAction(label: 'use_contact', icon: Icons.person_add_alt_1_outlined, kind: QrReadActionKind.shareFile, extension: value.trim().toUpperCase().startsWith('BEGIN:VCARD') ? 'vcf' : 'txt');
    case QrType.event:
    case QrType.calendar:
      return const QrReadAction(label: 'use_event', icon: Icons.event_available_outlined, kind: QrReadActionKind.shareFile, extension: 'ics');
    case QrType.wifi:
    case QrType.text:
    case QrType.social:
    case QrType.business:
      return const QrReadAction(label: 'copy_info', icon: Icons.copy_outlined, kind: QrReadActionKind.copy);
  }
}

String localizedReadActionLabel(BuildContext context, String value) {
  return switch (detectQrType(value)) {
    QrType.whatsapp => context.qrL10n.t('reader.action.whatsapp'),
    QrType.email => context.qrL10n.t('reader.action.email'),
    QrType.phone => context.qrL10n.t('reader.action.phone'),
    QrType.sms => context.qrL10n.t('reader.action.sms'),
    QrType.location => context.qrL10n.t('reader.action.location'),
    QrType.contact => context.qrL10n.t('reader.action.contact'),
    QrType.event || QrType.calendar => context.qrL10n.t('reader.action.event'),
    QrType.wifi || QrType.text || QrType.social || QrType.business => context.qrL10n.t('reader.action.copy'),
    _ => context.qrL10n.t('reader.action.openUrl'),
  };
}

enum QrType { url, contact, wifi, whatsapp, text, email, phone, sms, location, event, social, business, crypto, appStore, calendar }

extension QrTypeInfo on QrType {
  String get label => switch (this) {
    QrType.url => 'Enlace', QrType.contact => 'Contacto', QrType.wifi => 'Wi-Fi', QrType.whatsapp => 'WhatsApp',
    QrType.text => 'Texto', QrType.email => 'Email', QrType.phone => 'Teléfono', QrType.sms => 'SMS',
    QrType.location => 'Ubicación', QrType.event => 'Evento', QrType.social => 'Redes sociales', QrType.business => 'Negocio',
    QrType.crypto => 'Cripto', QrType.appStore => 'App Store', QrType.calendar => 'Calendario',
  };
  IconData get icon => switch (this) {
    QrType.url => Icons.link, QrType.contact => Icons.person_outline, QrType.wifi => Icons.wifi,
    QrType.whatsapp => Icons.chat, QrType.text => Icons.notes, QrType.email => Icons.email_outlined,
    QrType.phone => Icons.phone_outlined, QrType.sms => Icons.sms_outlined, QrType.location => Icons.location_on_outlined,
    QrType.event || QrType.calendar => Icons.event_outlined, QrType.social => Icons.people_outline,
    QrType.business => Icons.storefront_outlined, QrType.crypto => Icons.currency_bitcoin, QrType.appStore => Icons.apps,
  };
  static QrType from(String value) => QrType.values.firstWhere((x) => x.name == value, orElse: () => QrType.text);
}

