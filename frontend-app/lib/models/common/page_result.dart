/// One page of a paginated list (`Pagination<T>` in docs/api-convention.md §7).
/// Pages are zero-based; use [nextPage] to load more while [hasNext] is true.
class PageResult<T> {
  final List<T> items;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool hasNext;

  const PageResult({required this.items, required this.page, required this.size, required this.totalElements, required this.totalPages, required this.hasNext});

  int get nextPage => page + 1;

  factory PageResult.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) item) => PageResult(
        items: [for (final e in json['items'] as List) item(e as Map<String, dynamic>)],
        page: json['page'] as int,
        size: json['size'] as int,
        totalElements: json['totalElements'] as int,
        totalPages: json['totalPages'] as int,
        hasNext: json['hasNext'] as bool,
      );
}
