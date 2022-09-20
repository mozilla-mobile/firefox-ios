/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct GleanMetrics {
    struct BrowserSearch {
        static var withAds: FakeArray { return FakeArray() }
        static var adClicks: FakeArray { return FakeArray() }
    }

    struct Search {
        static var inContent: FakeArray { return FakeArray() }
        static var googleTopsitePressed: FakeArray { return FakeArray() }
        static var counts: FakeArray { return FakeArray() }
    }

    struct FakeArray {
        subscript(string: String) -> Fake {
            return Fake()
        }
    }

    struct Fake {
        func add() {}
    }
}
