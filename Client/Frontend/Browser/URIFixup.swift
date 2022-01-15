// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared

class URIFixup {
    static func getURL(_ entry: String) -> URL? {
        if let url = URL(string: entry), InternalURL.isValid(url: url) {
            return URL(string: entry)
        }

        let trimmed = entry.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let escaped = trimmed.addingPercentEncoding(withAllowedCharacters: .URLAllowed) else {
            return nil
        }

        // Then check if the URL includes a scheme. This will handle
        // all valid requests starting with "http://", "about:", etc.
        // However, we ensure that the scheme is one that is listed in
        // the official URI scheme list, so that other such search phrases
        // like "filetype:" are recognised as searches rather than URLs.
        if let url = punycodedURL(escaped), url.schemeIsValid {
            return url
        }

        // If there's no scheme, we're going to prepend "http://". First,
        // make sure there's at least one ".", or two ":"'s for IPv6, in the host. This means
        // we'll allow single-word searches (e.g., "foo") at the expense
        // of breaking single-word hosts without a scheme (e.g., "localhost").
        if trimmed.range(of: ".") == nil && trimmed.filter({ $0 == ":" }).count < 2 {
            return nil
        }

        if trimmed.range(of: " ") != nil {
            return nil
        }

        // If there is a ".", prepend "http://" and try again. Since this
        // is strictly an "http://" URL, we also require a host.
        if let url = punycodedURL("http://\(escaped)"), url.host != nil {
            return url
        }

        return nil
    }

    static func punycodedURL(_ string: String) -> URL? {
        var string = string
        if !string.filter({ $0 == "#" }).isEmpty {
            string = replaceHashMarks(url: string)
        }

        if !string.filter({ $0 == "[" || $0 == "]" }).isEmpty {
            string = replaceBrackets(url: string)
        }

        guard let url = URL(string: string) else { return nil }

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if AppConstants.MOZ_PUNYCODE {
            let host = components?.host?.utf8HostToAscii()
            components?.host = host
        }
        return components?.url
    }

    static func replaceBrackets(url: String) -> String {
        var url = url
        let firstOpenIndex = url.firstIndex(of: "[")
        let firstCloseIndex = url.firstIndex(of: "]")
        if firstOpenIndex == nil && firstCloseIndex == nil { return url }
        if let firstOpenIndex = firstOpenIndex {
            let start = url.index(firstOpenIndex, offsetBy: 1)
            url = url.replacingOccurrences(of: "[", with: "%5B", range: start..<url.endIndex)
        }
        if let firstCloseIndex = firstCloseIndex {
            let start = url.index(firstCloseIndex, offsetBy: 1)
            url = url.replacingOccurrences(of: "]", with: "%5D", range: start..<url.endIndex)
        }
        return url
    }

    static func replaceHashMarks(url: String) -> String {
        guard let firstIndex = url.firstIndex(of: "#") else { return String() }
        let start = url.index(firstIndex, offsetBy: 1)
        return url.replacingOccurrences(of: "#", with: "%23", range: start..<url.endIndex)
    }
}
