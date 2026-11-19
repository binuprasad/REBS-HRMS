import '../entities/dashboard_data.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardDataUseCase {
  final DashboardRepository repository;

  GetDashboardDataUseCase(this.repository);

  Future<DashboardData> execute({bool forceRefresh = false}) {
    return repository.getDashboardData(forceRefresh: forceRefresh);
  }
}
