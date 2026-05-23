import 'complaint.dart';

/// Request body for paginated list endpoints (`SearchParam` on backend).
class SearchParam {
  const SearchParam({
    this.firstRow = 0,
    this.pageSize = 10,
    this.sortField,
    this.sortOrder,
    this.searchFieldParams = const [],
    this.param = const {},
  });

  final int firstRow;
  final int pageSize;
  final String? sortField;
  final String? sortOrder;
  final List<SearchFieldParam> searchFieldParams;
  final Map<String, dynamic> param;

  /// Default list request — all rows, backend applies sort defaults.
  factory SearchParam.defaults({
    int firstRow = 0,
    int pageSize = 50,
    Map<String, dynamic>? param,
  }) {
    return SearchParam(
      firstRow: firstRow,
      pageSize: pageSize,
      searchFieldParams: const [],
      param: param ?? const {},
    );
  }

  /// Filter by backend status name, e.g. `NEW`, `IN_PROGRESS`.
  factory SearchParam.withStatus(String status, {int pageSize = 50}) {
    return SearchParam.defaults(
      pageSize: pageSize,
      param: {'status': status},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstRow': firstRow,
      'pageSize': pageSize,
      if (sortField != null && sortField!.isNotEmpty) 'sortField': sortField,
      if (sortOrder != null && sortOrder!.isNotEmpty) 'sortOrder': sortOrder,
      'searchFieldParams':
          searchFieldParams.map((e) => e.toJson()).toList(growable: false),
      'param': param,
    };
  }
}

class SearchFieldParam {
  const SearchFieldParam({
    required this.fieldKey,
    required this.fieldOperator,
    required this.fieldCondition,
    required this.fieldValue,
  });

  final String fieldKey;
  final String fieldOperator;
  final String fieldCondition;
  final String fieldValue;

  Map<String, dynamic> toJson() => {
        'fieldKey': fieldKey,
        'fieldOperator': fieldOperator,
        'fieldCondition': fieldCondition,
        'fieldValue': fieldValue,
      };
}

class MyComplaintsPageResult {
  const MyComplaintsPageResult({
    required this.total,
    required this.records,
  });

  final int total;
  final List<Complaint> records;
}
