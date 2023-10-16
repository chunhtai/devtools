// Copyright 2023 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:file/local.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import 'scripts.dart';

class DirectoryPickerManager {
  /// The key to retrieve error message from the returning map of this class's
  /// APIs.
  static const kErrorField = 'error';

  /// The key to retrieve output json from the returning map of this class's
  /// APIs.
  static const kOutputTextField = 'text';

  String get scriptRoot => path.dirname(Platform.script.path);

  Future<String> launchDirectoryPicker() {
    if (Platform.isMacOS) {
      return _launchDirectoryPickerMacOS();
    }
    throw UnimplementedError();
  }

  Future<String> _launchDirectoryPickerMacOS() async {
    // Write script into a temp file.
    final tempDirectory =
        const LocalFileSystem().systemTempDirectory.createTempSync('devtool');
    final scriptFile = tempDirectory.childFile('launch_directory_picker.sh');
    scriptFile.writeAsStringSync(macScript, flush: true);

    // Make sure the file is read/writeable.
    await runCommand('chmod', <String>['755', scriptFile.path]);
    return (await runCommand(scriptFile.path, const <String>[])).stdout;
  }

  @visibleForTesting
  Future<ProcessResult> runCommand(
    String executable,
    List<String> arguments,
  ) async {
    final result = await Process.run(executable, arguments);
    if (result.exitCode != 0) {
      throw _DirectoryPickerError(result.stderr);
    }
    return result;
  }
}

class _DirectoryPickerError extends Error {
  _DirectoryPickerError(this.message);

  /// The error message.
  final String message;

  @override
  String toString() => message;
}
