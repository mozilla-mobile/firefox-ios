/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct ReaderModeUtils {

    static let DomainPrefixesToSimplify = ["www.", "mobile.", "m.", "blog."]

    static func simplifyDomain(_ domain: String) -> String {
        for prefix in DomainPrefixesToSimplify {
            if domain.hasPrefix(prefix) {
                return domain.substring(from: domain.characters.index(domain.startIndex, offsetBy: prefix.characters.count))
            }
        }
        return domain
    }

    static func generateReaderContent(_ readabilityResult: ReadabilityResult, initialStyle: ReaderModeStyle) -> String? {
        if let stylePath = Bundle.main.pathForResource("Reader", ofType: "css") {
            do {
                let css = try NSString(contentsOfFile: stylePath, encoding: String.Encoding.utf8.rawValue)
                if let tmplPath = Bundle.main.pathForResource("Reader", ofType: "html") {
                    do {
                        let tmpl = try NSMutableString(contentsOfFile: tmplPath, encoding: String.Encoding.utf8.rawValue)
                        tmpl.replaceOccurrences(of: "%READER-CSS%", with: css as String,
                            options: NSString.CompareOptions(), range: NSMakeRange(0, tmpl.length))

                        tmpl.replaceOccurrences(of: "%READER-STYLE%", with: initialStyle.encode(),
                            options: NSString.CompareOptions(), range: NSMakeRange(0, tmpl.length))

                        tmpl.replaceOccurrences(of: "%READER-DOMAIN%", with: simplifyDomain(readabilityResult.domain),
                            options: NSString.CompareOptions(), range: NSMakeRange(0, tmpl.length))

                        tmpl.replaceOccurrences(of: "%READER-URL%", with: readabilityResult.url,
                            options: NSString.CompareOptions(), range: NSMakeRange(0, tmpl.length))

                        tmpl.replaceOccurrences(of: "%READER-TITLE%", with: readabilityResult.title,
                            options: NSString.CompareOptions(), range: NSMakeRange(0, tmpl.length))

                        tmpl.replaceOccurrences(of: "%READER-CREDITS%", with: readabilityResult.credits,
                            options: NSString.CompareOptions(), range: NSMakeRange(0, tmpl.length))

                        tmpl.replaceOccurrences(of: "%READER-CONTENT%", with: readabilityResult.content,
                            options: NSString.CompareOptions(), range: NSMakeRange(0, tmpl.length))

                        return tmpl as String
                    } catch _ {
                    }
                }
            } catch _ {
            }
        }
        return nil
    }

    static func isReaderModeURL(_ url: URL) -> Bool {
        let scheme = url.scheme, host = url.host, path = url.path
        return scheme == "http" && host == "localhost" && path == "/reader-mode/page"
    }

    static func decodeURL(_ url: URL) -> URL? {
        if ReaderModeUtils.isReaderModeURL(url) {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false), queryItems = components.queryItems where queryItems.count == 1 {
                if let queryItem = queryItems.first, value = queryItem.value {
                    return URL(string: value)
                }
            }
        }
        return nil
    }

    static func encodeURL(_ url: URL?) -> URL? {
        let baseReaderModeURL: String = WebServer.sharedInstance.URL(forResource: "page", module: "reader-mode")
        if let absoluteString = url?.absoluteString {
            if let encodedURL = absoluteString.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) {
                if let aboutReaderURL = URL(string: "\(baseReaderModeURL)?url=\(encodedURL)") {
                    return aboutReaderURL
                }
            }
        }
        return nil
    }
}
