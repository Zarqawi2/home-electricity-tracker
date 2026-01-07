class GridCalculator {
  const GridCalculator({
    required this.contentWidth,
    required this.spacing,
    required this.applianceSlack,
  });

  final double contentWidth;
  final double spacing;
  final double applianceSlack;

  int get summaryColumns => contentWidth > 900
      ? 3
      : contentWidth > 640
          ? 2
          : 1;

  int get chartColumns => contentWidth > 1000 ? 2 : 1;

  int get applianceColumns => contentWidth > 900
      ? 3
      : contentWidth > 640
          ? 2
          : 1;

  double widthForColumns(int columns) {
    if (columns <= 1) return contentWidth;
    final w = (contentWidth - spacing * (columns - 1)) / columns;
    return w.clamp(0.0, double.infinity);
  }

  double widthForApplianceColumns(int columns) {
    final available = (contentWidth - applianceSlack).clamp(
      0.0,
      double.infinity,
    );
    if (columns <= 1) return available;
    final w = (available - spacing * (columns - 1)) / columns;
    return w.clamp(0.0, double.infinity);
  }
}

