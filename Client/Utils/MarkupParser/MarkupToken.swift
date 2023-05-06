// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum MarkupToken: CustomStringConvertible, Equatable {
    case text(String)
    case leftDelimiter(UnicodeScalar)
    case rightDelimiter(UnicodeScalar)

    var description: String {
        switch self {
        case .text(let value): return value
        case .leftDelimiter(let value): return String(value)
        case .rightDelimiter(let value): return String(value)
        }
    }
}
