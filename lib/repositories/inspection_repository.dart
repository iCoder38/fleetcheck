import 'package:dio/dio.dart';
import '../core/network/api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/inspection_model.dart';
import '../models/driver_model.dart';

class InspectionRepository {
  final ApiService _api;
  InspectionRepository({ApiService? api}) : _api = api ?? ApiService();

  Future<ApiResult<QrData>> scanQr(String qrCodeString) async {
    return _api.call<QrData>(
      request: () => _api.post(ApiConstants.scanQr, data: {'qr_code': qrCodeString}),
      fromJson: (data) => QrData.fromJson(data['qr_data'] as Map<String, dynamic>),
    );
  }

  Future<ApiResult<InspectionResult>> submitInspection(InspectionSubmission submission) async {
    return _api.call<InspectionResult>(
      request: () => _api.post(ApiConstants.submitInspection, data: submission.toJson()),
      fromJson: (data) => InspectionResult.fromJson(data['inspection'] as Map<String, dynamic>),
    );
  }

  Future<ApiResult<List<InspectionResult>>> getInspections({
    String? dateRange,
    String? vehicleNumber,
    String? type,
    String? status,
    int page = 1,
  }) async {
    return _api.call<List<InspectionResult>>(
      request: () => _api.get(ApiConstants.inspectionList, params: {
        if (dateRange != null) 'date_range': dateRange,
        if (vehicleNumber != null) 'vehicle_number': vehicleNumber,
        if (type != null) 'type': type,
        if (status != null) 'status': status,
        'page': page,
      }),
      fromJson: (data) => (data['inspections'] as List)
          .map((e) => InspectionResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResult<Map<String, dynamic>>> getInspectionDetail(int id) async {
    return _api.call<Map<String, dynamic>>(
      request: () => _api.get(ApiConstants.inspectionDetail(id)),
      fromJson: (data) => data['inspection'] as Map<String, dynamic>,
    );
  }

  Future<ApiResult<DriverStats>> getDriverStats() async {
    return _api.call<DriverStats>(
      request: () => _api.get(ApiConstants.driverStats),
      fromJson: (data) => DriverStats.fromJson(data['stats'] as Map<String, dynamic>),
    );
  }

  Future<ApiResult<List<ActivityItem>>> getRecentActivity() async {
    return _api.call<List<ActivityItem>>(
      request: () => _api.get(ApiConstants.inspectionList, params: {'limit': 3, 'recent': 1}),
      fromJson: (data) => (data['inspections'] as List? ?? [])
          .map((e) => ActivityItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResult<List<NotificationModel>>> getNotifications() async {
    return _api.call<List<NotificationModel>>(
      request: () => _api.get(ApiConstants.notifications),
      fromJson: (data) => (data['notifications'] as List)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResult<bool>> markNotificationRead(int id) async {
    return _api.call<bool>(
      request: () => _api.post(ApiConstants.markNotifRead, data: {'id': id}),
      fromJson: (_) => true,
    );
  }

  Future<ApiResult<DriverModel>> updateProfile({
    String? phone,
    String? email,
    String? photoPath,
  }) async {
    return _api.call<DriverModel>(
      request: () async {
        if (photoPath != null) {
          final formData = FormData.fromMap({
            if (phone != null) 'phone': phone,
            if (email != null) 'email': email,
            'photo': await MultipartFile.fromFile(photoPath),
          });
          return _api.postFormData(ApiConstants.updateProfile, formData);
        }
        return _api.put(ApiConstants.updateProfile, data: {
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
        });
      },
      fromJson: (data) => DriverModel.fromJson(data['driver'] as Map<String, dynamic>),
    );
  }

  Future<ApiResult<bool>> updateFcmToken(String token) async {
    return _api.call<bool>(
      request: () => _api.post(ApiConstants.updateFcmToken, data: {'fcm_token': token}),
      fromJson: (_) => true,
    );
  }

  String getReportUrl(int id) =>
      '${ApiConstants.baseUrl}${ApiConstants.downloadReport(id)}';
}
