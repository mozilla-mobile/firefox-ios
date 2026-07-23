// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MozillaAppServices
@testable import Client

final class GroupedDefaultFolderHierarchyFetcherTests: XCTestCase {
    var mockProfile: MockProfile!
    let rootFolderGUID = BookmarkRoots.MobileFolderGUID
    let testFolderTitle = "testTitle"
    var testFolderGuid = ""

    override func setUp() async throws {
        try await super.setUp()
        mockProfile = MockProfile()
        testFolderGuid = await addFolder(title: testFolderTitle)
    }

    override func tearDown() {
        mockProfile = nil
        super.tearDown()
    }

    func testFetchFolder_returnsPreviouslyAddedFolder() async throws {
        let subject = createSubject()

        let folders = await subject.fetchFolders()

        let folder = try XCTUnwrap(folders.first)
        XCTAssertEqual(folders.count, 1)
        XCTAssertEqual(folder.title, testFolderTitle)
        // should be zero since the folder is at the root
        XCTAssertEqual(folder.indentation, 0)
        XCTAssertFalse(folder.isDesktopRoot)
    }

    func testFetchFolder_ignoresExcludedGuidTrees() async throws {
        _ = await addFolder(title: "testSubFolder", parentFolderGUID: testFolderGuid)
        let subject = createSubject()
        let folders = await subject.fetchFolders(excludedGuids: [testFolderGuid])
        // Should be zero folders since we are excluding our root folder (testFolderGuid)
        XCTAssertEqual(folders.count, 0)
    }

    func testAddFolderToPreviousAddedFolderGUID_returnsFolderWithIndentationHigherThenPreviousFolder() async throws {
        mockProfile.reopen()
        let subject = createSubject()
        let previousFolders = await subject.fetchFolders()
        let previouslyAddedFolder = try XCTUnwrap(previousFolders.first)
        let folderTitle = "indented"
        _ = await addFolder(title: folderTitle, parentFolderGUID: previouslyAddedFolder.guid)

        let folders = await subject.fetchFolders()
        let lastAddedFolder = try XCTUnwrap(folders.first { $0.title == folderTitle })

        XCTAssertEqual(lastAddedFolder.title, folderTitle)
        XCTAssertGreaterThan(lastAddedFolder.indentation, previouslyAddedFolder.indentation)
    }

    func testAddFolderToPreviousAddedFolderGUID_setsParentTitleToPreviousFolderTitle() async throws {
        mockProfile.reopen()
        let subject = createSubject()
        let previousFolders = await subject.fetchFolders()
        let previouslyAddedFolder = try XCTUnwrap(previousFolders.first)
        let folderTitle = "indented"
        _ = await addFolder(title: folderTitle, parentFolderGUID: previouslyAddedFolder.guid)

        let folders = await subject.fetchFolders()
        let lastAddedFolder = try XCTUnwrap(folders.first { $0.title == folderTitle })

        XCTAssertEqual(lastAddedFolder.parentTitle, previouslyAddedFolder.title)
    }

    func testFetchFolder_whenNoDesktopBookmarks_excludesDesktopRoots() async throws {
        let subject = createSubject(rootFolderGUID: BookmarkRoots.RootGUID)

        let folders = await subject.fetchFolders()

        XCTAssertFalse(folders.contains { $0.isDesktopRoot })
    }

    func testFetchFolder_whenHasDesktopBookmarks_includesDesktopRootMarkedAsIsDesktopRoot() async throws {
        let desktopRootGUID = try XCTUnwrap(BookmarkRoots.DesktopRoots.first)
        _ = await addBookmark(parentFolderGUID: desktopRootGUID)
        let subject = createSubject(rootFolderGUID: BookmarkRoots.RootGUID)

        let folders = await subject.fetchFolders()

        let desktopFolder = try XCTUnwrap(folders.first { $0.guid == desktopRootGUID })
        XCTAssertTrue(desktopFolder.isDesktopRoot)
    }

    private func createSubject(rootFolderGUID: String? = nil) -> GroupedDefaultFolderHierarchyFetcher {
        let subject = GroupedDefaultFolderHierarchyFetcher(profile: mockProfile,
                                                           rootFolderGUID:
                                                           rootFolderGUID ??
                                                           self.rootFolderGUID)
        return subject
    }

    func testFolderHierarchy_setsParentTitleOnlyOnNestedRows() async throws {
        // Mobile → Work → Taxes
        let workGuid = await addFolder(title: "Work")
        _ = await addFolder(title: "Taxes", parentFolderGUID: workGuid)
        let subject = createSubject(rootFolderGUID: BookmarkRoots.RootGUID)

        let folders = await subject.fetchFolders()

        let work = try XCTUnwrap(folders.first { $0.title == "Work" })
        let taxes = try XCTUnwrap(folders.first { $0.title == "Taxes" })

        // Top-level card header: indent 0, no "↳ parent" subtitle
        XCTAssertEqual(work.indentation, 0)
        XCTAssertNil(work.parentTitle)

        // Nested row: indent 1, subtitle points at the immediate parent
        XCTAssertEqual(taxes.indentation, 1)
        XCTAssertEqual(taxes.parentTitle, "Work")
    }

    func testMakeGroups_withMobileAndDesktopFolders_returnsMobileFirstAndDesktopCollapsed() {
        let mobileFolder = GroupedFolder(title: "Mobile Folder", guid: "mobile-guid", indentation: 0)
        let desktopFolder = GroupedFolder(title: "Desktop Folder", guid: "desktop-guid", indentation: 0, isDesktopRoot: true)

        let groups = FolderGroup.makeGroups(from: [mobileFolder, desktopFolder],
                                            mobileTitle: "Mobile Bookmarks",
                                            desktopTitle: "Desktop Bookmarks",
                                            mobileExpandedByDefault: true,
                                            desktopExpandedByDefault: false)

        XCTAssertEqual(groups.count, 2)

        let mobileGroup = groups[0]
        XCTAssertEqual(mobileGroup.id, FolderGroup.mobileGroupID)
        XCTAssertEqual(mobileGroup.folders, [mobileFolder])
        XCTAssertTrue(mobileGroup.isExpanded)

        let desktopGroup = groups[1]
        XCTAssertEqual(desktopGroup.id, FolderGroup.desktopGroupID)
        XCTAssertEqual(desktopGroup.folders, [desktopFolder])
        XCTAssertFalse(desktopGroup.isExpanded)
    }

    func testMakeGroups_withOnlyMobileFolders_returnsSingleMobileGroup() {
        let mobileFolder = GroupedFolder(title: "Mobile Folder", guid: "mobile-guid", indentation: 0)

        let groups = FolderGroup.makeGroups(from: [mobileFolder],
                                            mobileTitle: "Mobile Bookmarks",
                                            desktopTitle: "Desktop Bookmarks",
                                            mobileExpandedByDefault: true,
                                            desktopExpandedByDefault: false)

        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].id, FolderGroup.mobileGroupID)
        XCTAssertEqual(groups[0].folders, [mobileFolder])
    }

    func testBlocks_splitsFlatFolderListIntoCardsAtEachIndentationZero() {
        let folderA = GroupedFolder(title: "A", guid: "a-guid", indentation: 0)
        let folderASub = GroupedFolder(title: "A-Sub", guid: "a-sub-guid", indentation: 1, parentTitle: "A")
        let folderB = GroupedFolder(title: "B", guid: "b-guid", indentation: 0)

        let group = FolderGroup(id: "test-group",
                                title: "Test",
                                folders: [folderA, folderASub, folderB],
                                isExpanded: true)

        let blocks = group.blocks

        XCTAssertEqual(blocks.count, 2)
        XCTAssertEqual(blocks[0].folders, [folderA, folderASub])
        XCTAssertEqual(blocks[1].folders, [folderB])
    }

    private func addFolder(title: String, parentFolderGUID: String? = nil) async -> String {
        return await withCheckedContinuation { continuation in
            mockProfile.places.createFolder(parentGUID: parentFolderGUID ?? rootFolderGUID,
                                            title: title,
                                            position: 0).uponQueue(.main, block: { result in
                switch result {
                case .success(let guid):
                    return continuation.resume(returning: guid)
                case .failure:
                    return continuation.resume(returning: "")
                }
            })
        }
    }

    private func addBookmark(parentFolderGUID: String,
                             title: String = "Test Bookmark",
                             url: String = "https://example.com") async -> String {
        return await withCheckedContinuation { continuation in
            mockProfile.places.createBookmark(parentGUID: parentFolderGUID,
                                              url: url,
                                              title: title,
                                              position: 0).uponQueue(.main, block: { result in
                switch result {
                case .success(let guid):
                    return continuation.resume(returning: guid)
                case .failure:
                    return continuation.resume(returning: "")
                }
            })
        }
    }
}
