import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

class ReportProvider extends ChangeNotifier {
  ReportProvider({StorageService? service})
      : _service = service ?? StorageService();

  final StorageService _service;
  List<ReportModel> _reports = [];
  bool _isLoading = false;
  String? _error;

  List<ReportModel> get reports => List.unmodifiable(_reports);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadReports(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reports = await _service.getReports(userId: userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Asks the backend to compute the trend/top-author/top-journal PDF for
  /// [query] and upload it — no client-side PDF generation needed.
  Future<void> generateReport({
    required String userId,
    String? query,
    String? topicId,
  }) async {
    try {
      final result = await _service.generateReport(
        userId: userId,
        query: query,
        topicId: topicId,
      );
      if (result != null) {
        final newReport = ReportModel(
          reportId: result['reportId']?.toString() ?? '',
          userId: userId,
          topicId: result['topicId']?.toString() ?? topicId,
          reportType: result['reportType']?.toString(),
          fileUrl: result['fileUrl']?.toString(),
          createdAt: result['createdAt'] != null
              ? DateTime.tryParse(result['createdAt'].toString())
              : DateTime.now(),
        );
        _reports.insert(0, newReport);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
