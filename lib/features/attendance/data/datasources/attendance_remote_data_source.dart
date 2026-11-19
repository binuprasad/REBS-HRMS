import 'package:rebs_hrms/core/constants/api_endpoints.dart';
import 'package:rebs_hrms/core/network/dio_client.dart';
import '../models/attendance_event_model.dart';
import '../models/attendance_record_model.dart';

abstract class AttendanceRemoteDataSource {
  Future<List<AttendanceRecordModel>> getAttendanceHistory({String? month});
  Future<Map<String, dynamic>> submitAttendanceEvent(AttendanceEventModel event);
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final DioClient dioClient;

  AttendanceRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<AttendanceRecordModel>> getAttendanceHistory({String? month}) async {
    final Map<String, dynamic> query = {};
    if (month != null && month.isNotEmpty) {
      query['month'] = month;
    }

    final response = await dioClient.get(
      ApiEndpoints.attendance,
      queryParameters: query.isNotEmpty ? query : null,
    );

    final data = response.data as Map<String, dynamic>;
    final recordsList = (data['records'] as List<dynamic>?) ?? [];
    return recordsList
        .map((r) => AttendanceRecordModel.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> submitAttendanceEvent(AttendanceEventModel event) async {
    final response = await dioClient.post(
      ApiEndpoints.attendanceEvents,
      data: event.toApiPayload(),
    );

    return Map<String, dynamic>.from(response.data as Map);
  }
}
