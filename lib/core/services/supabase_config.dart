class SupabaseConfig {
  const SupabaseConfig({
    this.url = const String.fromEnvironment('SUPABASE_URL'),
    this.anonKey = const String.fromEnvironment('SUPABASE_ANON_KEY'),
  });

  final String url;
  final String anonKey;

  bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  String get statusMessage {
    if (isConfigured) {
      return 'Supabase configuration detected.';
    }
    return 'Supabase is not configured yet. Mock repositories are active.';
  }
}
