// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

final class MockGroupedFolderHierarchyFetcher: GroupedFolderHierarchyFetcher, @unchecked Sendable {
    var mockFolderStructures: [GroupedFolder] = []
    private(set) var fetchFoldersCalled = 0
    private(set) var capturedExcludedGuids: [String] = []

    func fetchFolders(excludedGuids: [String]) async -> [GroupedFolder] {
        fetchFoldersCalled += 1
        capturedExcludedGuids = excludedGuids
        return mockFolderStructures
    }
}
