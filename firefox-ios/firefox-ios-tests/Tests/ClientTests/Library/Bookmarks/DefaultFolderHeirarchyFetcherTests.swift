// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MozillaAppServices
@testable import Client

final class DefaultFolderHeirarchyFetcherTests: XCTestCase {
    var mockProfile: MockProfile!
    let rootFolderGUID = BookmarkRoots.MobileFolderGUID
    let testFolderTitle = "testTitle"

    override func setUp() async throws {
        try await super.setUp()
        mockProfile = MockProfile()
        await addFolder(title: testFolderTitle)
    }

    override func tearDown() {
        mockProfile = nil
        super.tearDown()
    }

    func testFecthFolder_returnsPreviouslyAddedFolder() async throws {
        let subject = createSubject()

        let folders = await subject.fetchFolders()

        let folder = try XCTUnwrap(folders.first)
        XCTAssertEqual(folders.count, 1)
        XCTAssertEqual(folder.title, testFolderTitle)
        // should be zero since the folder is at the root
        XCTAssertEqual(folder.indentation, 0)
    }

    func testAddFolderToPreviousAddedFolderGUID_returnsFolderWithIndentationHigherThenPreviousFolder() async throws {
        let subject = createSubject()
        let previousFolders = await subject.fetchFolders()
        let previouslyAddedFolder = try XCTUnwrap(previousFolders.first)
        let folderTitle = "indented"
        await addFolder(title: folderTitle, parentFolderGUID: previouslyAddedFolder.guid)

        let folders = await subject.fetchFolders()
        let lastAddedFolder = try XCTUnwrap(folders.first { $0.title == folderTitle })

        XCTAssertEqual(lastAddedFolder.title, folderTitle)
        XCTAssertGreaterThan(lastAddedFolder.indentation, previouslyAddedFolder.indentation)
    }

    private func createSubject() -> DefaultFolderHierarchyFetcher {
        let subject = DefaultFolderHierarchyFetcher(profile: mockProfile, rootFolderGUID: rootFolderGUID)
        return subject
    }

    private func addFolder(title: String, parentFolderGUID: String? = nil) async {
        return await withCheckedContinuation { continuation in
            mockProfile.places.createFolder(parentGUID: parentFolderGUID ?? rootFolderGUID,
                                            title: title,
                                            position: 0).uponQueue(.main, block: { result in
                continuation.resume()
            })
        }
    }
}
