// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// FXIOS-10189 This struct will be refactored into a generic UITableView solution later. For now, it is largely a clone of
// MenuKit's work. Eventually both this target and the MenuKit target will leverage a common reusable tableView component.
public struct SearchEngineSection: Equatable {
    public let options: [SearchEngineElement]

    public init(options: [SearchEngineElement]) {
        self.options = options
    }
}
