// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:devtools_shared/devtools_shared.dart';
import 'package:flutter/material.dart';

import '../../analytics/analytics.dart' as ga;
import '../../charts/treemap.dart';
import '../../config_specific/drag_and_drop/drag_and_drop.dart';
import '../../config_specific/server/server.dart' as server;
import '../../config_specific/url/url.dart';
import '../../primitives/auto_dispose_mixin.dart';
import '../../primitives/simple_items.dart';
import '../../primitives/utils.dart';
import '../../shared/common_widgets.dart';
import '../../shared/file_import.dart';
import '../../shared/globals.dart';
import '../../shared/screen.dart';
import '../../shared/split.dart';
import '../../shared/theme.dart';
import '../../shared/utils.dart';
import '../../ui/icons.dart';
import '../../ui/tab.dart';

const initialFractionForTreemap = 0.67;
const initialFractionForTreeTable = 0.33;

class DeeplinkScreen extends Screen {
  const DeeplinkScreen()
      : super.conditional(
          id: id,
          requiresDartVm: true,
          title: 'Deeplink',
          icon: Octicons.info,
        );

  static const testTabKey = Key('Test Tab');
  static const inventoryTabKey = Key('Inventory Tab');
  static const webValidationTabKey = Key('Web Validation Tab');

  /// The ID (used in routing) for the tabbed app-size page.
  ///
  /// This must be different to the top-level appSizePageId which is also used
  /// in routing when to ensure they have unique URLs.
  static const id = ScreenIds.deeplink;

  @visibleForTesting
  static const diffTypeDropdownKey = Key('Diff Tree Type Dropdown');

  @visibleForTesting
  static const appUnitDropdownKey = Key('App Segment Dropdown');

  @visibleForTesting
  static const analysisViewTreemapKey = Key('Analysis View Treemap');

  @visibleForTesting
  static const diffViewTreemapKey = Key('Diff View Treemap');

  static const loadingMessage =
      'Loading data...\nPlease do not refresh or leave this page.';

  @override
  String get docPageId => id;

  @override
  Widget build(BuildContext context) {
    // Since `handleDrop` is not specified for this [DragAndDrop] widget, drag
    // and drop events will be absorbed by it, meaning drag and drop actions
    // will be a no-op if they occur over this area. [DragAndDrop] widgets
    // lower in the tree will have priority over this one.
    return const DragAndDrop(child: DeeplinkBody());
  }
}

class DeeplinkBody extends StatefulWidget {
  const DeeplinkBody();

  @override
  _DeeplinkBodyState createState() => _DeeplinkBodyState();
}

class _DeeplinkBodyState extends State<DeeplinkBody>
    with
        AutoDisposeMixin,
        SingleTickerProviderStateMixin{
  static const _gaPrefix = 'deeplinkTab';
  static final inventoryTab = DevToolsTab.create(
    tabName: 'Inventory',
    gaPrefix: _gaPrefix,
    key: DeeplinkScreen.inventoryTabKey,
  );
  static final testTab = DevToolsTab.create(
    tabName: 'Test',
    gaPrefix: _gaPrefix,
    key: DeeplinkScreen.testTabKey,
  );

  static final webValidationTab = DevToolsTab.create(
    tabName: 'Web Validation',
    gaPrefix: _gaPrefix,
    key: DeeplinkScreen.webValidationTabKey,
  );
  static final tabs = [testTab, inventoryTab, webValidationTab];

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    ga.screen(DeeplinkScreen.id);
    _tabController = TabController(length: tabs.length, vsync: this);
    addAutoDisposeListener(_tabController);
  }

  // Future<void> maybeLoadAppSizeFiles() async {
  //   final queryParams = loadQueryParams();
  //   final baseFilePath = queryParams[baseAppSizeFilePropertyName];
  //   if (baseFilePath != null) {
  //     // TODO(kenz): does this have to be in a setState()?
  //     _preLoadingData = true;
  //     final baseAppSizeFile = await server.requestBaseAppSizeFile(baseFilePath);
  //     DevToolsJsonFile? testAppSizeFile;
  //     final testFilePath = queryParams[testAppSizeFilePropertyName];
  //     if (testFilePath != null) {
  //       testAppSizeFile = await server.requestTestAppSizeFile(testFilePath);
  //     }
  //
  //     // TODO(kenz): add error handling if the files are null
  //     if (baseAppSizeFile != null) {
  //       if (testAppSizeFile != null) {
  //         controller.loadDiffTreeFromJsonFiles(
  //           oldFile: baseAppSizeFile,
  //           newFile: testAppSizeFile,
  //           onError: _pushErrorMessage,
  //         );
  //         _tabController.animateTo(tabs.indexOf(inventoryTab));
  //       } else {
  //         controller.loadTreeFromJsonFile(
  //           jsonFile: baseAppSizeFile,
  //           onError: _pushErrorMessage,
  //         );
  //         _tabController.animateTo(tabs.indexOf(testTab));
  //       }
  //     }
  //   }
  //   if (_preLoadingData) {
  //     setState(() {
  //       _preLoadingData = false;
  //     });
  //   }
  // }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  // void _pushErrorMessage(String error) {
  //   if (mounted) notificationService.push(error);
  // }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // if (!initController()) return;
    //
    // unawaited(maybeLoadAppSizeFiles());
    //
    // addAutoDisposeListener(controller.activeDiffTreeType);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: defaultButtonHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TabBar(
                labelColor: Theme.of(context).textTheme.bodyLarge!.color,
                isScrollable: true,
                controller: _tabController,
                tabs: tabs,
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            physics: defaultTabBarViewPhysics,
            controller: _tabController,
            children: const [
              TestView(),
              IventoryView(),
              WebValidationView(),
            ],
          ),
        ),
      ],
    );
  }
}

class WebValidationView extends StatefulWidget {
  const WebValidationView();

  // TODO(kenz): add links to documentation on how to generate these files, and
  // mention the import file button once it is hooked up to a file picker.
  static const importInstructions = 'Drag and drop an AOT snapshot or'
      ' size analysis file for debugging';

  @override
  _WebValidationViewState createState() => _WebValidationViewState();
}

class _WebValidationViewState extends State<WebValidationView>
    with
        AutoDisposeMixin {
  TreemapNode? analysisRoot;


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 50),
        Text.rich(TextSpan(text: 'Web Domain: ', style:TextStyle(fontSize: 30), children: [TextSpan(text: 'myapp.com', style: TextStyle(fontStyle: FontStyle.italic))]),
        ),
        SizedBox(height: 50),
        Text.rich(TextSpan(text: 'assetlink.json Check', style: TextStyle(fontSize: 20))),
        Divider(),
        Row(children: [SizedBox(width: 500, child:Text('Accessible')), Icon(Icons.check)],),
        Divider(),
        Row(children: [SizedBox(width: 500, child:Text('No Redirect')), Icon(Icons.info)],),
        Divider(),
        Row(children: [SizedBox(width: 500, child:Text('Package id: ')), Text('com.package.myapp')],),
        SizedBox(height: 50),
        Text.rich(TextSpan(text: 'apple-app-site-association Check', style: TextStyle(fontSize: 20))),
        Divider(),
        Row(children: [SizedBox(width: 500, child:Text('Accessible')), Icon(Icons.check)],),
        Divider(),
        Row(children: [SizedBox(width: 500, child:Text('No Redirect')), Icon(Icons.info)],),
        Divider(),
        Row(children: [SizedBox(width: 500, child:Text('Boundle id: ')), Text('com.package.myapp')],),

      ],
    );
  }
}

class TestView extends StatefulWidget {
  const TestView();

  // TODO(kenz): add links to documentation on how to generate these files, and
  // mention the import file button once it is hooked up to a file picker.
  static const importInstructions = 'Drag and drop an AOT snapshot or'
      ' size analysis file for debugging';

  @override
  _TestViewState createState() => _TestViewState();
}

class _TestViewState extends State<TestView>
    with
        AutoDisposeMixin {
  TreemapNode? analysisRoot;


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _buildImportFileView(),
        ),
      ],
    );
  }




  Widget _buildImportFileView() {
    return Column(
      children: [
        Flexible(
          child: Row(
        children: [
          Expanded(child: TextField(decoration: InputDecoration(
            hintText: 'Enter url to test...',

          ),),),
      Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: defaultSpacing),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => null,
              child: Text('Test'),
            ),
          ],
        ),
      ],
    ),
      ],
    )),
      ],
    );
  }
}

class IventoryView extends StatefulWidget {
  const IventoryView();

  // TODO(kenz): add links to documentation on how to generate these files, and
  // mention the import file button once it is hooked up to a file picker.
  static const importOldInstructions = 'Drag and drop an original (old) AOT '
      'snapshot or size analysis file for debugging';
  static const importNewInstructions = 'Drag and drop a modified (new) AOT '
      'snapshot or size analysis file for debugging';

  @override
  _IventoryViewState createState() => _IventoryViewState();
}

class _IventoryViewState extends State<IventoryView>
    with
        AutoDisposeMixin{
  TreemapNode? diffRoot;


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child:Padding(
    padding: EdgeInsets.symmetric(vertical: 50),
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 50),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      child: Column(
        children: [
          Row(children: [SizedBox(width: 100,),SizedBox(width: 500, child: Text('https://myapp.com/*')), Flexible(flex: 1, child: Icon(Icons.edit)),],),
          Divider(),
          Row(children: [SizedBox(width: 100,),SizedBox(width: 500, child: Text('https://myapp.com/subroute/*')), Flexible(flex: 1, child: Icon(Icons.edit)),],),
          Divider(),
          Row(children: [SizedBox(width: 100,),SizedBox(width: 500, child: Text('https://myapp.com/subroute/1')), Flexible(flex: 1, child: Icon(Icons.edit)),],),
        ],
      ),
    )
    )
        ),
      ],
    );
  }
}
