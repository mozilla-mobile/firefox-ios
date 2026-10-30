// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

public struct ReaderModeUtils {
    // Content Security Policy for readerized pages. Disallows everything except images from anywhere,
    // and styles (including inline styles) and fonts from origin.
    // Must stay on a single line: CFNetwork and HTTPURLResponse drop multi-line header values.
    public static func contentSecurityPolicy(origin: String) -> String {
        return "default-src 'none'; img-src *; style-src 'unsafe-inline' \(origin); font-src \(origin)"
    }

    @MainActor
    public static func generateReaderContent(
        _ readabilityResult: ReadabilityResult,
        initialStyle: ReaderModeStyle
    ) -> String? {
        guard let stylePath = Bundle.main.path(forResource: "Reader", ofType: "css"),
              let css = try? String(contentsOfFile: stylePath, encoding: .utf8),
              let tmplPath = Bundle.main.path(forResource: "Reader", ofType: "html"),
              let tmpl = try? String(contentsOfFile: tmplPath, encoding: .utf8)
        else { return nil }

        return tmpl.replacingOccurrences(of: "%READER-CSS%", with: css)
            .replacingOccurrences(of: "%READER-STYLE%", with: initialStyle.encode())
            .replacingOccurrences(of: "%READER-TITLE%", with: readabilityResult.title)
            .replacingOccurrences(of: "%READER-BYLINE%", with: readabilityResult.byline)
            .replacingOccurrences(of: "%READER-LANGUAGE%", with: readabilityResult.language)
            .replacingOccurrences(of: "%READER-DIRECTION%", with: readabilityResult.direction.rawValue)
            .replacingOccurrences(of: "%READER-JSONLD%", with: readabilityResult.jsonld)
            .replacingOccurrences(of: "%READER-CONTENT%", with: readabilityResult.content)
    }
}
