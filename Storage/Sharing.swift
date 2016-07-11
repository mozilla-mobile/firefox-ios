/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Shared

// A small structure to encapsulate all the possible data that we can get
// from an application sharing a web page or a URL.
public struct ShareItem {
    public let url: String
    public let title: String?
    public let favicon: Favicon?

    public init(url: String, title: String?, favicon: Favicon?) {
        self.url = url
        self.title = title
        self.favicon = favicon
    }

    // We only support sharing HTTP and HTTPS URLs.
    public var isShareable: Bool {
        return URL(string: url)?.isWebPage() ?? false
    }
}

public protocol ShareToDestination {
    func shareItem(_ item: ShareItem)
}
