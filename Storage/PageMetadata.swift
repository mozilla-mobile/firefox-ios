/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public struct PageMetadata {
    public let url: NSURL
    public let title: String?
    public let description: String?
    public let imageURL: NSURL?
    public let type: String?
    public let iconURL: NSURL?

    public init(url: NSURL, title: String?, description: String?, imageURL: NSURL?, type: String?, iconURL: NSURL?) {
        self.url = url
        self.title = title
        self.description = description
        self.imageURL = imageURL
        self.type = type
        self.iconURL = iconURL
    }
}
