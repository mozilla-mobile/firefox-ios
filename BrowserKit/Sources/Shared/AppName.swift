// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public enum AppName: String, CustomStringConvertible {
    case shortName = "Firefox"

    public var description: String {
        return self.rawValue
    }
}

public enum PocketAppName: String, CustomStringConvertible {
    case shortName = "Pocket"

    public var description: String {
        return self.rawValue
    }
}

public enum MozillaName: String, CustomStringConvertible {
    case shortName = "Mozilla"

    public var description: String {
        return self.rawValue
    }
}

public enum KVOConstants: String {
    case loading
    case estimatedProgress
    case URL
    case title
    case canGoBack
    case canGoForward
    case contentSize
    case hasOnlySecureContent
    case fullscreenState
}
