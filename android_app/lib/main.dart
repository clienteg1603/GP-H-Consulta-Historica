import 'package:flutter/material.dart';

import 'app_services.dart';
import 'screens/games_screen.dart';
import 'screens/home_visual_screen.dart';
import 'screens/numbers_hub_screen.dart';
import 'screens/search_screen.dart';
import 'screens/stats_visual_screen.dart';
import 'services/app_update_service.dart';
import 'theme/gph_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GphAndroidApp());
}

class GphAndroidApp extends StatelessWidget {
  const GphAndroidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GP-H Consulta Histórica',
      debugShowCheckedModeBanner: false,
      theme: GphTheme.darkBlue,
      home: const GphShell(),
    );
  }
}

class GphShell extends StatefulWidget {
  const GphShell({super.key});

  @override
  State<GphShell> createState() => _GphShellState();
}

class _GphShellState extends State<GphShell> {
  int _index = 0;
  bool _checkingUpdate = false;

  static const _pages = <Widget>[
    HomeVisualScreen(),
    GamesScreen(),
    SearchScreen(),
    StatsVisualScreen(),
    NumbersHubScreen(),
  ];

  static const _titles = <String>[
    'Consulta Histórica',
    'Jogos do dia',
    'Pesquisa',
    'Estatísticas',
    'Números',
  ];

  static const _sectionIcons = <IconData>[
    Icons.home_rounded,
    Icons.view_day_rounded,
    Icons.search_rounded,
    Icons.query_stats_rounded,
    Icons.numbers_rounded,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdate(silent: true);
    });
  }

  Future<void> _checkForUpdate({required bool silent}) async {
    if (_checkingUpdate) return;
    setState(() => _checkingUpdate = true);

    try {
      final update = await AppServices.update.check();
      if (!mounted) return;

      if (update == null) {
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Você já está usando a versão mais recente.')),
          );
        }
        return;
      }

      await _showUpdateDialog(update);
    } on AppUpdateException catch (error) {
      if (!mounted || silent) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted || silent) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível verificar atualizações agora.')),
      );
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
    }
  }

  Future<void> _showUpdateDialog(AppUpdateInfo update) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        actionsPadding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: GphTheme.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.system_update_rounded,
                color: GphTheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 11),
            const Expanded(
              child: Text(
                'Atualização disponível',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 430),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: GphTheme.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: GphTheme.borderStrong),
                  ),
                  child: Text(
                    'Nova versão: ${update.version}',
                    style: const TextStyle(
                      color: GphTheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (update.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'O que mudou',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    update.notes,
                    style: const TextStyle(
                      color: GphTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: GphTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: GphTheme.border),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: GphTheme.textMuted,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'O Android abrirá o arquivo da atualização. Depois é só confirmar a instalação por cima da versão atual.',
                          style: TextStyle(
                            color: GphTheme.textSecondary,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Depois'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                await AppServices.update.openDownload(update);
              } on AppUpdateException catch (error) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error.message)),
                );
              }
            },
            icon: const Icon(Icons.download_rounded),
            label: const Text('Baixar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        titleSpacing: 16,
        title: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: Container(
                key: ValueKey(_index),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: GphTheme.primarySoft,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: GphTheme.borderStrong),
                ),
                child: Icon(
                  _sectionIcons[_index],
                  size: 22,
                  color: GphTheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Column(
                  key: ValueKey(_index),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titles[_index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: GphTheme.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 19,
                        letterSpacing: -0.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'GP-H Android  •  v${AppUpdateService.currentVersion}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: GphTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton.filledTonal(
              tooltip: 'Verificar atualização',
              onPressed: _checkingUpdate ? null : () => _checkForUpdate(silent: false),
              icon: _checkingUpdate
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.system_update_alt_rounded, size: 21),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: GphTheme.border)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (value) {
            if (value == _index) return;
            setState(() => _index = value);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Início',
            ),
            NavigationDestination(
              icon: Icon(Icons.view_day_outlined),
              selectedIcon: Icon(Icons.view_day_rounded),
              label: 'Jogos',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search_rounded),
              label: 'Pesquisa',
            ),
            NavigationDestination(
              icon: Icon(Icons.query_stats_outlined),
              selectedIcon: Icon(Icons.query_stats_rounded),
              label: 'Estatísticas',
            ),
            NavigationDestination(
              icon: Icon(Icons.numbers_outlined),
              selectedIcon: Icon(Icons.numbers_rounded),
              label: 'Números',
            ),
          ],
        ),
      ),
    );
  }
}
