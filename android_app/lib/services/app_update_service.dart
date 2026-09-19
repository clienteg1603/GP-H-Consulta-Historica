import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.version,
    required this.build,
    required this.downloadUrl,
    this.notes = '',
  });

  final String version;
  final int build;
  final String downloadUrl;
  final String notes;
}

class AppUpdateService {
  AppUpdateService({http.Client? client}) : _client = client ?? http.Client();

  static const int currentBuild = 14;
  static const String currentVersion = '0.1.11 alpha 14';
  static const String manifestUrl =
      'https://raw.githubusercontent.com/clienteg1603/GP-H-Consulta-Historica/android-release/latest.json';

  final http.Client _client;

  Future<AppUpdateInfo?> check() async {
    final response = await _client
        .get(
          Uri.parse('$manifestUrl?t=${DateTime.now().millisecondsSinceEpoch}'),
          headers: const {
            'Cache-Control': 'no-cache, no-store',
            'Pragma': 'no-cache',
          },
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppUpdateException(
        'Não foi possível verificar atualizações agora. HTTP ${response.statusCode}.',
      );
    }

    final raw = jsonDecode(response.body);
    if (raw is! Map<String, dynamic>) {
      throw const AppUpdateException('Resposta de atualização inválida.');
    }

    final build = _asInt(raw['build']);
    final version = (raw['version'] ?? '').toString().trim();
    final url = (raw['url'] ?? '').toString().trim();
    final notes = (raw['notes'] ?? '').toString().trim();

    if (build <= 0 || version.isEmpty || url.isEmpty) {
      throw const AppUpdateException('Informações de atualização incompletas.');
    }

    if (build <= currentBuild) return null;

    return AppUpdateInfo(
      version: version,
      build: build,
      downloadUrl: url,
      notes: notes,
    );
  }

  Future<void> openDownload(AppUpdateInfo update) async {
    final uri = Uri.tryParse(update.downloadUrl);
    if (uri == null || !uri.hasScheme) {
      throw const AppUpdateException('Link de atualização inválido.');
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      throw const AppUpdateException('Não foi possível abrir o download da atualização.');
    }
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class AppUpdateException implements Exception {
  const AppUpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}
