import "package:anc_app/src/features/dashboard/services/charts_service.dart";
import "package:anc_app/src/models/chart.dart";
import "package:anc_app/src/models/errors/charts_error.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:equatable/equatable.dart";
import "package:flutter/foundation.dart";
import "package:get_it/get_it.dart";

class DashboardCubit extends Cubit<DashboardState> {
  final ChartsService _chartsService;

  DashboardCubit()
      : _chartsService = GetIt.instance<ChartsService>(),
        super(const DashboardInitial());

  Future<void> loadCharts({int page = 1, int perPage = 20}) async {
    emit(const DashboardLoading());

    final result = await _chartsService.getCharts(
      page: page,
      perPage: perPage,
    );

    result.when(
      ok: (charts) {
        emit(
          DashboardLoaded(
            charts: charts,
            currentPage: page,
            itemsPerPage: perPage,
          ),
        );
      },
      err: (error) {
        debugPrint("Error loading charts: $error");
        emit(DashboardError(error: error));
      },
    );
  }

  Future<void> deleteChart(String chartId) async {
    emit(const DashboardLoading());

    final result = await _chartsService.deleteChart(chartId);

    result.when(
      ok: (_) {
        loadCharts();
      },
      err: (error) {
        debugPrint("Error deleting chart: $error");
        emit(DashboardError(error: error));
      },
    );
  }
}

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final List<Chart> charts;
  final int currentPage;
  final int itemsPerPage;

  const DashboardLoaded({
    required this.charts,
    required this.currentPage,
    required this.itemsPerPage,
  });

  @override
  List<Object?> get props => [charts, currentPage, itemsPerPage];
}

class DashboardError extends DashboardState {
  final ChartsError error;

  const DashboardError({required this.error});

  @override
  List<Object?> get props => [error];
}
