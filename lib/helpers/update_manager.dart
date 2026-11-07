import 'dart:convert';

import 'package:get/get.dart';

import '../models/github.dart';
import '../services/request_service.dart';
import '../utils/constants.dart';

enum UpdateStatus { unknown, checking, current, available, failed }

/// Owns the result of the app update check for all screens.
class UpdateManager extends GetxController {
  UpdateManager({RequestService? requestService})
      : _requestService = requestService;

  final RequestService? _requestService;
  UpdateStatus _status = UpdateStatus.unknown;
  String? _downloadLink;

  UpdateStatus get status => _status;
  String? get downloadLink => _downloadLink;
  bool get isUpdateAvailable => _status == UpdateStatus.available;

  Future<void> checkForUpdate() async {
    _status = UpdateStatus.checking;
    update();
    try {
      final response = await (_requestService ?? Get.find<RequestService>())
          .requestGitHubUpdate(latestRelease);
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Release response was not an object.');
      }
      final release = Github.fromJson(decoded);
      final link = release.downloadLink?.trim();
      if (version == release.version.toString().trim() ||
          link == null ||
          link.isEmpty) {
        _status = UpdateStatus.current;
        _downloadLink = null;
      } else {
        _status = UpdateStatus.available;
        _downloadLink = link;
      }
    } catch (_) {
      _status = UpdateStatus.failed;
      _downloadLink = null;
    }
    update();
  }
}
