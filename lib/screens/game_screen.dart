import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/puzzle.dart';
import '../painters/board_painter.dart';
import '../services/palette.dart';
import '../services/progress_service.dart';
import '../services/settings_service.dart';
import '../services/audio_manager.dart';

class GameScreen extends StatefulWidget {
  final Puzzle puzzle;
  final AudioManager audio;
  final VoidCallback? onNext;
  const GameScreen({
    super.key,
    required this.puzzle,
    required this.audio,
    this.onNext,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late List<List<int>> grid;
  int? selR, selC;
  bool won = false;
  int moves = 0;
  final _controller = TextEditingController();

  int get _n => widget.puzzle.n;

  @override
  void initState() {
    super.initState();
    grid = List.generate(_n, (_) => List.filled(_n, 0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _haptic() {
    if (context.read<SettingsService>().haptics) {
      HapticFeedback.selectionClick();
    }
  }

  void _selectCell(int r, int c) {
    if (won) return;
    setState(() {
      selR = r;
      selC = c;
      _controller.clear();
    });
    widget.audio.tap();
  }

  void _enterValue(int value) {
    if (won || selR == null || selC == null) return;
    setState(() {
      grid[selR!][selC!] = value;
      moves++;
    });
    if (value == 0) {
      widget.audio.clear();
    } else {
      widget.audio.place();
    }
    _haptic();
    _checkWin();
  }

  Set<String> _conflicts() {
    final out = <String>{};
    for (int r = 0; r < _n; r++) {
      final seen = <int, List<int>>{};
      for (int c = 0; c < _n; c++) {
        final v = grid[r][c];
        if (v > 0) seen.putIfAbsent(v, () => []).add(c);
      }
      for (final cs in seen.values) {
        if (cs.length > 1) {
          for (final c in cs) {
            out.add('$r,$c');
          }
        }
      }
    }
    for (int c = 0; c < _n; c++) {
      final seen = <int, List<int>>{};
      for (int r = 0; r < _n; r++) {
        final v = grid[r][c];
        if (v > 0) seen.putIfAbsent(v, () => []).add(r);
      }
      for (final rs in seen.values) {
        if (rs.length > 1) {
          for (final r in rs) {
            out.add('$r,$c');
          }
        }
      }
    }
    return out;
  }

  bool _cageOk(Cage cage, {bool requireFull = false}) {
    final vals = <int>[];
    for (final cell in cage.cells) {
      final v = grid[cell[0]][cell[1]];
      if (v == 0) {
        if (requireFull) return false;
        continue;
      }
      vals.add(v);
    }
    if (vals.length < cage.cells.length) return true; // partial: ok so far
    switch (cage.op) {
      case '=':
        return vals[0] == cage.target;
      case '+':
        return vals.reduce((a, b) => a + b) == cage.target;
      case 'x':
        return vals.reduce((a, b) => a * b) == cage.target;
      case '-':
        return (vals[0] - vals[1]).abs() == cage.target;
      case '/':
        final hi = vals[0] > vals[1] ? vals[0] : vals[1];
        final lo = vals[0] > vals[1] ? vals[1] : vals[0];
        return lo != 0 && hi % lo == 0 && hi ~/ lo == cage.target;
      default:
        return true;
    }
  }

  Set<String> _cageConflicts() {
    final out = <String>{};
    for (final cage in widget.puzzle.cages) {
      final allFilled = cage.cells.every((cell) => grid[cell[0]][cell[1]] != 0);
      if (allFilled && !_cageOk(cage, requireFull: true)) {
        for (final cell in cage.cells) {
          out.add('${cell[0]},${cell[1]}');
        }
      }
    }
    return out;
  }

  void _checkWin() {
    final p = widget.puzzle;
    for (final row in grid) {
      if (row.contains(0)) return;
    }
    if (_conflicts().isNotEmpty) return;
    for (final cage in p.cages) {
      if (!_cageOk(cage, requireFull: true)) return;
    }
    won = true;
    widget.audio.win();
    final stars = _starRating();
    context.read<ProgressService>().recordWin(p.id, stars);
    Future.delayed(const Duration(milliseconds: 300), _showWinSheet);
  }

  int _starRating() {
    final cells = _n * _n;
    if (moves <= cells) return 3;
    if (moves <= (cells * 1.5).round()) return 2;
    return 1;
  }

  void _showWinSheet() {
    final stars = _starRating();
    showModalBottomSheet(
      context: context,
      backgroundColor: Palette.panel,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Grid Balanced',
                style: TextStyle(
                    color: Palette.ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < stars ? Icons.star : Icons.star_border,
                    color: i < stars ? Palette.amber : Palette.haze,
                    size: 44,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('Solved in $moves entries',
                style: const TextStyle(color: Palette.haze, fontSize: 14)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Palette.ink,
                      side: const BorderSide(color: Palette.line),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Levels'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.cyan,
                      foregroundColor: Palette.void_,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                      widget.onNext?.call();
                    },
                    child: const Text('Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _reset() {
    setState(() {
      grid = List.generate(_n, (_) => List.filled(_n, 0));
      selR = null;
      selC = null;
      moves = 0;
      won = false;
      _controller.clear();
    });
    widget.audio.tap();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.puzzle;
    final conflicts = _conflicts().union(_cageConflicts());
    final enabled = selR != null && selC != null;
    return Scaffold(
      backgroundColor: Palette.void_,
      appBar: AppBar(
        backgroundColor: Palette.void_,
        elevation: 0,
        foregroundColor: Palette.ink,
        title: Text('Level ${p.id + 1}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reset),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Fill 1 to ${p.n} in every row and column. Each boxed cage '
                'must combine to its target using the shown operation.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Palette.haze.withValues(alpha: 0.9),
                    fontSize: 12.5,
                    height: 1.4),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Center(
                child: LayoutBuilder(builder: (context, cons) {
                  final side = (cons.maxWidth < cons.maxHeight
                          ? cons.maxWidth
                          : cons.maxHeight) -
                      32;
                  final cell = side / _n;
                  return GestureDetector(
                    onTapUp: (d) {
                      final c = (d.localPosition.dx / cell)
                          .floor()
                          .clamp(0, _n - 1);
                      final r = (d.localPosition.dy / cell)
                          .floor()
                          .clamp(0, _n - 1);
                      _selectCell(r, c);
                    },
                    child: CustomPaint(
                      size: Size(side, side),
                      painter: BoardPainter(
                        puzzle: p,
                        state: grid,
                        selR: selR,
                        selC: selC,
                        conflicts: conflicts,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            Opacity(
              opacity: enabled ? 1.0 : 0.4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: TextField(
                          controller: _controller,
                          enabled: enabled,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Palette.ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w700),
                          decoration: InputDecoration(
                            hintText: 'Value 1–${p.n}',
                            hintStyle: const TextStyle(
                                color: Palette.haze, fontSize: 15),
                            filled: true,
                            fillColor: Palette.raised,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (text) {
                            final v = int.tryParse(text);
                            if (v != null && v >= 1 && v <= p.n) {
                              _enterValue(v);
                              _controller.clear();
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 52,
                      width: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Palette.raised,
                          foregroundColor: Palette.coral,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: enabled
                            ? () {
                                _enterValue(0);
                                _controller.clear();
                              }
                            : null,
                        child: const Icon(Icons.backspace_outlined, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Entries: $moves',
                      style:
                          const TextStyle(color: Palette.haze, fontSize: 14)),
                  Text(p.tier.toUpperCase(),
                      style: TextStyle(
                          color: Palette.tierColors[p.tier],
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
