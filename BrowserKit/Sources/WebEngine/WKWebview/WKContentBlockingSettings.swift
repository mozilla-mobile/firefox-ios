// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

public struct WKContentBlockingSettings: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let standard = WKContentBlockingSettings(rawValue: 1 << 0)
    public static let strict = WKContentBlockingSettings(rawValue: 1 << 1)
    public static let noImages = WKContentBlockingSettings(rawValue: 1 << 2)
}
