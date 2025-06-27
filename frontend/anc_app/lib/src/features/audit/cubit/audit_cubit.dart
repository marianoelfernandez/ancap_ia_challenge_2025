import "package:anc_app/src/features/audit/services/audit_service.dart";
import "package:anc_app/src/models/audit_record.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:intl/intl.dart";
import "package:equatable/equatable.dart";
import "package:get_it/get_it.dart";

abstract class AuditState extends Equatable {
  const AuditState();

  @override
  List<Object?> get props => [];
}

class AuditInitial extends AuditState {
  const AuditInitial();
}

class AuditLoading extends AuditState {
  const AuditLoading();
}

class AuditLoaded extends AuditState {
  final List<AuditRecord> auditRecords;
  final List<AuditRecord> filteredRecords;
  final Set<String> selectedTableTags;
  final Set<String> selectedRoleTags;
  final String usernameFilter;
  final String roleFilter;
  final String dateFilter;
  final String tablesFilter;
  final String costFilter;

  const AuditLoaded({
    required this.auditRecords,
    required this.filteredRecords,
    required this.selectedTableTags,
    required this.selectedRoleTags,
    required this.usernameFilter,
    required this.roleFilter,
    required this.dateFilter,
    required this.tablesFilter,
    required this.costFilter,
  });

  AuditLoaded copyWith({
    List<AuditRecord>? auditRecords,
    List<AuditRecord>? filteredRecords,
    Set<String>? selectedTableTags,
    Set<String>? selectedRoleTags,
    String? usernameFilter,
    String? roleFilter,
    String? dateFilter,
    String? tablesFilter,
    String? costFilter,
  }) {
    return AuditLoaded(
      auditRecords: auditRecords ?? this.auditRecords,
      filteredRecords: filteredRecords ?? this.filteredRecords,
      selectedTableTags: selectedTableTags ?? this.selectedTableTags,
      selectedRoleTags: selectedRoleTags ?? this.selectedRoleTags,
      usernameFilter: usernameFilter ?? this.usernameFilter,
      roleFilter: roleFilter ?? this.roleFilter,
      dateFilter: dateFilter ?? this.dateFilter,
      tablesFilter: tablesFilter ?? this.tablesFilter,
      costFilter: costFilter ?? this.costFilter,
    );
  }

  @override
  List<Object?> get props => [
        auditRecords,
        filteredRecords,
        selectedTableTags,
        selectedRoleTags,
        usernameFilter,
        roleFilter,
        dateFilter,
        tablesFilter,
        costFilter,
      ];
}

class AuditError extends AuditState {
  final String message;

  const AuditError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuditCubit extends Cubit<AuditState> {
  final AuditService _auditService;

  AuditCubit([AuditService? auditService])
      : _auditService = auditService ?? GetIt.instance<AuditService>(),
        super(const AuditInitial());

  Future<void> fetchAuditRecords() async {
    emit(const AuditLoading());

    try {
      final result = await _auditService.getAuditRecords(
        page: 1,
        perPage: 100, // Fetch up to 100 records
      );

      result.match(
        (response) {
          emit(
            AuditLoaded(
              auditRecords: response.items,
              filteredRecords: response.items,
              selectedTableTags: {},
              selectedRoleTags: {},
              usernameFilter: "",
              roleFilter: "",
              dateFilter: "",
              tablesFilter: "",
              costFilter: "",
            ),
          );
        },
        (error) {
          emit(AuditError(error.toString()));
        },
      );
    } catch (e) {
      emit(AuditError("An unexpected error occurred: $e"));
    }
  }

  void applyFilters({
    String? usernameFilter,
    String? roleFilter,
    String? dateFilter,
    String? tablesFilter,
    String? costFilter,
  }) {
    final currentState = state;
    if (currentState is AuditLoaded) {
      final newUsernameFilter = usernameFilter ?? currentState.usernameFilter;
      final newRoleFilter = roleFilter ?? currentState.roleFilter;
      final newDateFilter = dateFilter ?? currentState.dateFilter;
      final newTablesFilter = tablesFilter ?? currentState.tablesFilter;
      final newCostFilter = costFilter ?? currentState.costFilter;

      final filteredRecords = currentState.auditRecords.where((record) {
        final usernameMatch = newUsernameFilter.isEmpty ||
            record.displayName
                .toLowerCase()
                .contains(newUsernameFilter.toLowerCase());

        final textRoleMatch = newRoleFilter.isEmpty ||
            record.role.toLowerCase().contains(newRoleFilter.toLowerCase());

        final tagRoleMatch = currentState.selectedRoleTags.isEmpty ||
            currentState.selectedRoleTags.contains(record.role);

        final dateMatch = newDateFilter.isEmpty ||
            DateFormat("yyyy-MM-dd")
                .format(record.date)
                .contains(newDateFilter);

        final textTablesMatch = newTablesFilter.isEmpty ||
            record.consultedTables.any(
              (table) =>
                  table.toLowerCase().contains(newTablesFilter.toLowerCase()),
            );

        final tagTablesMatch = currentState.selectedTableTags.isEmpty ||
            currentState.selectedTableTags.every(
              (tag) => record.consultedTables.contains(tag),
            );

        final costMatch = newCostFilter.isEmpty ||
            record.cost.toString().contains(newCostFilter);

        return usernameMatch &&
            textRoleMatch &&
            (currentState.selectedRoleTags.isEmpty || tagRoleMatch) &&
            dateMatch &&
            textTablesMatch &&
            (currentState.selectedTableTags.isEmpty || tagTablesMatch) &&
            costMatch;
      }).toList();

      emit(
        currentState.copyWith(
          filteredRecords: filteredRecords,
          usernameFilter: newUsernameFilter,
          roleFilter: newRoleFilter,
          dateFilter: newDateFilter,
          tablesFilter: newTablesFilter,
          costFilter: newCostFilter,
        ),
      );
    }
  }

  void clearAllFilters() {
    final currentState = state;
    if (currentState is AuditLoaded) {
      emit(
        currentState.copyWith(
          filteredRecords: currentState.auditRecords,
          selectedTableTags: {},
          selectedRoleTags: {},
          usernameFilter: "",
          roleFilter: "",
          dateFilter: "",
          tablesFilter: "",
          costFilter: "",
        ),
      );
    }
  }

  void addTableTag(String tag) {
    final currentState = state;
    if (currentState is AuditLoaded && tag.isNotEmpty) {
      final newTags = Set<String>.from(currentState.selectedTableTags);
      if (!newTags.contains(tag)) {
        newTags.add(tag);

        // Apply filters with the new tag
        final filteredRecords = currentState.auditRecords.where((record) {
          final usernameMatch = currentState.usernameFilter.isEmpty ||
              record.displayName
                  .toLowerCase()
                  .contains(currentState.usernameFilter.toLowerCase());

          final textRoleMatch = currentState.roleFilter.isEmpty ||
              record.role
                  .toLowerCase()
                  .contains(currentState.roleFilter.toLowerCase());

          final tagRoleMatch = currentState.selectedRoleTags.isEmpty ||
              currentState.selectedRoleTags.contains(record.role);

          final dateMatch = currentState.dateFilter.isEmpty ||
              DateFormat("yyyy-MM-dd")
                  .format(record.date)
                  .contains(currentState.dateFilter);

          final textTablesMatch = currentState.tablesFilter.isEmpty ||
              record.consultedTables.any(
                (table) => table
                    .toLowerCase()
                    .contains(currentState.tablesFilter.toLowerCase()),
              );

          final tagTablesMatch = newTags.isEmpty ||
              newTags.every(
                (tag) => record.consultedTables.contains(tag),
              );

          final costMatch = currentState.costFilter.isEmpty ||
              record.cost.toString().contains(currentState.costFilter);

          return usernameMatch &&
              textRoleMatch &&
              (currentState.selectedRoleTags.isEmpty || tagRoleMatch) &&
              dateMatch &&
              textTablesMatch &&
              (newTags.isEmpty || tagTablesMatch) &&
              costMatch;
        }).toList();

        emit(
          currentState.copyWith(
            filteredRecords: filteredRecords,
            selectedTableTags: newTags,
            tablesFilter: "",
          ),
        );
      }
    }
  }

  void removeTableTag(String tag) {
    final currentState = state;
    if (currentState is AuditLoaded) {
      final newTags = Set<String>.from(currentState.selectedTableTags);
      newTags.remove(tag);

      final filteredRecords = currentState.auditRecords.where((record) {
        final usernameMatch = currentState.usernameFilter.isEmpty ||
            record.displayName
                .toLowerCase()
                .contains(currentState.usernameFilter.toLowerCase());

        final textRoleMatch = currentState.roleFilter.isEmpty ||
            record.role
                .toLowerCase()
                .contains(currentState.roleFilter.toLowerCase());

        final tagRoleMatch = currentState.selectedRoleTags.isEmpty ||
            currentState.selectedRoleTags.contains(record.role);

        final dateMatch = currentState.dateFilter.isEmpty ||
            DateFormat("yyyy-MM-dd")
                .format(record.date)
                .contains(currentState.dateFilter);

        final textTablesMatch = currentState.tablesFilter.isEmpty ||
            record.consultedTables.any(
              (table) => table
                  .toLowerCase()
                  .contains(currentState.tablesFilter.toLowerCase()),
            );

        final tagTablesMatch = newTags.isEmpty ||
            newTags.every(
              (tag) => record.consultedTables.contains(tag),
            );

        final costMatch = currentState.costFilter.isEmpty ||
            record.cost.toString().contains(currentState.costFilter);

        return usernameMatch &&
            textRoleMatch &&
            (currentState.selectedRoleTags.isEmpty || tagRoleMatch) &&
            dateMatch &&
            textTablesMatch &&
            (newTags.isEmpty || tagTablesMatch) &&
            costMatch;
      }).toList();

      emit(
        currentState.copyWith(
          filteredRecords: filteredRecords,
          selectedTableTags: newTags,
        ),
      );
    }
  }

  void addRoleTag(String tag) {
    final currentState = state;
    if (currentState is AuditLoaded && tag.isNotEmpty) {
      final newTags = Set<String>.from(currentState.selectedRoleTags);
      if (!newTags.contains(tag)) {
        newTags.add(tag);

        // Apply filters with the new tag
        final filteredRecords = currentState.auditRecords.where((record) {
          final usernameMatch = currentState.usernameFilter.isEmpty ||
              record.displayName
                  .toLowerCase()
                  .contains(currentState.usernameFilter.toLowerCase());

          final textRoleMatch = currentState.roleFilter.isEmpty ||
              record.role
                  .toLowerCase()
                  .contains(currentState.roleFilter.toLowerCase());

          final tagRoleMatch = newTags.isEmpty || newTags.contains(record.role);

          final dateMatch = currentState.dateFilter.isEmpty ||
              DateFormat("yyyy-MM-dd")
                  .format(record.date)
                  .contains(currentState.dateFilter);

          final textTablesMatch = currentState.tablesFilter.isEmpty ||
              record.consultedTables.any(
                (table) => table
                    .toLowerCase()
                    .contains(currentState.tablesFilter.toLowerCase()),
              );

          final tagTablesMatch = currentState.selectedTableTags.isEmpty ||
              currentState.selectedTableTags.every(
                (tag) => record.consultedTables.contains(tag),
              );

          final costMatch = currentState.costFilter.isEmpty ||
              record.cost.toString().contains(currentState.costFilter);

          return usernameMatch &&
              textRoleMatch &&
              (newTags.isEmpty || tagRoleMatch) &&
              dateMatch &&
              textTablesMatch &&
              (currentState.selectedTableTags.isEmpty || tagTablesMatch) &&
              costMatch;
        }).toList();

        emit(
          currentState.copyWith(
            filteredRecords: filteredRecords,
            selectedRoleTags: newTags,
            roleFilter: "",
          ),
        );
      }
    }
  }

  void removeRoleTag(String tag) {
    final currentState = state;
    if (currentState is AuditLoaded) {
      final newTags = Set<String>.from(currentState.selectedRoleTags);
      newTags.remove(tag);

      // Apply filters without the removed tag
      final filteredRecords = currentState.auditRecords.where((record) {
        final usernameMatch = currentState.usernameFilter.isEmpty ||
            record.displayName
                .toLowerCase()
                .contains(currentState.usernameFilter.toLowerCase());

        final textRoleMatch = currentState.roleFilter.isEmpty ||
            record.role
                .toLowerCase()
                .contains(currentState.roleFilter.toLowerCase());

        final tagRoleMatch = newTags.isEmpty || newTags.contains(record.role);

        final dateMatch = currentState.dateFilter.isEmpty ||
            DateFormat("yyyy-MM-dd")
                .format(record.date)
                .contains(currentState.dateFilter);

        final textTablesMatch = currentState.tablesFilter.isEmpty ||
            record.consultedTables.any(
              (table) => table
                  .toLowerCase()
                  .contains(currentState.tablesFilter.toLowerCase()),
            );

        final tagTablesMatch = currentState.selectedTableTags.isEmpty ||
            currentState.selectedTableTags.every(
              (tag) => record.consultedTables.contains(tag),
            );

        final costMatch = currentState.costFilter.isEmpty ||
            record.cost.toString().contains(currentState.costFilter);

        return usernameMatch &&
            textRoleMatch &&
            (newTags.isEmpty || tagRoleMatch) &&
            dateMatch &&
            textTablesMatch &&
            (currentState.selectedTableTags.isEmpty || tagTablesMatch) &&
            costMatch;
      }).toList();

      emit(
        currentState.copyWith(
          filteredRecords: filteredRecords,
          selectedRoleTags: newTags,
        ),
      );
    }
  }

  void setDateFilter(String date) {
    applyFilters(dateFilter: date);
  }
}
