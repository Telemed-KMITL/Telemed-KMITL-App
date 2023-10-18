import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kmitl_telemedicine/kmitl_telemedicine.dart';
import 'package:kmitl_telemedicine/utils/date_time_extension.dart';
import 'package:kmitl_telemedicine_staff/utils/user_search_filter.dart';

typedef UserListSortCallback = void Function(
  String fieldName,
  UserSortDirection direction,
);

class UserListInternalView extends ConsumerStatefulWidget {
  const UserListInternalView(
    this.searchFilterProvider, {
    this.pageSize = 20,
    this.onSort,
    super.key,
  });

  final StateProvider<List<UserSearchFilter>> searchFilterProvider;
  final int pageSize;
  final UserListSortCallback? onSort;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _UserListInternalViewState();
}

class _UserListInternalViewState extends ConsumerState<UserListInternalView> {
  @override
  void initState() {
    super.initState();
    _queryProvider = Provider((ref) {
      try {
        final result = _buildQuery(ref.watch(widget.searchFilterProvider));
        return result;
      } catch (e) {
        ref.read(_errorMessageProvider.notifier).state = e.toString();
        return null;
      }
    });
    _currentPageQueryProvider = StateProvider(
      (ref) =>
          _buildFirstPageQuery(ref.read(_queryProvider), updateCache: true),
    );
    _currentPageSnapshotProvider = FutureProvider((ref) async {
      // When success to get data, clear error message
      ref.listenSelf((_, status) {
        if (!status.hasError && status.hasValue) {
          ref.read(_errorMessageProvider.notifier).state = null;
        }
      });

      final query = ref.watch(_currentPageQueryProvider);
      return query == null ? const [] : (await query.get()).docs;
    });
  }

  late final Provider<Query<User>?> _queryProvider;
  late final StateProvider<Query<User>?> _currentPageQueryProvider;
  late final FutureProvider<List<DocumentSnapshot<User>>>
      _currentPageSnapshotProvider;

  final StateProvider<String?> _errorMessageProvider = StateProvider(
    (ref) => null,
  );

  Query<User>? _prevPageQueryCache;
  Query<User>? _nextPageQueryCache;

  //--- UI ---//

  @override
  Widget build(BuildContext context) {
    // If query changed, move to first page
    ref.listen(_queryProvider, (_, query) {
      ref.read(_currentPageQueryProvider.notifier).state =
          _buildFirstPageQuery(query, updateCache: true);
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                maxWidth: ref.watch(_errorMessageProvider) == null &&
                        !ref.watch(_currentPageSnapshotProvider).hasError
                    ? double.infinity
                    : constraints.maxWidth,
              ),
              child: _buildUserListView(),
            ),
          );
        }),
        const Divider(
          height: 1,
        ),
        _buildFooter(),
      ],
    );
  }

  Widget _buildFooter() {
    return Consumer(builder: (context, ref, _) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed:
                _canMoveToPrevPage(ref) ? () => _moveToPrevPage(ref) : null,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed:
                _canMoveToNextPage(ref) ? () => _moveToNextPage(ref) : null,
          ),
        ],
      );
    });
  }

  Widget _buildUserListView() {
    String? errorMessage = ref.watch(_errorMessageProvider);
    final snapshot = ref.watch(_currentPageSnapshotProvider);
    return snapshot.when(
      data: (data) => errorMessage == null
          ? _buildUserTable(ref, data)
          : _buildErrorMessageView(errorMessage),
      error: (error, stackTrace) => _buildErrorMessageView(error.toString()),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  DataTable _buildUserTable(
      WidgetRef ref, List<DocumentSnapshot<User>> snapshot) {
    const column2fieldMap = <String, List<String>>{
      "ID": ["id"],
      "Role": ["role"],
      "Name": ["firstName", "lastName"],
      "HN": ["HN"],
      "Status": ["status"],
      "UpdatedAt": ["updatedAt"],
    };
    final sortFilter = ref
        .watch(widget.searchFilterProvider)
        .where((filter) => filter.condition == UserFilterCondition.orderBy)
        .firstOrNull;

    int? sortColumnIndex;
    bool sortAscending = false;
    if (sortFilter != null) {
      for (var (i, fields) in column2fieldMap.values.indexed) {
        if (fields.contains(sortFilter.fieldName)) {
          sortColumnIndex = i;
          sortAscending = (sortFilter.value as UserSortDirection) ==
              UserSortDirection.ascending;
        }
      }
    }

    return DataTable(
      dataRowColor: MaterialStateProperty.all(Colors.white),
      headingTextStyle: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
      headingRowHeight: 40,
      columns: column2fieldMap.keys
          .map(
            (columnName) => DataColumn(
              label: Text(columnName),
              onSort: widget.onSort == null
                  ? null
                  : (columnIndex, ascending) {
                      final fieldName = sortColumnIndex == columnIndex
                          ? sortFilter!.fieldName
                          : column2fieldMap.values.elementAt(columnIndex).first;
                      widget.onSort!(
                        fieldName,
                        ascending
                            ? UserSortDirection.ascending
                            : UserSortDirection.descending,
                      );
                    },
            ),
          )
          .toList(),
      sortColumnIndex: sortColumnIndex,
      sortAscending: sortAscending,
      rows: snapshot.map(
        (snapshot) {
          final data = snapshot.data()!;
          return DataRow(
            cells: [
              DataCell(Text(snapshot.id)),
              DataCell(Text(data.role.name)),
              DataCell(Text(data.getDisplayName())),
              DataCell(Text(data.HN ?? "null")),
              DataCell(Text(data.status.name)),
              DataCell(
                Text(data.updatedAt?.toShortTimestampString() ?? "null"),
              ),
            ],
          );
        },
      ).toList(),
    );
  }

  Widget _buildErrorMessageView(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.error_outline),
            const SizedBox(height: 10),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }

  //--- Util ---//

  bool _canMoveToPrevPage(WidgetRef ref) {
    final currentPageSnapshot = ref.watch(_currentPageSnapshotProvider).value;
    return (currentPageSnapshot != null && currentPageSnapshot.isNotEmpty) ||
        _prevPageQueryCache != null;
  }

  bool _canMoveToNextPage(WidgetRef ref) {
    final currentPageSnapshot = ref.watch(_currentPageSnapshotProvider).value;
    return (currentPageSnapshot != null && currentPageSnapshot.isNotEmpty) ||
        _nextPageQueryCache != null;
  }

  void _moveToPrevPage(WidgetRef ref) {
    ref.read(_currentPageQueryProvider.notifier).state =
        _buildPrevPageQuery(ref, updateCache: true);
  }

  void _moveToNextPage(WidgetRef ref) {
    ref.read(_currentPageQueryProvider.notifier).state =
        _buildNextPageQuery(ref, updateCache: true);
  }

  //--- Query ---//

  Query<User> _buildQuery(List<UserSearchFilter> filters) {
    Query<User> baseQuery = KmitlTelemedicineDb.users;
    for (final filter in filters) {
      baseQuery = filter.appendQuery(baseQuery);
    }
    return baseQuery;
  }

  Query<User>? _buildFirstPageQuery(Query<User>? query,
      {bool updateCache = false}) {
    final result = query?.limit(widget.pageSize);
    if (updateCache) {
      _prevPageQueryCache = null;
      _nextPageQueryCache = null;
    }
    return result;
  }

  Query<User> _buildPrevPageQuery(WidgetRef ref, {bool updateCache = false}) {
    assert(_canMoveToPrevPage(ref));

    final currentPageSnapshot = ref.read(_currentPageSnapshotProvider).value;

    DocumentSnapshot<User>? firstDoc = currentPageSnapshot?.firstOrNull;
    Query<User> prevPageQuery;
    if (firstDoc == null) {
      prevPageQuery = _prevPageQueryCache!;
      if (updateCache) {
        _prevPageQueryCache = null;
        _nextPageQueryCache = null;
      }
    } else {
      final currentPageQuery = ref.read(_currentPageQueryProvider)!;

      prevPageQuery = ref
          .read(_queryProvider)!
          .endBeforeDocument(firstDoc)
          .limit(widget.pageSize);
      if (updateCache) {
        _prevPageQueryCache = null;
        _nextPageQueryCache = currentPageQuery;
      }
    }

    return prevPageQuery;
  }

  Query<User> _buildNextPageQuery(WidgetRef ref, {bool updateCache = false}) {
    assert(_canMoveToNextPage(ref));

    final currentPageSnapshot = ref.read(_currentPageSnapshotProvider).value;

    DocumentSnapshot<User>? lastDoc = currentPageSnapshot?.lastOrNull;
    Query<User> nextPageQuery;
    if (lastDoc == null) {
      nextPageQuery = _nextPageQueryCache!;
      if (updateCache) {
        _prevPageQueryCache = null;
        _nextPageQueryCache = null;
      }
    } else {
      final currentPageQuery = ref.read(_currentPageQueryProvider)!;

      nextPageQuery = ref
          .read(_queryProvider)!
          .startAfterDocument(lastDoc)
          .limit(widget.pageSize);
      if (updateCache) {
        _prevPageQueryCache = currentPageQuery;
        _nextPageQueryCache = null;
      }
    }

    return nextPageQuery;
  }
}
