// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public final class Favourites {
    public var items = [Page]() {
        didSet {
            PageStore.save(favourites: items)
        }
    }

    public init() {
        items = PageStore.favourites
    }
}
