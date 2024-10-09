// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

enum MetadataKeys: String {
    case imageURL = "image"
    case imageDataURI = "image_data_uri"
    case pageURL = "url"
    case title = "title"
    case description = "description"
    case type = "type"
    case provider = "provider"
    case favicon = "icon"
    case keywords = "keywords"
    case language = "language"
}

/*
 * Value types representing a page's metadata
 */
public struct PageMetadata {
    public let id: Int?
    public let siteURL: String
    public let mediaURL: String?
    public let title: String?
    public let description: String?
    public let type: String?
    public let providerName: String?
    public let faviconURL: String?
    public let keywordsString: String?
    public let language: String?
    public var keywords: Set<String> {
        guard let string = keywordsString else {
            return Set()
        }

        let strings = string.split(separator: ",", omittingEmptySubsequences: true).map(String.init)
        return Set(strings)
    }

    public init(
        id: Int?,
        siteURL: String,
        mediaURL: String?,
        title: String?,
        description: String?,
        type: String?,
        providerName: String?,
        faviconURL: String? = nil,
        language: String? = nil,
        keywords: String? = nil
    ) {
        self.id = id
        self.siteURL = siteURL
        self.mediaURL = mediaURL
        self.title = title
        self.description = description
        self.type = type
        self.providerName = providerName
        self.faviconURL = faviconURL
        self.language = language
        self.keywordsString = keywords
    }

    public static func fromDictionary(_ dict: [String: Any]) -> PageMetadata? {
        guard let siteURL = dict[MetadataKeys.pageURL.rawValue] as? String else { return nil }

        return PageMetadata(
            id: nil,
            siteURL: siteURL,
            mediaURL: dict[MetadataKeys.imageURL.rawValue] as? String,
            title: dict[MetadataKeys.title.rawValue] as? String,
            description: dict[MetadataKeys.description.rawValue] as? String,
            type: dict[MetadataKeys.type.rawValue] as? String,
            providerName: dict[MetadataKeys.provider.rawValue] as? String,
            faviconURL: dict[MetadataKeys.favicon.rawValue] as? String,
            language: dict[MetadataKeys.language.rawValue] as? String,
            keywords: dict[MetadataKeys.keywords.rawValue] as? String)
    }
}
