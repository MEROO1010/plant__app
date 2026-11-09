class PagedResult<T> {
  const PagedResult({required this.items, required this.currentPage, required this.lastPage, required this.total});

  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;

  factory PagedResult.fromResponse(dynamic data, Map<String, dynamic> meta, T Function(Map<String, dynamic>) parse) {
    final list = (data as List? ?? const []).cast<Map<String, dynamic>>().map(parse).toList();
    return PagedResult(
      items: list,
      currentPage: (meta['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      total: (meta['total'] as num?)?.toInt() ?? list.length,
    );
  }
}
