// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

enum BundleError: Error, CustomStringConvertible {
    var description: String {
        switch self {
        case .noBundleRetrieved(let error), .imageFormatting(let error), .noImage(let error):
            return error
        }
    }

    case noBundleRetrieved(String)
    case imageFormatting(String)
    case noImage(String)
}
