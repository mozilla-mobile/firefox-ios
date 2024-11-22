// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Object model to represent array of content blocking rules.
/// Currently this is not used (yet) since we load the JSON directly
/// in order to modify it in some cases before injecting to WKWebView.
struct ContentBlockingListRecord: RemoteDataTypeRecord {
}
