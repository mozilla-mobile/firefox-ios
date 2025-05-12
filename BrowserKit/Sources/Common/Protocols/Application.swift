// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public protocol Application {
    func open(url: URL)

    func canOpen(url: URL) -> Bool
}

extension UIApplication: Application {
    public func open(url: URL) {
        open(url, options: [:])
    }

    public func canOpen(url: URL) -> Bool {
        return canOpenURL(url)
    }
}
