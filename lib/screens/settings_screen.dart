import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/palette.dart';
import '../services/settings_service.dart';
import '../services/progress_service.dart';
import '../services/audio_manager.dart';

class SettingsScreen extends StatelessWidget {
  final AudioManager audio;
  const SettingsScreen({super.key, required this.audio});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    return Scaffold(
      backgroundColor: Palette.void_,
      appBar: AppBar(
        backgroundColor: Palette.void_,
        elevation: 0,
        foregroundColor: Palette.ink,
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Sound',
                        style: TextStyle(color: Palette.ink)),
                    value: settings.sound,
                    activeColor: Palette.cyan,
                    onChanged: (v) {
                      settings.setSound(v);
                      if (v) {
                        audio.startMusic();
                      } else {
                        audio.stopMusic();
                      }
                    },
                  ),
                  const Divider(color: Palette.line, height: 1),
                  SwitchListTile(
                    title: const Text('Haptics',
                        style: TextStyle(color: Palette.ink)),
                    value: settings.haptics,
                    activeColor: Palette.cyan,
                    onChanged: settings.setHaptics,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _card(
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How to play',
                        style: TextStyle(
                            color: Palette.ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w700)),
                    SizedBox(height: 12),
                    Text(
                      'Fill every row and column with the numbers 1 to the '
                      'grid size, each appearing exactly once — just like a '
                      'Latin square.\n\n'
                      'The grid is also divided into outlined cages. Each '
                      'cage shows a target number and an operation in its '
                      'top-left cell. The values inside that cage must '
                      'combine — by adding, subtracting, multiplying, or '
                      'dividing — to reach the target. Subtraction and '
                      'division only ever appear on two-cell cages, using '
                      'the larger value minus or divided by the smaller.\n\n'
                      'Tap a cell to select it, then type its value. '
                      'Conflicts within a row, column, or cage are flagged '
                      'in red.\n\n'
                      'Every puzzle has exactly one solution, reachable by '
                      'pure deduction.',
                      style: TextStyle(
                          color: Palette.haze, fontSize: 13.5, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _card(
              child: ListTile(
                title: const Text('Reset all progress',
                    style: TextStyle(color: Palette.coral)),
                trailing:
                    const Icon(Icons.delete_outline, color: Palette.coral),
                onTap: () => _confirmReset(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: Palette.panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Palette.line),
        ),
        child: child,
      );

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Palette.panel,
        title: const Text('Reset progress?',
            style: TextStyle(color: Palette.ink)),
        content: const Text('This clears all stars and solved levels.',
            style: TextStyle(color: Palette.haze)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Palette.haze)),
          ),
          TextButton(
            onPressed: () {
              context.read<ProgressService>().reset();
              Navigator.pop(context);
            },
            child: const Text('Reset', style: TextStyle(color: Palette.coral)),
          ),
        ],
      ),
    );
  }
}
