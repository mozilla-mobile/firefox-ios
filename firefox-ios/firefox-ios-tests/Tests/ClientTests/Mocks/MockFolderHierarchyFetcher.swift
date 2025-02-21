// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

class MockFolderHierarchyFetcher: FolderHierarchyFetcher {
    var fetchFoldersCalled = 0
    var mockFolderStructures = [Folder(title: "Example", guid: "123456", indentation: 0)]

    func fetchFolders(excludedGuids: [String] = []) async -> [Folder] {
        fetchFoldersCalled += 1
        return mockFolderStructures
    }
}
