// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

public struct ReaderModeUtils {
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
            .replacingOccurrences(of: "%READER-CONTENT%", with: readabilityResult.content)
            .replacingOccurrences(of: "%READER-LANGUAGE%", with: readabilityResult.language)
            .replacingOccurrences(of: "%READER-DIRECTION%", with: readabilityResult.direction.rawValue)
    }
}
