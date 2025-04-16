// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

/// This struct captures the response from the Readability.js code.
public struct ReadabilityResult {
    /// The `dir` global attribute is an enumerated attribute that indicates the directionality of the element's text
    enum Direction: String {
        /// Direction for languages that are written from the left to the right
        case leftToRight = "ltr"
        /// Direction for languages that are written from the right to the left
        case rightToLeft = "rtl"
        /// Direction base on the user agent algorithm, which uses a basic algorithm
        /// as it parses the characters inside the element until it finds a character
        /// with a strong directionality, then applies that directionality to the
        /// whole element
        case auto
    }
    public let content: String
    public let textContent: String
    public let title: String
    public let credits: String
    public let excerpt: String
    let byline: String
    let length: Int
    let language: String
    let siteName: String
    let direction: Direction

    public init?(object: AnyObject?) {
        guard let dict = object as? NSDictionary else { return nil }

        self.content = dict["content"] as? String ?? ""
        self.textContent = dict["textContent"] as? String ?? ""
        self.excerpt = dict["excerpt"] as? String ?? ""
        self.title = dict["title"] as? String ?? ""
        self.length = dict["length"] as? Int ?? .zero
        self.language = dict["language"] as? String ?? ""
        self.siteName = dict["siteName"] as? String ?? ""
        self.credits = dict["credits"] as? String ?? ""
        self.byline = dict["byline"] as? String ?? ""
        self.direction = Direction(rawValue: dict["dir"] as? String ?? "") ?? .auto
    }

    /// Initialize from a JSON encoded string
    init?(string: String) {
        guard let data = string.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(
                with: data,
                options: .fragmentsAllowed
              ) as? [String: Any],
              let content = object["content"] as? String,
              let title = object["title"] as? String,
              let credits = object["byline"] as? String
        else { return nil }

        self.content = content
        self.title = title
        self.credits = credits
        self.textContent = object["textContent"] as? String ?? ""
        self.excerpt = object["excerpt"] as? String ?? ""
        self.length = object["length"] as? Int ?? .zero
        self.language = object["language"] as? String ?? ""
        self.siteName = object["siteName"] as? String ?? ""
        self.byline = object["byline"] as? String ?? ""
        self.direction = Direction(rawValue: object["dir"] as? String ?? "") ?? .auto
    }

    /// Encode to a dictionary, which can then for example be json encoded
    func encode() -> [String: Any] {
        return [
            "content": content,
            "title": title,
            "credits": credits,
            "textContent": textContent,
            "excerpt": excerpt,
            "byline": byline,
            "length": length,
            "dir": direction.rawValue,
            "siteName": siteName,
            "lang": language
        ]
    }

    /// Encode to a JSON encoded string
    func encode() -> String {
        let dict: [String: Any] = self.encode()
        return dict.asString!
    }
}

// NSObject wrapper around ReadabilityResult Swift struct for adding into the NSCache
class ReadabilityResultWrapper: NSObject {
    let result: ReadabilityResult

    init(readabilityResult: ReadabilityResult) {
        self.result = readabilityResult
        super.init()
    }
}
