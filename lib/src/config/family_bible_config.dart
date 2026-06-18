class FamilyBibleConfig {
  static const appName = 'Family Bible';
  static const ownerBrand = 'Leslie-23';

  static const apiBaseUrl = String.fromEnvironment(
    'FAMILY_BIBLE_API_URL',
    defaultValue: 'https://server-pi-five-58.vercel.app',
  );
}
