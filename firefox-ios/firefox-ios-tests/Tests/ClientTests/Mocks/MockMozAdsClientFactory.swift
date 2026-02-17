// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

@testable import Client

final class MockMozAdsClientFactory: MozAdsClientFactory {
    private let mockClient: MozAdsClientProtocol

    init(mockClient: MozAdsClientProtocol) {
        self.mockClient = mockClient
    }

    func createClient() -> MozAdsClientProtocol {
        return mockClient
    }
}
