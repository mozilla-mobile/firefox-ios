/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

public class Site {
    public let guid: String
    public let url: String
    public let title: String

    public init(guid: String, url: String, title: String) {
        self.guid = guid
        self.url = url
        self.title = title
    }

    public convenience init(url: String, title: String) {
        let id = NSUUID().UUIDString       // TODO: make this a GUID!
        self.init(guid: id, url: url, title: title)
    }
}
