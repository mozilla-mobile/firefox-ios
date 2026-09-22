// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import XCTest

extension XCTestCase {
    /// Lays a SwiftUI view out inside a window so that its body is evaluated.
    /// The host and window stay local so they deallocate as soon as the call returns.
    @MainActor
    func render(_ view: some View,
                size: CGSize = CGSize(width: 390, height: 844)) -> UIView {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = host
        window.isHidden = false
        host.view.layoutIfNeeded()
        return host.view
    }
}
