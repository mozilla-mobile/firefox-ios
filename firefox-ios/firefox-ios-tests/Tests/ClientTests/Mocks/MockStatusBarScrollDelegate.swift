// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

@testable import Client

class MockStatusBarScrollDelegate: StatusBarScrollDelegate {
    var savedScrollView: UIScrollView?
    var savedStatusBarFrame: CGRect?
    var savedTheme: Theme?

    func scrollViewDidScroll(_ scrollView: UIScrollView, statusBarFrame: CGRect?, theme: Theme) {
        savedScrollView = scrollView
        savedStatusBarFrame = statusBarFrame
        savedTheme = theme
    }
}
