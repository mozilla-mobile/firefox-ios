/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class TextContentDetector {

    enum DetectedType {
        case phoneNumber(String)
        case link(URL)
    }

    private static let dataDetector: NSDataDetector = {
        let types: NSTextCheckingResult.CheckingType = [.link, .phoneNumber]
        return try! NSDataDetector(types: types.rawValue)
    }()

    static func detectTextContent(_ content: String) -> DetectedType? {

        guard let match = dataDetector.firstMatch(in: content, options: [], range: NSRange(location: 0, length: content.count)) else { return nil }
        switch match.resultType {
        case .link:
            return .link(match.url!)
        case .phoneNumber:
            return .phoneNumber(match.phoneNumber!)
        default:
            return nil
        }
    }
}
