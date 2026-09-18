import 'package:flutter/material.dart';

import 'app_services.dart';
import 'screens/games_screen.dart';
import 'screens/home_explorer_screen.dart';
import 'screens/search_screen.dart';
import 'screens/stats_screen.dart';
import 'services/app_update_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GphAndroidApp());
}

class GphAndroidApp extends StatelessWidget {
  const GphAndroidApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF3B82F6),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'GP-H Consulta Histórica',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF07101D),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF07101D),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0D1726),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF1C2B41)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF1C2B41)),
          ),
        ),
      ),
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
    HomeExplorerScreen(),
    GamesScreen(),
    SearchScreen(),
    StatsScreen(),
  ];

  static const _titles = <String>[
    'GP-H Consulta Histórica',
    'Jogos do dia',
    'Pesquisa',
    'Estatísticas',
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
        title: const Row(
          children: [
            Icon(Icons.system_update_rounded),
            SizedBox(width: 10),
            Expanded(child: Text('Atualização disponível')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nova versão: ${update.version}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            if (update.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(update.notes),
            ],
            const SizedBox(height: 12),
            const Text(
              'Ao tocar em baixar, o Android abrirá o arquivo de atualização. Depois é só confirmar a instalação.',
              style: TextStyle(color: Color(0xFF9FB0C5)),
            ),
          ],
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
            label: const Text('Baixar atualização'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _titles[_index],
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19),
            ),
            Text(
              'Android • v${AppUpdateService.currentVersion}',
              style: const TextStyle(
                color: Color(0xFF7F94AD),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Verificar atualização',
            onPressed: _checkingUpdate ? null : () => _checkForUpdate(silent: false),
            icon: _checkingUpdate
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.system_update_alt_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
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
        ],
      ),
    );
  }
}
