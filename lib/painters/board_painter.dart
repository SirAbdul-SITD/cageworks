import 'package:flutter/material.dart';
import '../models/puzzle.dart';
import '../services/palette.dart';

class BoardPainter extends CustomPainter {
  final Puzzle puzzle;
  final List<List<int>> state; // 0 = empty, else 1..N
  final int? selR;
  final int? selC;
  final Set<String> conflicts;

  BoardPainter({
    required this.puzzle,
    required this.state,
    required this.selR,
    required this.selC,
    required this.conflicts,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = puzzle.n;
    final cell = size.width / n;

    // find the "label cell" for each cage: topmost, then leftmost cell
    final labelCell = <int, List<int>>{};
    for (int ci = 0; ci < puzzle.cages.length; ci++) {
      final cells = puzzle.cages[ci].cells;
      var best = cells[0];
      for (final c in cells) {
        if (c[0] < best[0] || (c[0] == best[0] && c[1] < best[1])) best = c;
      }
      labelCell[ci] = best;
    }

    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        final rect = Rect.fromLTWH(c * cell, r * cell, cell, cell);
        final isSel = r == selR && c == selC;
        final isConf = conflicts.contains('$r,$c');
        Color fill;
        if (isConf) {
          fill = Palette.coral.withValues(alpha: 0.35);
        } else if (isSel) {
          fill = Palette.cellSel;
        } else {
          fill = Palette.cellFill;
        }
        canvas.drawRect(rect, Paint()..color = fill);

        final v = state[r][c];
        if (v > 0) {
          final tp = TextPainter(
            text: TextSpan(
                text: '$v',
                style: TextStyle(
                    color: Palette.ink,
                    fontSize: cell * 0.42,
                    fontWeight: FontWeight.w700)),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(
              canvas,
              Offset(c * cell + cell / 2 - tp.width / 2,
                  r * cell + cell * 0.56 - tp.height / 2));
        }
      }
    }

    // thin internal grid
    final thin = Paint()
      ..color = Palette.line
      ..strokeWidth = 1;
    for (int r = 0; r <= n; r++) {
      canvas.drawLine(Offset(0, r * cell), Offset(size.width, r * cell), thin);
    }
    for (int c = 0; c <= n; c++) {
      canvas.drawLine(Offset(c * cell, 0), Offset(c * cell, size.height), thin);
    }

    // thick cage borders
    final thick = Paint()
      ..color = Palette.cageLine
      ..strokeWidth = 2.6;
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        final id = puzzle.regions[r][c];
        if (c == n - 1 || puzzle.regions[r][c + 1] != id) {
          canvas.drawLine(Offset((c + 1) * cell, r * cell),
              Offset((c + 1) * cell, (r + 1) * cell), thick);
        }
        if (c == 0 || puzzle.regions[r][c - 1] != id) {
          canvas.drawLine(Offset(c * cell, r * cell),
              Offset(c * cell, (r + 1) * cell), thick);
        }
        if (r == n - 1 || puzzle.regions[r + 1][c] != id) {
          canvas.drawLine(Offset(c * cell, (r + 1) * cell),
              Offset((c + 1) * cell, (r + 1) * cell), thick);
        }
        if (r == 0 || puzzle.regions[r - 1][c] != id) {
          canvas.drawLine(Offset(c * cell, r * cell),
              Offset((c + 1) * cell, r * cell), thick);
        }
      }
    }
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = Palette.cageLine
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6);

    // cage clue labels
    for (int ci = 0; ci < puzzle.cages.length; ci++) {
      final cage = puzzle.cages[ci];
      final lc = labelCell[ci]!;
      final x0 = lc[1] * cell;
      final y0 = lc[0] * cell;
      final tp = TextPainter(
        text: TextSpan(
            text: cage.label,
            style: TextStyle(
                color: Palette.cyan,
                fontSize: cell * 0.22,
                fontWeight: FontWeight.w800)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x0 + cell * 0.06, y0 + cell * 0.04));
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter old) =>
      old.state != state ||
      old.selR != selR ||
      old.selC != selC ||
      old.conflicts != conflicts ||
      old.puzzle != puzzle;
}
