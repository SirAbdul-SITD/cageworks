class Cage {
  final String op;
  final int target;
  final List<List<int>> cells; // [r, c] pairs

  Cage({required this.op, required this.target, required this.cells});

  factory Cage.fromJson(Map<String, dynamic> j) {
    return Cage(
      op: j['op'] as String,
      target: j['target'] as int,
      cells: (j['cells'] as List)
          .map((e) => (e as List).map((x) => x as int).toList())
          .toList(),
    );
  }

  String get label {
    switch (op) {
      case '=':
        return '$target';
      case '+':
        return '$target+';
      case '-':
        return '$target-';
      case 'x':
        return '$target×';
      case '/':
        return '$target÷';
      default:
        return '$target';
    }
  }
}

class Puzzle {
  final int id;
  final String tier;
  final int n;
  final List<List<int>> regions; // cage id per cell
  final List<Cage> cages;
  final List<List<int>> solution;

  Puzzle({
    required this.id,
    required this.tier,
    required this.n,
    required this.regions,
    required this.cages,
    required this.solution,
  });

  factory Puzzle.fromJson(Map<String, dynamic> j) {
    final n = j['n'] as int;
    final rf = (j['regions'] as List).map((e) => e as int).toList();
    final sf = (j['solution'] as List).map((e) => e as int).toList();
    return Puzzle(
      id: j['id'] as int,
      tier: j['tier'] as String,
      n: n,
      regions: List.generate(n, (r) => List.generate(n, (c) => rf[r * n + c])),
      cages: (j['cages'] as List)
          .map((e) => Cage.fromJson(e as Map<String, dynamic>))
          .toList(),
      solution:
          List.generate(n, (r) => List.generate(n, (c) => sf[r * n + c])),
    );
  }
}
