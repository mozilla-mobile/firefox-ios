#!/bin/bash
#
#  Copyright 2017 Google Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

set -euo pipefail

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
CHEATSHEET_DIR=$(cd ../../docs/cheatsheet; pwd)
CHEATSHEET_HTML="$CHEATSHEET_DIR/cheatsheet.html"
CHEATSHEET_PNG="$CHEATSHEET_DIR/cheatsheet.png"

set -x

"$CHROME" --headless --hide-scrollbars --disable-gpu --screenshot="$CHEATSHEET_PNG" --window-size=1024,2550 "file://$CHEATSHEET_HTML"
