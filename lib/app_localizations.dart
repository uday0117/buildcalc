import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations();

  static const List<Locale> supportedLocales = [Locale('en'), Locale('ar')];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static String translate(BuildContext context, String key) {
    final locale = Localizations.localeOf(context);
    final map = _translations[locale.languageCode] ?? _translations['en']!;
    return map[key] ?? _translations['en']![key] ?? key;
  }

  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'appName': 'BuildCalc',
      'tagline': 'Build Smart, Calculate Right',
      'home': 'Home',
      'history': 'History',
      'saved': 'Saved',
      'settings': 'Settings',
      'rateUs': 'Rate Us',
      'theme': 'Theme',
      'language': 'Language',
      'update': 'Check for update',
      'share': 'Share App',
      'privacy': 'Privacy Policy',
      'terms': 'Terms & Conditions',
      'about': 'About',
      'updateAvailable': 'Update available',
      'installUpdate': 'Install update',
      'later': 'Later',
      'save': 'Save',
      'system': 'System',
      'light': 'Light',
      'dark': 'Dark',
      'english': 'English',
      'arabic': 'العربية',
      'projectDashboard': 'Project dashboard',
      'smartTools': 'Smart tools for faster planning',
      'calculators': 'Calculators',
      'insights': 'Insights',
      'materials': 'Materials',
      'projects': 'Projects',
      'appRating': 'App rating',
      'ratePrompt': 'Enjoying BuildCalc? Let us know with a quick rating.',
      'notNow': 'Not now',
      'rateNow': 'Rate now',
      'version': 'Version',
      'madeBy': 'Made with ❤️ by UK Solutions',
      'loading': 'Loading...',
      'professional': 'Professional Construction Calculator',
    },
    'ar': {
      'appName': 'BuildCalc',
      'tagline': 'ابنِ بذكاء، احسب بدقة',
      'home': 'الرئيسية',
      'history': 'السجل',
      'saved': 'المحفوظات',
      'settings': 'الإعدادات',
      'rateUs': 'قيّم التطبيق',
      'theme': 'المظهر',
      'language': 'اللغة',
      'update': 'التحقق من التحديث',
      'share': 'مشاركة التطبيق',
      'privacy': 'سياسة الخصوصية',
      'terms': 'الشروط والأحكام',
      'about': 'حول',
      'updateAvailable': 'تحديث متاح',
      'installUpdate': 'تثبيت التحديث',
      'later': 'لاحقاً',
      'save': 'حفظ',
      'system': 'النظام',
      'light': 'فاتح',
      'dark': 'داكن',
      'english': 'English',
      'arabic': 'العربية',
      'projectDashboard': 'لوحة المشروع',
      'smartTools': 'أدوات ذكية لتسريع التخطيط',
      'calculators': 'الحاسبات',
      'insights': 'التقارير',
      'materials': 'المواد',
      'projects': 'المشاريع',
      'appRating': 'تقييم التطبيق',
      'ratePrompt': 'هل تستمتع بـ BuildCalc؟ شاركنا بتقييم سريع.',
      'notNow': 'لاحقاً',
      'rateNow': 'قيّم الآن',
      'version': 'الإصدار',
      'madeBy': 'مصنوع بحب من قبل UK Solutions',
      'loading': 'جارٍ التحميل...',
      'professional': 'آلة حسابات البناء الاحترافية',
    },
  };
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return const AppLocalizations();
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
