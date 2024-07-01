// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

// Note: ClientAndTabs data structure contains all tabs under a remote client. To make traversal and search easier
// this wrapper combines them and is helpful in showing Remote Client and Remote tab in our SearchViewController
struct ClientTabsSearchWrapper: Equatable {
    var client: RemoteClient
    var tab: RemoteTab
}
