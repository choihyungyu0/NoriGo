import 'package:flutter/foundation.dart';
import 'package:norigo/features/my/data/my_page_repository.dart';
import 'package:norigo/features/my/domain/my_page_summary.dart';

class MyPageController extends ChangeNotifier {
  MyPageController({required MyPageRepository repository})
    : _repository = repository;

  final MyPageRepository _repository;

  MyPageSummary? _summary;
  bool _isLoading = false;

  MyPageSummary? get summary => _summary;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    try {
      _summary = await _repository.fetchSummary();
    } catch (_) {
      _summary = MyPageSummary.localPreview(
        errorMessage: 'Unable to load My Page right now.',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
