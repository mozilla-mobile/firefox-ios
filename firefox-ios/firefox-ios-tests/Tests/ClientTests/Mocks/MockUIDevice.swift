// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

class MockUIDevice: UIDeviceInterface {
    var isiPad: Bool

    var userInterfaceIdiom: UIUserInterfaceIdiom {
        return isiPad ? .pad : .phone
    }

    init(isIpad: Bool) {
        self.isiPad = isIpad
    }
}
