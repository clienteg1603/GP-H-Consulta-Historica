class StrongNumberEntry {
  const StrongNumberEntry({
    required this.value,
    required this.count,
    required this.lastDate,
    required this.lastTime,
    required this.lastDraw,
    required this.lastPrize,
  });

  final String value;
  final int count;
  final String lastDate;
  final String lastTime;
  final String lastDraw;
  final int lastPrize;
}

enum StrongNumberKind {
  dozen,
  hundred,
  thousand,
}

extension StrongNumberKindLabel on StrongNumberKind {
  String get label {
    switch (this) {
      case StrongNumberKind.dozen:
        return 'Dezenas';
      case StrongNumberKind.hundred:
        return 'Centenas';
      case StrongNumberKind.thousand:
        return 'Milhares';
    }
  }

  int get width {
    switch (this) {
      case StrongNumberKind.dozen:
        return 2;
      case StrongNumberKind.hundred:
        return 3;
      case StrongNumberKind.thousand:
        return 4;
    }
  }
}
