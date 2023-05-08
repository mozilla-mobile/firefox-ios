// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum MarkupNode: Equatable {
    case text(String)
    case bold([MarkupNode])
    case italics([MarkupNode])

    init?(delimiter: UnicodeScalar, children: [MarkupNode]) {
        switch delimiter {
        case "*": self = .bold(children)
        case "_": self = .italics(children)
        default: return nil
        }
    }
}
