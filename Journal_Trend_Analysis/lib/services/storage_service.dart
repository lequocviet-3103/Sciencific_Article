import 'api_service.dart';

class StorageService {
  StorageService({ApiService? api}) : _api = api ?? ApiService();
  final ApiService _api;

  /// Backend computes the publication trend + top authors + top journals
  /// for papers matching [query] (or [topicId]), generates the PDF and
  /// uploads it to Firebase Storage server-side — the client only sends
  /// the search term.
  Future<Map<String, dynamic>?> generateReport({
    required String userId,
    String? query,
    String? topicId,
  }) async {
    final body = <String, dynamic>{
      'userId': userId,
      if (query != null) 'query': query,
      if (topicId != null) 'topicId': topicId,
    };
    return await _api.post('/api/reports/generate', body: body);
  }

  Future<List<ReportModel>> getReports({String? userId}) async {
    final params = userId != null ? {'userId': userId} : null;
    final list = await _api.getList('/api/reports', params: params);
    return list.map((e) => ReportModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}

class ReportModel {
  final String reportId;
  final String? userId;
  final String? topicId;
  final String? reportType;
  final String? fileUrl;
  final DateTime? createdAt;

  ReportModel({
    required this.reportId,
    this.userId,
    this.topicId,
    this.reportType,
    this.fileUrl,
    this.createdAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      reportId: json['reportId']?.toString() ?? json['report_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['user_id']?.toString(),
      topicId: json['topicId']?.toString() ?? json['topic_id']?.toString(),
      reportType: json['reportType']?.toString() ?? json['report_type']?.toString(),
      fileUrl: json['fileUrl']?.toString() ?? json['file_url']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
