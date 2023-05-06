// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum MarkupNode: Equatable {
    case text(String)
    case strong([MarkupNode])
    case emphasis([MarkupNode])

    init?(delimiter: UnicodeScalar, children: [MarkupNode]) {
        switch delimiter {
        case "*": self = .strong(children)
        case "_": self = .emphasis(children)
        default: return nil
        }
    }
}
