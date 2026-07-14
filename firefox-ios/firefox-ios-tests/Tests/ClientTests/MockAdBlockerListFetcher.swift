// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
@testable import Client

final class MockAdBlockerListFetcher: AdBlockerListFetcherProtocol, @unchecked Sendable {
    var jsonToReturn: String?
    private(set) var fetchCallCount = 0

    init(jsonToReturn: String?) {
        self.jsonToReturn = jsonToReturn
    }

    func fetchAdBlockerListJSON() async -> String? {
        fetchCallCount += 1
        return jsonToReturn
    }
}
