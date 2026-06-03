import 'package:flutter/widgets.dart';
import 'package:norigo/l10n/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n {
    final localized = AppLocalizations.of(this);
    if (localized != null) return localized;

    final locale = Localizations.maybeLocaleOf(this) ?? const Locale('en');
    return lookupAppLocalizations(Locale(locale.languageCode));
  }
}
