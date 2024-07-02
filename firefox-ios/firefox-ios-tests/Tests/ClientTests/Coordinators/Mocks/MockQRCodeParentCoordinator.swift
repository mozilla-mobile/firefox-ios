// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

class MockQRCodeViewControllerDelegate: QRCodeViewControllerDelegate {
    var didScanQRCodeWithUrlCalled = 0
    var didScanQRCodeWithTextCalled = 0

    func didScanQRCodeWithURL(_ url: URL) {
        didScanQRCodeWithUrlCalled += 1
    }

    func didScanQRCodeWithText(_ text: String) {
        didScanQRCodeWithTextCalled += 1
    }

    var qrCodeScanningPermissionLevel: QRCodeScanPermissions {
        return .default
    }
}
