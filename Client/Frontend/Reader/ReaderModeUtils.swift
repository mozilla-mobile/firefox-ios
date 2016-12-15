/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct ReaderModeUtils {

    static let DomainPrefixesToSimplify = ["www.", "mobile.", "m.", "blog."]

    static func simplifyDomain(domain: String) -> String {
        for prefix in DomainPrefixesToSimplify {
            if domain.hasPrefix(prefix) {
                return domain.substringFromIndex(domain.startIndex.advancedBy(prefix.characters.count))
            }
        }
        return domain
    }

    static func generateReaderContent(readabilityResult: ReadabilityResult, initialStyle: ReaderModeStyle) -> String? {
        if let stylePath = NSBundle.mainBundle().pathForResource("Reader", ofType: "css") {
            do {
                let css = try NSString(contentsOfFile: stylePath, encoding: NSUTF8StringEncoding)
                if let tmplPath = NSBundle.mainBundle().pathForResource("Reader", ofType: "html") {
                    do {
                        let tmpl = try NSMutableString(contentsOfFile: tmplPath, encoding: NSUTF8StringEncoding)
                        tmpl.replaceOccurrencesOfString("%READER-CSS%", withString: css as String,
                            options: NSStringCompareOptions(), range: NSMakeRange(0, tmpl.length))

                        tmpl.replaceOccurrencesOfString("%READER-STYLE%", withString: initialStyle.encode(),
                            options: NSStringCompareOptions(), range: NSMakeRange(0, tmpl.length))

                        tmpl.replaceOccurrencesOfString("%READER-DOMAIN%", withString: simplifyDomain(readabilityResult.domain),
                            options: NSStringCompareOptions(), range: NSMakeRange(0, tmpl.length))

                        tmpl.replaceOccurrencesOfString("%READER-URL%", withString: readabilityResult.url,
                            options: NSStringCompareOptions(), range: NSMakeRange(0, tmpl.length))

                        tmpl.replaceOccurrencesOfString("%READER-TITLE%", withString: readabilityResult.title,
                            options: NSStringCompareOptions(), range: NSMakeRange(0, tmpl.length))

                        tmpl.replaceOccurrencesOfString("%READER-CREDITS%", withString: readabilityResult.credits,
                            options: NSStringCompareOptions(), range: NSMakeRange(0, tmpl.length))

                        tmpl.replaceOccurrencesOfString("%READER-CONTENT%", withString: readabilityResult.content,
                            options: NSStringCompareOptions(), range: NSMakeRange(0, tmpl.length))

                        return tmpl as String
                    } catch _ {
                    }
                }
            } catch _ {
            }
        }
        return nil
    }
}
