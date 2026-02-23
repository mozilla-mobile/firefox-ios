// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MozillaAppServices
import Shared
@testable import Client

final class DefaultBookmarksSaverTests: XCTestCase {
    let rootFolderGUID = BookmarkRoots.MobileFolderGUID
    let testBookmark = Bookmark(title: "test", url: "https://www.test.com")
    var testBookmarkGUID: Guid?
    // the guid is empty since it is assigned by the system
    let testFolder = Folder(title: "test", guid: "", indentation: 0)
    var testFolderGUID: Guid?
    var helper: BookmarksSaverTestsHelper!

    override func setUp() async throws {
        try await super.setUp()
        let mockProfile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: mockProfile)
        helper = BookmarksSaverTestsHelper(mockProfile: mockProfile, rootFolderGUID: rootFolderGUID)
        testBookmarkGUID = await helper.addBookmark(title: testBookmark.title, url: testBookmark.url)
        testFolderGUID = await helper.addFolder(title: testFolder.title)
    }

    override func tearDown() {
        helper = nil
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
            return await helper.readNode(url: bookmark.url) as? BookmarkItemData
        }

        XCTAssertNotNil(try? result.get())
        XCTAssertEqual(addedNode.title, bookmark.title)
        XCTAssertEqual(addedNode.url, bookmark.url)
        XCTAssertEqual(addedNode.parentGUID, rootFolderGUID)
    }

    func testSave_updateAlreadyPresentBookmark() async throws {
        let testBookmark = Bookmark(title: "test", url: "https://www.test.com")
        let subject = createSubject()

        let previouslyAddedBookmark = try await unwrapAsync {
            return await helper.readNode(url: testBookmark.url) as? BookmarkItemData
        }
        let newTitle = "new title"
        let newUrl = "https://www.newurl.com/"
        let modifiedBookmark = previouslyAddedBookmark.copy(with: newTitle, url: newUrl)

        let result = try await unwrapAsync {
            return await subject.save(bookmark: modifiedBookmark,
                                      parentFolderGUID: modifiedBookmark.parentGUID ?? rootFolderGUID)
        }

        let readModfiedBookmark = try await unwrapAsync {
            return await helper.readNode(guid: previouslyAddedBookmark.guid) as? BookmarkItemData
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
            let rootFolder = await helper.readNode(guid: rootFolderGUID) as? BookmarkFolderData

            for childGUID in rootFolder?.childGUIDs ?? [] {
                let childNode = await helper.readNode(guid: childGUID) as? BookmarkFolderData
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

    @MainActor
    func testRestoreBookmarkNode_restoreSeparator() async throws {
        let subject = createSubject()
        // guid is not assigned since places will assign a custom one when creating a new bookmark
        let separator = BookmarkSeparatorData(guid: "",
                                              dateAdded: 0,
                                              lastModified: 0,
                                              parentGUID: rootFolderGUID,
                                              position: 0)
        let resultingGUID = await withCheckedContinuation { continuation in
            subject.restoreBookmarkNode(bookmarkNode: separator, parentFolderGUID: rootFolderGUID) { guid in
                    continuation.resume(returning: guid)
            }
        }
        XCTAssertNil(resultingGUID ?? nil)
    }

    @MainActor
    func testRestoreBookmarkNode_restoreFolder() async throws {
        let subject = createSubject()
        // guid is not assigned since places will assign a custom one when creating a new bookmark
        let folder = BookmarkFolderData(guid: "",
                                        dateAdded: 0,
                                        lastModified: 0,
                                        parentGUID: nil,
                                        position: 1,
                                        title: "testTitle",
                                        childGUIDs: [],
                                        children: nil)
        let tempGUID = await withCheckedContinuation { continuation in
            subject.restoreBookmarkNode(bookmarkNode: folder, parentFolderGUID: rootFolderGUID) { guid in
                    continuation.resume(returning: guid)
            }
        }
        let resultingGUID = try XCTUnwrap(tempGUID)

        let tempFolder = await helper.readNode(guid: resultingGUID) as? BookmarkFolderData
        let addedFolder = try XCTUnwrap(tempFolder)

        XCTAssertNotNil(addedFolder)
        XCTAssertEqual(addedFolder.title, folder.title)
        XCTAssertEqual(addedFolder.parentGUID, rootFolderGUID)
        XCTAssertEqual(addedFolder.position, folder.position)
    }

    @MainActor
    func testRestoreBookmarkNode_restoreBookmark() async throws {
        let subject = createSubject()
        // guid is not assigned since places will assign a custom one when creating a new bookmark
        let bookmark = BookmarkItemData(guid: "",
                                        dateAdded: 0,
                                        lastModified: 0,
                                        parentGUID: nil,
                                        position: 1,
                                        url: "https://www.mozilla.com/",
                                        title: "testTitle")
        let tempGUID = await withCheckedContinuation { continuation in
            subject.restoreBookmarkNode(bookmarkNode: bookmark, parentFolderGUID: rootFolderGUID) { guid in
                    continuation.resume(returning: guid)
            }
        }
        let resultingGUID = try XCTUnwrap(tempGUID)

        let tempBookmark = await helper.readNode(guid: resultingGUID) as? BookmarkItemData
        let addedBookmark = try XCTUnwrap(tempBookmark)

        XCTAssertNotNil(addedBookmark)
        XCTAssertEqual(addedBookmark.title, bookmark.title)
        XCTAssertEqual(addedBookmark.url, bookmark.url)
        XCTAssertEqual(addedBookmark.parentGUID, rootFolderGUID)
        XCTAssertEqual(addedBookmark.position, bookmark.position)
    }

    func testSave_updatesAlreadyPresentFolder() async throws {
        // the guid is empty since it is assigned by the system
        let testFolder = Folder(title: "test", guid: "", indentation: 0)
        let subject = createSubject()

        let previouslyAddedFolder = try await unwrapAsync {
            let rootFolder = await helper.readNode(guid: rootFolderGUID) as? BookmarkFolderData

            for childGUID in rootFolder?.childGUIDs ?? [] {
                let childNode = await helper.readNode(guid: childGUID) as? BookmarkFolderData
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
            return await helper.readNode(guid: modifiedFolder.guid) as? BookmarkFolderData
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
        let bookmarkTitle =  "testTitle"

        let subject = createSubject()

        await subject.createBookmark(url: bookmarkUrl, title: bookmarkTitle, position: 0)

        let addedNode = try await unwrapAsync {
            return await helper.readNode(url: bookmarkUrl) as? BookmarkItemData
        }

        XCTAssertEqual(addedNode.url, bookmarkUrl)
        XCTAssertEqual(addedNode.title, bookmarkTitle)
        XCTAssertEqual(addedNode.parentGUID, rootFolderGUID)
    }

    func testCreateBookmark_usesRecentFolderWhenValid() async throws {
        let bookmarkUrl = "https://www.mozilla.com/recent"
        let bookmarkTitle = "recentTitle"
        let recentFolderGuid = try await unwrapAsync {
            return await helper.addFolder(title: "Recent Folder")
        }
        helper.mockProfile.prefs.setString(recentFolderGuid, forKey: PrefsKeys.RecentBookmarkFolder)

        let subject = createSubject()

        await subject.createBookmark(url: bookmarkUrl, title: bookmarkTitle, position: 0)

        let addedNode = try await unwrapAsync {
            return await helper.readNode(url: bookmarkUrl) as? BookmarkItemData
        }

        XCTAssertEqual(addedNode.title, bookmarkTitle)
        XCTAssertEqual(addedNode.parentGUID, recentFolderGuid)
    }

    func testCreateBookmark_fallsBackWhenRecentFolderMissing() async throws {
        let bookmarkUrl = "https://www.mozilla.com/missing"
        let bookmarkTitle = "missingTitle"
        helper.mockProfile.prefs.setString("missing-guid", forKey: PrefsKeys.RecentBookmarkFolder)

        let subject = createSubject()

        await subject.createBookmark(url: bookmarkUrl, title: bookmarkTitle, position: 0)

        let addedNode = try await unwrapAsync {
            return await helper.readNode(url: bookmarkUrl) as? BookmarkItemData
        }

        XCTAssertEqual(addedNode.title, bookmarkTitle)
        XCTAssertEqual(addedNode.parentGUID, rootFolderGUID)
        XCTAssertNil(helper.mockProfile.prefs.stringForKey(PrefsKeys.RecentBookmarkFolder))
    }

    private func createSubject() -> DefaultBookmarksSaver {
        return DefaultBookmarksSaver(profile: helper.mockProfile)
    }
}

struct BookmarksSaverTestsHelper {
    let mockProfile: MockProfile!
    let rootFolderGUID: String!

    func addFolder(title: String, position: Int = 0, parentFolderGUID: String? = nil) async -> Guid? {
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

    func addBookmark(title: String, url: String, position: Int = 0, parentFolderGUID: String? = nil) async -> Guid? {
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

    func readNode(guid: String) async -> BookmarkNodeData? {
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
    func readNode(url: String) async -> BookmarkNodeData? {
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
}
