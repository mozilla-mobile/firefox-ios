/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

public class InfoCollections {
    private let json: JSON

    init(json: JSON) {
        self.json = json
    }

    public func modified(collection: String) -> Int64? {
        return json[collection].asInt64
    }
}