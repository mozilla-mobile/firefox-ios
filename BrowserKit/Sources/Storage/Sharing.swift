// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared

// A small structure to encapsulate all the possible data that we can get
// from an application sharing a web page or a URL.
public struct ShareItem: Equatable {
    public let url: String
    public let title: String?

    public init(url: String, title: String?) {
        self.url = url
        self.title = title
    }

    // We only support sharing HTTP and HTTPS URLs, as well as data URIs.
    public var isShareable: Bool {
        return URL(string: url, invalidCharacters: false)?.isWebPage() ?? false
    }
}
