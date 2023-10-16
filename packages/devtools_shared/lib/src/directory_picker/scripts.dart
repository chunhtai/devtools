const macScript = r'''
#!/bin/bash

# Copyright 2018 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Fast fail the script on failures.
set -ex

osascript -e '
  tell application (path to frontmost application as text)
    set flutterFolder to choose folder with prompt "Select a Flutter project"
    return (POSIX path of flutterFolder)
  end tell
'
''';
