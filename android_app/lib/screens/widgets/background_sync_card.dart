import 'package:flutter/material.dart';

import '../../services/background_sync_service.dart';
import '../../theme/gph_theme.dart';

class BackgroundSyncCard extends StatelessWidget {
  const BackgroundSyncCard({
    super.key,
    required this.config,
    required this.loading,
    required this.saving,
    required this.onAutoChanged,
    required this.onNotificationsChanged,
  });

  final BackgroundSyncConfig? config;
  final bool loading;
  final bool saving;
  final ValueChanged<bool> onAutoChanged;
  final ValueChanged<bool> onNotificationsChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = config?.enabled ?? false;
    final notifications = config?.notificationsEnabled ?? false;
    final disabled = loading || saving;

    return Container(
      decoration: BoxDecoration(
        color: GphTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: enabled ? GphTheme.borderStrong : GphTheme.border),
      ),
      child: Column(
        children: [
          SwitchListTile.adaptive(
            value: enabled,
            onChanged: disabled ? null : onAutoChanged,
            secondary: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: enabled ? GphTheme.primarySoft : GphTheme.surfaceRaised,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.sync_lock_rounded,
                color: enabled ? GphTheme.primary : GphTheme.textMuted,
                size: 21,
              ),
            ),
            title: const Text(
              'Atualização automática',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              loading
                  ? 'Carregando configuração...'
                  : enabled
                      ? 'O Android verifica novos resultados em segundo plano, aproximadamente a cada 15 minutos.'
                      : 'Ative para o GP-H verificar resultados mesmo com o aplicativo fechado.',
              style: const TextStyle(
                color: GphTheme.textSecondary,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
          Divider(height: 1, color: GphTheme.border.withValues(alpha: 0.8)),
          SwitchListTile.adaptive(
            value: notifications,
            onChanged: disabled || !enabled ? null : onNotificationsChanged,
            secondary: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: notifications ? GphTheme.headSoft : GphTheme.surfaceRaised,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                notifications
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_none_rounded,
                color: notifications ? GphTheme.head : GphTheme.textMuted,
                size: 21,
              ),
            ),
            title: const Text(
              'Notificar novos resultados',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: const Text(
              'Quando a atualização automática encontrar prêmios novos, mostra um aviso no celular.',
              style: TextStyle(
                color: GphTheme.textSecondary,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
          if (enabled) ...[
            Divider(height: 1, color: GphTheme.border.withValues(alpha: 0.8)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 11, 16, 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    config?.lastError == null
                        ? Icons.schedule_rounded
                        : Icons.info_outline_rounded,
                    size: 17,
                    color: config?.lastError == null
                        ? GphTheme.textMuted
                        : GphTheme.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusText(config),
                      style: TextStyle(
                        color: config?.lastError == null
                            ? GphTheme.textMuted
                            : GphTheme.warning,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _statusText(BackgroundSyncConfig? value) {
    if (saving) return 'Salvando configuração...';
    if (value?.lastError != null) return 'Última tentativa: ${value!.lastError}';
    final lastCheck = value?.lastCheck;
    if (lastCheck == null) {
      return 'A primeira verificação será agendada pelo Android. O horário pode variar para economizar bateria.';
    }
    final local = lastCheck.toLocal();
    final date =
        '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    final found = value!.lastNewCount;
    return found > 0
        ? 'Última verificação: $date às $time • $found novo${found == 1 ? '' : 's'} prêmio${found == 1 ? '' : 's'}.'
        : 'Última verificação: $date às $time • nenhum prêmio novo.';
  }
}
