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

  int get applianceColumns => contentWidth > 1120
      ? 3
      : contentWidth > 700
      ? 2
      : 1;

  double widthForColumns(int columns) {
    if (columns <= 1) return contentWidth;
    final w = (contentWidth - spacing * (columns - 1)) / columns;
    return w.clamp(0.0, double.infinity);
  }

  double widthForApplianceColumns(int columns) {
    if (columns <= 1) return contentWidth;
    final available = (contentWidth - applianceSlack).clamp(
      0.0,
      double.infinity,
    );
    final w = (available - spacing * (columns - 1)) / columns;
    return w.clamp(0.0, double.infinity);
  }
}
