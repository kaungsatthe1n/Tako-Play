import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/github.dart';
import '../services/request_service.dart';
import '../utils/constants.dart';

enum UpdateStatus { unknown, checking, current, available, failed }

/// Owns the result of the app update check for all screens.
class UpdateManager extends GetxController {
  UpdateManager({RequestService? requestService, TargetPlatform? platform})
      : _requestService = requestService,
        _platform = platform ?? defaultTargetPlatform;

  final RequestService? _requestService;
  final TargetPlatform _platform;
  UpdateStatus _status = UpdateStatus.unknown;
  String? _downloadLink;
  bool _usesApkDownload = false;

  UpdateStatus get status => _status;
  String? get downloadLink => _downloadLink;
  bool get usesApkDownload => _usesApkDownload;
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
      final isAndroid = _platform == TargetPlatform.android;
      final apkLink = release.apkDownloadLink?.trim();
      final link = isAndroid
          ? apkLink ?? release.releasePageUrl ?? release.downloadLink
          : release.releasePageUrl ??
              release.downloadLink ??
              release.apkDownloadLink;
      if (release.isPrerelease ||
          release.isDraft ||
          release.version == null ||
          version == release.version!.trim() ||
          link == null ||
          link.isEmpty) {
        _status = UpdateStatus.current;
        _downloadLink = null;
        _usesApkDownload = false;
      } else {
        _status = UpdateStatus.available;
        _downloadLink = link;
        _usesApkDownload = isAndroid && apkLink != null;
      }
    } catch (_) {
      _status = UpdateStatus.failed;
      _downloadLink = null;
      _usesApkDownload = false;
    }
    update();
  }
}
