// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension Collection {
    /// A Boolean value indicating whether the collection contains elements.
    ///
    /// `var isEmpty: Bool { get }`
    ///
    /// When you need to check whether your collection is not empty, use the
    /// `isNotEmpty` property instead of checking that the count property is
    /// greater than zero. For collections that don’t conform to
    /// `RandomAccessCollection`, accessing the count property iterates
    /// through the elements of the collection.
    var isNotEmpty: Bool {
        return isEmpty == false
    }
}

extension String {
    /// A Boolean value indicating whether a string contains characters.
    var isNotEmpty: Bool {
        return isEmpty == false
    }
}

extension Data {
    /// A Boolean value indicating whether the `Data` object contains something.
    var isNotEmpty: Bool {
        return isEmpty == false
    }
}
