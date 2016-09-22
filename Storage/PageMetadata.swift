/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/*
 * Value types representing a page's metadata and associated images
 */
public struct PageMetadata {
    public let id: Int
    public let siteURL: String
    public let title: String?
    public let description: String?
    public let type: String?
    public let images: [PageMetadataImage]

    public init(id: Int, siteURL: String, title: String?, description: String?, type: String?, images: [PageMetadataImage] = []) {
        self.id = id
        self.siteURL = siteURL
        self.title = title
        self.description = description
        self.type = type
        self.images = images
    }
}

public enum MetadataImageType: Int {
    case Favicon = 1
    case RichFavicon = 2
    case Preview = 3
}

public struct PageMetadataImage {
    public let imageURL: String
    public let type: MetadataImageType
    public let height: Int
    public let width: Int
    public let color: String
}
