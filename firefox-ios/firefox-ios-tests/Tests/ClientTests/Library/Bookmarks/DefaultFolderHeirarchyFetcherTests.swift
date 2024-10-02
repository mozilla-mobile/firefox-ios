// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MozillaAppServices
@testable import Client

final class DefaultFolderHeirarchyFetcherTests: XCTestCase {
    var mockProfile: MockProfile!
    
    override func setUp() async throws {
        try await super.setUp()
        mockProfile = MockProfile()
        await addFolder(title: "test", gui: nil)
    }

    override func tearDown() {
        mockProfile = nil
        super.tearDown()
    }

    func testFolder() async {
        let subject = createSubject()
        let folders = await subject.fetchFolders()
        XCTAssertEqual(folders.count, 1)
        XCTAssertEqual(folders[0].title, "test")
        XCTAssertEqual(folders[0].indentation, 0)
    }
    
    func testReturnIndentedFolders() async {
        let subject = createSubject()
        let lastInserted = await subject.fetchFolders()[0]
        await addFolder(title: "indented", gui: lastInserted.guid)
        
        let folders = await subject.fetchFolders()
        print(folders)
    }

    private func createSubject() -> DefaultFolderHierarchyFetcher {
        let subject = DefaultFolderHierarchyFetcher(profile: mockProfile, rootFolderGUID: BookmarkRoots.MobileFolderGUID)
        return subject
    }
    
    private func addFolder(title: String, gui: String?) async {
        return await withCheckedContinuation { continuation in
            mockProfile.places.createFolder(parentGUID: gui ?? BookmarkRoots.MobileFolderGUID, title: title, position: 0).uponQueue(.main, block: { result in
                print(result)
                continuation.resume()
            })
        }
    }
}
