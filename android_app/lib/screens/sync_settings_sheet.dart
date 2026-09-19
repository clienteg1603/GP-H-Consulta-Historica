import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/history_repository.dart';
import '../services/background_sync_service.dart';
import '../services/history_sync_service.dart';
import '../theme/gph_theme.dart';
import 'widgets/background_sync_card.dart';
import 'widgets/home_overview_widgets.dart';

class SyncSettingsSheet extends StatefulWidget {
  const SyncSettingsSheet({super.key});

  @override
  State<SyncSettingsSheet> createState() => _SyncSettingsSheetState();
}

class _SyncSettingsSheetState extends State<SyncSettingsSheet> {
  late Future<HistorySummary> _summary;

  bool _syncing = false;
  bool _syncFailed = false;
  SyncProgress? _progress;
  String? _syncMessage;

  BackgroundSyncConfig? _backgroundConfig;
  bool _backgroundConfigLoading = true;
  bool _backgroundConfigSaving = false;

  @override
  void initState() {
    super.initState();
    _summary = AppServices.history.summary();
    _initializeBackgroundSync();
  }

  Future<void> _initializeBackgroundSync() async {
    try {
      await AppServices.background.ensureScheduled();
      final config = await AppServices.background.config();
      if (!mounted) return;
      setState(() {
        _backgroundConfig = config;
        _backgroundConfigLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _backgroundConfigLoading = false);
    }
  }

  Future<void> _reloadBackgroundConfig() async {
    final config = await AppServices.background.config();
    if (!mounted) return;
    setState(() {
      _backgroundConfig = config;
      _backgroundConfigLoading = false;
    });
  }

  Future<void> _setAutomaticSync(bool enabled) async {
    if (_backgroundConfigSaving) return;
    setState(() => _backgroundConfigSaving = true);
    try {
      if (enabled) {
        final summary = await AppServices.history.summary();
        if (summary.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Prepare o histórico antes de ativar a atualização automática.'),
            ),
          );
          return;
        }
      }

      await AppServices.background.setEnabled(enabled);
      await _reloadBackgroundConfig();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? 'Atualização automática ativada.'
                : 'Atualização automática desativada.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível alterar a atualização automática agora.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _backgroundConfigSaving = false);
    }
  }

  Future<void> _setResultNotifications(bool enabled) async {
    if (_backgroundConfigSaving) return;
    setState(() => _backgroundConfigSaving = true);
    try {
      if (enabled) {
        final granted = await AppServices.notifications.requestPermission();
        if (!granted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Permita as notificações do GP-H no Android para receber os avisos.',
              ),
            ),
          );
          return;
        }
      }
      await AppServices.background.setNotificationsEnabled(enabled);
      await _reloadBackgroundConfig();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível alterar as notificações agora.')),
      );
    } finally {
      if (mounted) setState(() => _backgroundConfigSaving = false);
    }
  }

  Future<void> _sync() async {
    if (_syncing) return;
    setState(() {
      _syncing = true;
      _syncFailed = false;
      _progress = null;
      _syncMessage = null;
    });

    try {
      final result = await AppServices.sync.sync(
        onProgress: (progress) {
          if (mounted) setState(() => _progress = progress);
        },
      );
      if (!mounted) return;

      setState(() {
        _summary = AppServices.history.summary();
        _syncFailed = false;
        _syncMessage = result.initialLoad
            ? 'Primeira sincronização concluída. ${result.saved} prêmios processados.'
            : 'Atualização concluída. ${result.saved} prêmios processados.';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_syncMessage!)));
    } on SyncException catch (error) {
      if (!mounted) return;
      setState(() {
        _summary = AppServices.history.summary();
        _syncFailed = true;
        _syncMessage = error.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _syncFailed = true;
        _syncMessage = 'Não foi possível sincronizar agora.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível sincronizar agora.')),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.78,
          minChildSize: 0.55,
          maxChildSize: 0.94,
          builder: (context, controller) => DecoratedBox(
            decoration: const BoxDecoration(
              color: GphTheme.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: GphTheme.borderStrong,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: GphTheme.primarySoft,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.sync_rounded,
                        color: GphTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Atualização e sincronização',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Gerencie a base histórica e os avisos de novos resultados.',
                            style: TextStyle(
                              color: GphTheme.textSecondary,
                              fontSize: 11,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                FutureBuilder<HistorySummary>(
                  future: _summary,
                  builder: (context, snapshot) => HomeSyncCard(
                    summary: snapshot.data,
                    syncing: _syncing,
                    progress: _progress,
                    message: _syncMessage,
                    messageIsError: _syncFailed,
                    onSync: _sync,
                  ),
                ),
                const SizedBox(height: 12),
                BackgroundSyncCard(
                  config: _backgroundConfig,
                  loading: _backgroundConfigLoading,
                  saving: _backgroundConfigSaving,
                  onAutoChanged: _setAutomaticSync,
                  onNotificationsChanged: _setResultNotifications,
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    'O horário das verificações em segundo plano é definido pelo Android e pode variar para economizar bateria.',
                    style: TextStyle(
                      color: GphTheme.textMuted,
                      fontSize: 10,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
