/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

enum MetadataKeys: String {
    case iconURL = "icon_url"
    case imageURL = "image_url"
    case pageURL = "url"
    case title = "title"
    case description = "description"
    case type = "type"
    case provider = "provider"
}

/*
 * Value types representing a page's metadata
 */
public struct PageMetadata {
    public let id: Int?
    public let siteURL: String
    public let mediaURL: String?
    public let iconURL: String?
    public let title: String?
    public let description: String?
    public let type: String?
    public let providerName: String?

    public init(id: Int?, siteURL: String, mediaURL: String?, iconURL: String?, title: String?, description: String?, type: String?, providerName: String?) {
        self.id = id
        self.siteURL = siteURL
        self.mediaURL = mediaURL
        self.iconURL = iconURL
        self.title = title
        self.description = description
        self.type = type
        self.providerName = providerName
    }

    public static func fromDictionary(_ dict: [String: Any]) -> PageMetadata? {
        guard let siteURL = dict[MetadataKeys.pageURL.rawValue] as? String else {
            return nil
        }

        return PageMetadata(id: nil, siteURL: siteURL, mediaURL: dict[MetadataKeys.imageURL.rawValue] as? String, iconURL: dict[MetadataKeys.iconURL.rawValue] as? String,
                            title: dict[MetadataKeys.title.rawValue] as? String, description: dict[MetadataKeys.description.rawValue] as? String,
                            type: dict[MetadataKeys.type.rawValue] as? String, providerName: dict[MetadataKeys.provider.rawValue] as? String)
    }
}
