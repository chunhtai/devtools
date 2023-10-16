// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../shared/config_specific/server/server.dart' as server;

import 'common_widgets.dart';

class DirectoryPicker extends StatefulWidget {
  const DirectoryPicker({
    required this.gaScreen,
    required this.gaSelectionImport,
    required this.onDirectoryPicked,
    required this.directoryPickerText,
    this.enabled = true,
    this.gaSelectionAction,
    super.key,
  });

  /// The title of the directory picker button.
  final String? directoryPickerText;

  final bool enabled;

  final ValueChanged<String> onDirectoryPicked;

  final String gaScreen;

  final String gaSelectionImport;

  final String? gaSelectionAction;

  @override
  State<DirectoryPicker> createState() => _DirectoryPickerState();
}

class _DirectoryPickerState extends State<DirectoryPicker> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rowHeight = defaultButtonHeight;
    final bool displayDirectoryPickerButton;
    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
        displayDirectoryPickerButton = true;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.iOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        displayDirectoryPickerButton = false;
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        Flexible(
          flex: 4,
          fit: FlexFit.tight,
          child: RoundedOutlinedBorder(
            child: Container(
              height: rowHeight,
              padding: const EdgeInsets.symmetric(horizontal: defaultSpacing),
              child: _buildDirectoryDisplay(),
            ),
          ),
        ),
        if (displayDirectoryPickerButton) const SizedBox(width: denseSpacing),
        if (displayDirectoryPickerButton)
          DirectoryPickerButton(
            onPressed: _selectDirectory,
            gaScreen: widget.gaScreen,
            gaSelection: widget.gaSelectionImport,
          ),
        const Spacer(),
      ],
    );
  }

  void _selectDirectory() async {
    String? directoryPath = await server.requestLaunchDirectoryPicker();
    if (directoryPath == null) {
      // Operation was canceled by the user.
      return;
    }
    directoryPath = directoryPath.trim();
    controller.text = directoryPath;
    widget.onDirectoryPicked(directoryPath);
  }

  Widget _buildDirectoryDisplay() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            enabled: widget.enabled,
            onSubmitted: (String path) {
              widget.onDirectoryPicked(path.trim());
            },
            decoration: const InputDecoration(hintText: 'or enter path here.'),
            style: TextStyle(
              color: Theme.of(context).textTheme.displayLarge!.color,
            ),
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }
}

class DirectoryPickerButton extends StatelessWidget {
  const DirectoryPickerButton({
    super.key,
    required this.onPressed,
    required this.gaScreen,
    required this.gaSelection,
    this.elevatedButton = false,
  });

  final VoidCallback onPressed;
  final bool elevatedButton;
  final String gaScreen;
  final String gaSelection;

  @override
  Widget build(BuildContext context) {
    return GaDevToolsButton(
      onPressed: onPressed,
      icon: Icons.folder,
      label: 'Choose project',
      gaScreen: gaScreen,
      gaSelection: gaSelection,
      elevated: elevatedButton,
    );
  }
}
