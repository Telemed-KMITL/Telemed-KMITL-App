import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kmitl_telemedicine/kmitl_telemedicine.dart';
import 'package:kmitl_telemedicine_staff/providers.dart';
import 'package:kmitl_telemedicine_staff/utils/user_search_filter.dart';
import 'package:kmitl_telemedicine_staff/views/create_user_record_dialog.dart';
import 'package:kmitl_telemedicine_staff/views/user_list_internal_view.dart';

class _AddFilterPopup extends StatefulWidget {
  const _AddFilterPopup({super.key, this.onAdd});

  final void Function(UserSearchFilter)? onAdd;

  @override
  State<_AddFilterPopup> createState() => _AddFilterPopupState();
}

class _AddFilterPopupState extends State<_AddFilterPopup> {
  String? _selectedFieldName;
  UserFilterCondition? _selectedCondition;
  Object? _selectedValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: const BorderRadius.all(
          Radius.circular(5),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Add Filter", style: Theme.of(context).textTheme.titleMedium),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildFieldSelector(),
                const SizedBox(width: 10),
                _buildConditionSelector(),
                const SizedBox(width: 10),
                Flexible(flex: 1, child: _buildValueInput()),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: _selectedFieldName != null &&
                        _selectedCondition != null &&
                        _selectedValue != null
                    ? () => widget.onAdd?.call(UserSearchFilter(
                          _selectedFieldName!,
                          _selectedCondition!,
                          _selectedValue,
                        ))
                    : null,
                child: const Text("Add"),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFieldSelector() {
    return _buildDropdownFromChoice(
      choices: UserSearchFilter.fieldNames.map((e) => (e, e)),
      value: _selectedFieldName,
      onChanged: (field) => setState(
        () {
          if (field != null) {
            _selectedValue = null;
            _selectedFieldName = field;
          }
        },
      ),
      hint: const Text("Field"),
    );
  }

  Widget _buildConditionSelector() {
    return _buildDropdownFromChoice<UserFilterCondition>(
      choices:
          UserSearchFilter.conditionNames.entries.map((e) => (e.key, e.value)),
      value: _selectedCondition,
      onChanged: (condition) => setState(() {
        if (condition != null) {
          _selectedValue = null;
          _selectedCondition = condition;
        }
      }),
      hint: const Text("Condition"),
    );
  }

  Widget _buildValueInput() {
    if (_selectedFieldName == null || _selectedCondition == null) {
      return _buildValueTextField(false);
    }

    Type valueType = UserSearchFilter.getValueType(
      _selectedFieldName!,
      _selectedCondition!,
    );

    switch (valueType) {
      case UserSortDirection:
        return _buildDropdownFromChoice<UserSortDirection>(
          choices: UserSortDirection.values.map((e) => (e, e.name)),
          value: _selectedValue as UserSortDirection?,
          onChanged: (value) => setState(() {
            if (value != null) {
              _selectedValue = value;
            }
          }),
          hint: const Text("Value"),
        );
      case UserRole:
        return _buildDropdownFromChoice<UserRole>(
          choices: UserRole.values.map((e) => (e, e.name)),
          value: _selectedValue as UserRole?,
          onChanged: (value) => setState(() {
            if (value != null) {
              _selectedValue = value;
            }
          }),
          hint: const Text("Value"),
        );
      case UserStatus:
        return _buildDropdownFromChoice<UserStatus>(
          choices: UserStatus.values.map((e) => (e, e.name)),
          value: _selectedValue as UserStatus?,
          onChanged: (value) => setState(() {
            if (value != null) {
              _selectedValue = value;
            }
          }),
          hint: const Text("Value"),
        );
      case String:
        return _buildValueTextField(true);
      case DateTime:
        return TextField(
          decoration: const InputDecoration(
            isDense: true,
            hintText: "Value",
          ),
          onChanged: (value) => setState(() {
            _selectedValue = DateTime.tryParse(value);
          }),
        );
    }
    throw UnimplementedError();
  }

  Widget _buildValueTextField(bool enabled) {
    return TextField(
      decoration: const InputDecoration(
        isDense: true,
        hintText: "Value",
      ),
      onChanged: (value) => setState(() {
        _selectedValue = value;
      }),
      enabled: enabled,
    );
  }

  Widget _buildDropdownFromChoice<T>({
    required Iterable<(T, String)> choices,
    required T? value,
    void Function(T?)? onChanged,
    Widget? hint,
  }) {
    return DropdownButton<T>(
      isDense: true,
      value: value,
      items: choices
          .map((choice) => DropdownMenuItem(
                value: choice.$1,
                child: Text(choice.$2),
              ))
          .toList(),
      onChanged: onChanged,
      hint: hint,
    );
  }
}

class UserListView extends ConsumerStatefulWidget {
  const UserListView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _UserListViewState();
}

class _UserListViewState extends ConsumerState<UserListView> {
  final StateProvider<List<UserSearchFilter>> _searchFilterProvider =
      StateProvider(
    (ref) => [],
  );

  final _addFilterLayerLink = LayerLink();
  final OverlayPortalController _addFilterPopupController =
      OverlayPortalController();

  UserSearchFilter? _sortFilter;
  final List<UserSearchFilter> _searchFilters = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: const BorderRadius.all(
          Radius.circular(10),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            _buildInternalView(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          CompositedTransformTarget(
            link: _addFilterLayerLink,
            child: OverlayPortal(
              controller: _addFilterPopupController,
              overlayChildBuilder: (context) => CompositedTransformFollower(
                link: _addFilterLayerLink,
                targetAnchor: Alignment.bottomLeft,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: _AddFilterPopup(
                    onAdd: (filter) {
                      _addFilterPopupController.hide();
                      _addFilter(filter);
                      _refresh();
                    },
                  ),
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.filter_alt),
                onPressed: () => _addFilterPopupController.toggle(),
              ),
            ),
          ),
          Expanded(
            child: _buildFilterChipList(),
          ),
          if (ref
                  .watch(firebaseTokenProvider(false))
                  .valueOrNull
                  ?.claims?["role"] ==
              UserRole.admin.name)
            ElevatedButton(
              onPressed: _addUser,
              child: const Text("Add User"),
            ),
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChipList() {
    if (_sortFilter == null && _searchFilters.isEmpty) {
      return const Text("No Filters", style: TextStyle(color: Colors.grey));
    }
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        if (_sortFilter != null)
          InputChip(
            backgroundColor: Colors.orange.shade200,
            label: Text(_sortFilter!.toString()),
            onDeleted: () => setState(() {
              _sortFilter = null;
              _refresh();
            }),
          ),
        ..._searchFilters.map(
          (filter) => InputChip(
            label: Text(filter.toString()),
            onDeleted: () => setState(() {
              _searchFilters.remove(filter);
              _refresh();
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildInternalView() {
    return UserListInternalView(
      _searchFilterProvider,
      onSort: (fieldName, direction) {
        _addFilter(UserSearchFilter(
          fieldName,
          UserFilterCondition.orderBy,
          direction,
        ));
        _refresh();
      },
    );
  }

  void _refresh() {
    ref.read(_searchFilterProvider.notifier).state = [
      if (_sortFilter != null) _sortFilter!,
      ..._searchFilters,
    ];
  }

  void _addFilter(UserSearchFilter filter) {
    setState(() {
      if (filter.condition == UserFilterCondition.orderBy) {
        _sortFilter = filter;
      } else {
        _searchFilters.add(filter);
      }
    });
  }

  Future<void> _addUser() async {
    final result = await showDialog(
      context: context,
      builder: (context) => const CreateUserRecordDialog(),
    );
    if (result == true) {
      _refresh();
    }
  }
}
