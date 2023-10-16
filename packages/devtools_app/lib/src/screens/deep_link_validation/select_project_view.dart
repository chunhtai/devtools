// Copyright 2023 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/material.dart';

import '../../shared/analytics/constants.dart' as gac;
import '../../shared/config_specific/server/server.dart' as server;
import '../../shared/directory_picker.dart';
import '../../shared/utils.dart';
import 'deep_links_controller.dart';
import 'deep_links_model.dart';

/// A View for selecting a Flutter project.
class SelectProjectView extends StatefulWidget {
  const SelectProjectView({super.key});

  @override
  State<SelectProjectView> createState() => _SelectProjectViewState();
}

class _SelectProjectViewState extends State<SelectProjectView>
    with ProvidedControllerMixin<DeepLinksController, SelectProjectView> {
  static const _kMessageSize = 24.0;
  bool _retrievingFlutterProject = false;
  String? _errorText;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initController()) return;
  }

  void _handleDirectoryPicked(String directory) async {
    setState(() {
      _retrievingFlutterProject = true;
      _errorText = null;
    });
    final List<String> androidVariants =
        await server.requestAndroidBuildVariants(directory);
    if (androidVariants.isEmpty) {
      setState(() {
        _errorText =
            "The path doesn't correspond to a Flutter project or include a Android sub-project, please pick a new Flutter project to continue.";
      });
    } else {
      controller.selectedProject.value =
          FlutterProject(path: directory, androidVariants: androidVariants);
    }
    setState(() {
      _retrievingFlutterProject = false;
    });
  }

  Widget _buildStatusBar(BuildContext context) {
    Widget? child;
    if (_retrievingFlutterProject) {
      child = const SizedBox(
        width: _kMessageSize,
        height: _kMessageSize,
        child: CircularProgressIndicator(),
      );
    } else if (_errorText != null) {
      final theme = Theme.of(context);
      child = SizedBox(
        height: _kMessageSize,
        child: Text(
          _errorText!,
          style: theme.textTheme.bodyMedium!
              .copyWith(color: theme.colorScheme.error),
        ),
      );
    } else {
      child = SizedBox(
        height: _kMessageSize,
        child: Text(
          'Pick a flutter project from your local file to check all deep links status',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).textTheme.displayLarge!.color,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(defaultSpacing),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStatusBar(context),
          DirectoryPicker(
            directoryPickerText: 'Choose project',
            gaScreen: gac.deeplink,
            gaSelectionImport: '',
            onDirectoryPicked: _handleDirectoryPicked,
            enabled: !_retrievingFlutterProject,
          ),
        ],
      ),
    );
  }
}
