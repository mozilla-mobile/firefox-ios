// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct Page: Codable {
    public let url: URL
    public let title: String

    public init(url: URL, title: String) {
        self.url = url
        self.title = title
    }
}
