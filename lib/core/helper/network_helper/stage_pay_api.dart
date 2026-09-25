import 'dart:developer';

import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/stage_pay/data/models/stage_pay_models.dart';

List<T> _decodeList<T>(
  dynamic data,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (data is! List) return const [];
  return [
    for (final entry in data)
      if (entry is Map<String, dynamic>) fromJson(entry),
  ];
}

/// Stage-based pay transport (`StagePayController`), beside the other
/// per-module extensions on [ApiService].
extension StagePayApi on ApiService {
  /// `GET /StagePay/rates` — every restoration type with its stages' prices.
  Future<List<StagePayRestorationTypeModel>> getStagePayRates({
    String? token,
  }) async {
    log('Fetching stage pay rates');

    final data = await Api().get(url: 'StagePay/rates', token: token);
    return _decodeList(data, StagePayRestorationTypeModel.fromJson);
  }

  /// `PUT /StagePay/rates` — upserts the listed prices of one laboratory.
  Future<void> saveStagePayRates({
    required SaveStagePayRatesRequestModel body,
    String? token,
  }) async {
    log('Saving ${body.rates.length} stage pay rates');

    await Api().put(url: 'StagePay/rates', body: body.toJson(), token: token);
  }

  /// `GET /StagePay/earnings` — stages finished in a period, and what they
  /// paid. No [employeeId] means everyone.
  Future<List<EmployeeStageEarningModel>> getStageEarnings({
    required DateTime from,
    required DateTime to,
    String? employeeId,
    String? token,
  }) async {
    log('Fetching stage earnings');

    final query = [
      'from=${ApiTime.formatDate(from)}',
      'to=${ApiTime.formatDate(to)}',
      if (employeeId != null) 'employeeId=$employeeId',
    ].join('&');

    final data = await Api().get(url: 'StagePay/earnings?$query', token: token);
    return _decodeList(data, EmployeeStageEarningModel.fromJson);
  }

  /// `GET /StagePay/loss-preview` — the work a breakage send-back of this
  /// restoration to [targetStageId] would throw away.
  Future<LossPreviewModel> getLossPreview({
    required String caseId,
    required String restorationId,
    required String targetStageId,
    String? token,
  }) async {
    log('Fetching loss preview for restoration $restorationId');

    final data = await Api().get(
      url:
          'StagePay/loss-preview?caseId=$caseId&restorationId=$restorationId'
          '&targetStageId=$targetStageId',
      token: token,
    );
    return LossPreviewModel.fromJson(
      data as Map<String, dynamic>? ?? const {},
    );
  }
}
