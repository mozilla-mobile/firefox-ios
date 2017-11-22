/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct ReaderModeUtils {

    static let DomainPrefixesToSimplify = ["www.", "mobile.", "m.", "blog."]

    static func simplifyDomain(_ domain: String) -> String {
        for prefix in DomainPrefixesToSimplify {
            if domain.hasPrefix(prefix) {
                return domain.substring(from: domain.index(domain.startIndex, offsetBy: prefix.count))
            }
        }
        return domain
    }

    static func generateReaderContent(_ readabilityResult: ReadabilityResult, initialStyle: ReaderModeStyle) -> String? {
        if let stylePath = Bundle.main.path(forResource: "Reader", ofType: "css") {
            do {
                let css = try String(contentsOfFile: stylePath, encoding: .utf8)
                if let tmplPath = Bundle.main.path(forResource: "Reader", ofType: "html") {
                    do {

                        let tmpl = try String(contentsOfFile: tmplPath, encoding: .utf8)
                        return tmpl.replacingOccurrences(of: "%READER-CSS%", with: css)
                                    .replacingOccurrences(of: "%READER-STYLE%", with: initialStyle.encode())
                                    .replacingOccurrences(of: "%READER-DOMAIN%", with: simplifyDomain(readabilityResult.domain))
                                    .replacingOccurrences(of: "%READER-URL%", with: readabilityResult.url)
                                    .replacingOccurrences(of: "%READER-TITLE%", with: readabilityResult.title)
                                    .replacingOccurrences(of: "%READER-CREDITS%", with: readabilityResult.credits)
                                    .replacingOccurrences(of: "%READER-CONTENT%", with: readabilityResult.content)

                    } catch _ {
                    }
                }
            } catch _ {
            }
        }
        return nil
    }
}
