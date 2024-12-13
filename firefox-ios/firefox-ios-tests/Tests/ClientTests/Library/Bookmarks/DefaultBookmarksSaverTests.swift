// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MozillaAppServices
@testable import Client

final class DefaultBookmarksSaverTests: XCTestCase, FeatureFlaggable {
    var mockProfile: MockProfile!
    let rootFolderGUID = BookmarkRoots.MobileFolderGUID
    let testBookmark = Bookmark(title: "test", url: "https://www.test.com")
    var testBookmarkGUID: Guid?
    // the guid is empty since it is assigned by the system
    let testFolder = Folder(title: "test", guid: "", indentation: 0)
    var testFolderGUID: Guid?

    override func setUp() async throws {
        try await super.setUp()
        mockProfile = MockProfile()
        testBookmarkGUID = await addBookmark(title: testBookmark.title, url: testBookmark.url)
        testFolderGUID = await addFolder(title: testFolder.title)
    }

    override func tearDown() {
        mockProfile = nil
        testBookmarkGUID = nil
        testFolderGUID = nil
        super.tearDown()
    }

    func testSave_createsNewBookmark() async throws {
        // guid is not assigned since places will assign a custom one when creating a new bookmark
        let bookmark = BookmarkItemData(guid: "",
                                        dateAdded: 0,
                                        lastModified: 0,
                                        parentGUID: nil,
                                        position: 0,
                                        url: "https://www.mozilla.com/",
                                        title: "testTitle")
        let subject = createSubject()

        let result = try await unwrapAsync {
            return await subject.save(bookmark: bookmark, parentFolderGUID: rootFolderGUID)
        }
        let addedNode = try await unwrapAsync {
            return await readNode(url: bookmark.url) as? BookmarkItemData
        }

        XCTAssertNotNil(try? result.get())
        XCTAssertEqual(addedNode.title, bookmark.title)
        XCTAssertEqual(addedNode.url, bookmark.url)
        XCTAssertEqual(addedNode.parentGUID, rootFolderGUID)
    }

    func testSave_updateAlreadyPresentBookmark() async throws {
        let subject = createSubject()

        let previouslyAddedBookmark = try await unwrapAsync {
            return await readNode(url: testBookmark.url) as? BookmarkItemData
        }
        let newTitle = "new title"
        let newUrl = "https://www.newurl.com/"
        let modifiedBookmark = previouslyAddedBookmark.copy(with: newTitle, url: newUrl)

        let result = try await unwrapAsync {
            return await subject.save(bookmark: modifiedBookmark,
                                      parentFolderGUID: modifiedBookmark.parentGUID ?? rootFolderGUID)
        }

        let readModfiedBookmark = try await unwrapAsync {
            return await readNode(guid: previouslyAddedBookmark.guid) as? BookmarkItemData
        }

        switch result {
        case .success(let value):
            XCTAssertNil(value, "Expected the result value to be nil for updates.")
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error)")
        }

        XCTAssertEqual(readModfiedBookmark.title, newTitle)
        XCTAssertEqual(readModfiedBookmark.url, newUrl)
    }

    func testSave_createNewFolder() async throws {
        // guid is not assigned since places will assign a custom one when creating a new bookmark
        let folder = BookmarkFolderData(guid: "",
                                        dateAdded: 0,
                                        lastModified: 0,
                                        parentGUID: nil,
                                        position: 0,
                                        title: "testTitle",
                                        childGUIDs: [],
                                        children: nil)
        let subject = createSubject()
        let result = try await unwrapAsync {
            return await subject.save(bookmark: folder, parentFolderGUID: rootFolderGUID)
        }
        let addedFolder = try await unwrapAsync {
            let rootFolder = await readNode(guid: rootFolderGUID) as? BookmarkFolderData

            for childGUID in rootFolder?.childGUIDs ?? [] {
                let childNode = await readNode(guid: childGUID) as? BookmarkFolderData
                if let childNode, childNode.title == folder.title {
                    return childNode
                }
            }
            return nil
        }

        XCTAssertNotNil(try? result.get())
        XCTAssertEqual(addedFolder.title, folder.title)
        XCTAssertEqual(addedFolder.parentGUID, rootFolderGUID)
    }

    func testSave_updatesAlreadyPresentFolder() async throws {
        let subject = createSubject()

        let previouslyAddedFolder = try await unwrapAsync {
            let rootFolder = await readNode(guid: rootFolderGUID) as? BookmarkFolderData

            for childGUID in rootFolder?.childGUIDs ?? [] {
                let childNode = await readNode(guid: childGUID) as? BookmarkFolderData
                if let childNode, childNode.title == testFolder.title {
                    return childNode
                }
            }
            return nil
        }
        let newTitle = "new title"
        let modifiedFolder = previouslyAddedFolder.copy(withTitle: newTitle)

        let result = try await unwrapAsync {
            return await subject.save(bookmark: modifiedFolder,
                                      parentFolderGUID: modifiedFolder.parentGUID ?? rootFolderGUID)
        }

        let readModfiedBookmark = try await unwrapAsync {
            return await readNode(guid: modifiedFolder.guid) as? BookmarkFolderData
        }

        switch result {
        case .success(let value):
            XCTAssertNil(value, "Expected the result value to be nil for updates.")
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error)")
        }

        XCTAssertEqual(readModfiedBookmark.title, newTitle)
    }

    func testSave_withUnsupportedSepartorType() async throws {
        let subject = createSubject()
        let separator = BookmarkSeparatorData(guid: "",
                                              dateAdded: 0,
                                              lastModified: 0,
                                              parentGUID: rootFolderGUID,
                                              position: 0)

        let result = try await unwrapAsync {
            let returnValue = await subject.save(bookmark: separator,
                                                 parentFolderGUID: separator.parentGUID ?? rootFolderGUID)
            if case let .failure(error) = returnValue {
                return error
            }
            return nil
        }
        let error = try XCTUnwrap(result as? DefaultBookmarksSaver.SaveError)
        XCTAssertEqual(error, .bookmarkTypeDontSupportSaving)
    }

    func testCreateBookmark_createsNewBookmark() async throws {
        let bookmarkUrl = "https://www.mozilla.com/"
        let bookmarTitle =  "testTitle"

        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: mockProfile)

        let subject = createSubject()

        await subject.createBookmark(url: bookmarkUrl, title: bookmarTitle, position: 0)

        let addedNode = try await unwrapAsync {
            return await readNode(url: bookmarkUrl) as? BookmarkItemData
        }

        XCTAssertEqual(addedNode.url, bookmarkUrl)
        XCTAssertEqual(addedNode.title, bookmarTitle)
        XCTAssertEqual(addedNode.parentGUID, rootFolderGUID)
    }

    // MARK: - Utility

    private func addFolder(title: String, position: Int = 0, parentFolderGUID: String? = nil) async -> Guid? {
        return await withCheckedContinuation { continuation in
            mockProfile.places.createFolder(parentGUID: parentFolderGUID ?? rootFolderGUID,
                                            title: title,
                                            position: UInt32(position)).uponQueue(.main) { result in
                if let result = result.successValue {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func addBookmark(title: String, url: String, position: Int = 0, parentFolderGUID: String? = nil) async -> Guid? {
        return await withCheckedContinuation { continuation in
            mockProfile.places.createBookmark(parentGUID: parentFolderGUID ?? rootFolderGUID,
                                              url: url,
                                              title: title,
                                              position: UInt32(position)).uponQueue(.main) { result in
                if let result = result.successValue {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func readNode(guid: String) async -> BookmarkNodeData? {
        return await withCheckedContinuation { continuation in
            mockProfile.places.getBookmark(guid: guid).uponQueue(.main) { data in
                let result: BookmarkNodeData?
                defer {
                    continuation.resume(returning: result)
                }
                if let data = data.successValue, let data {
                    result = data
                } else {
                    result = nil
                }
            }
        }
    }

    /// Returns the first bookmark with the provided url
    private func readNode(url: String) async -> BookmarkNodeData? {
        return await withCheckedContinuation { continuation in
            mockProfile.places.getBookmarksWithURL(url: url).uponQueue(.main) { data in
                let result: BookmarkNodeData?
                defer {
                    continuation.resume(returning: result)
                }
                if let data = data.successValue {
                    result = data.first
                } else {
                    result = nil
                }
            }
        }
    }

    private func createSubject() -> DefaultBookmarksSaver {
        return DefaultBookmarksSaver(profile: mockProfile)
    }
}
