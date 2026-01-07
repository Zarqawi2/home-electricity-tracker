class AppConfig {
  AppConfig({
    required this.baseUrl,
    this.connectTimeoutMs = 20000,
    this.receiveTimeoutMs = 20000,
  });

  final String baseUrl;
  final int connectTimeoutMs;
  final int receiveTimeoutMs;

  factory AppConfig.fromEnv() {
    const customBaseUrl = ''; // Set to LAN IP or another host if needed.
    if (customBaseUrl.isNotEmpty) {
      return AppConfig(baseUrl: customBaseUrl);
    }

    return AppConfig(baseUrl: 'http://localhost:8000');
  }
}
