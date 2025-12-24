enum ShaparakStatus { notRelated, safe, fake }

class SecurityReport {
  final String url;
  final ShaparakStatus status;
  final String message;

  SecurityReport({
    required this.url,
    required this.status,
    required this.message,
  });

  bool get isSafe => status == ShaparakStatus.safe;

  String get threatType {
    switch (status) {
      case ShaparakStatus.fake:
        return "Phishing URL";
      case ShaparakStatus.notRelated:
        return "Not Shaparak-related";
      default:
        return "Safe";
    }
  }

  @override
  String toString() {
    return 'URL: $url\nStatus: $status\nMessage: $message\n';
  }
}

class ShaparakGuard {
  static const String officialDomain = 'shaparak.ir';
  static const List<String> typoPatterns = [
    'shaprak',
    'shaaparak',
    'shaparaak',
    'shapaarak',
    'shapark',
    'shprk',
  ];

  static List<SecurityReport> analyzeLinks(List<String> urls) {
    return urls.map((url) => analyze(url)).toList();
  }

  static SecurityReport analyze(String rawUrl) {
    Uri uri;
    try {
      uri = Uri.parse(rawUrl.startsWith('http') ? rawUrl : 'https://$rawUrl');
    } catch (_) {
      return SecurityReport(
        url: rawUrl,
        status: ShaparakStatus.notRelated,
        message: 'Invalid URL',
      );
    }

    final host = uri.host.toLowerCase();

    final isShaparakClaim =
        host.contains('shaparak') || typoPatterns.any((t) => host.contains(t));

    if (!isShaparakClaim) {
      return SecurityReport(
        url: rawUrl,
        status: ShaparakStatus.notRelated,
        message: 'Not related to Shaparak',
      );
    }

    if (host == officialDomain || host.endsWith('.$officialDomain')) {
      return SecurityReport(
        url: rawUrl,
        status: ShaparakStatus.safe,
        message: 'Verified official Shaparak domain',
      );
    }

    return SecurityReport(
      url: rawUrl,
      status: ShaparakStatus.fake,
      message: 'Fake or phishing Shaparak URL',
    );
  }
} 
