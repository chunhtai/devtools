// Copyright 2023 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:devtools_shared/src/directory_picker/directory_picker.dart';
import 'package:devtools_shared/src/directory_picker/scripts.dart';
import 'package:test/test.dart';

void main() {
  test('getBuildVariants calls flutter command correctly', () async {
    final StubbedDirectoryPickerManager manager =
        StubbedDirectoryPickerManager();
    const expectedPath = '/somepath';
    manager.mockedResult = ProcessResult(0, 0, expectedPath, '');
    expect(await manager.launchDirectoryPicker(), expectedPath);
    expect(manager.runFileContent, macScript);
  });
}

class StubbedDirectoryPickerManager extends DirectoryPickerManager {
  String? runFileContent;
  ProcessResult? mockedResult;

  @override
  Future<ProcessResult> runCommand(
    String executable,
    List<String> arguments,
  ) async {
    if (executable == 'chmod') {
      return ProcessResult(0, 0, '', '');
    }
    runFileContent = await File(executable).readAsString();
    return mockedResult!;
  }
}

class TestCommand {
  const TestCommand({
    required this.executable,
    required this.arguments,
    required this.result,
  });
  final String executable;
  final List<String> arguments;
  final ProcessResult result;

  @override
  String toString() {
    return '"$executable ${arguments.join(' ')}"';
  }
}
