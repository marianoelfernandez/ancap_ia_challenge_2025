class Chart {
  final String id;
  final String title;
  final String chartData;
  final String userId;
  final String created;
  final String updated;

  Chart({
    required this.id,
    required this.title,
    required this.chartData,
    required this.userId,
    required this.created,
    required this.updated,
  });

  List<Object?> get props => [
        id,
        title,
        chartData,
        userId,
        created,
        updated,
      ];
}
