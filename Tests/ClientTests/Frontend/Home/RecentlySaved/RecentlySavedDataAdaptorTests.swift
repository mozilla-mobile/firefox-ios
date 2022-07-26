// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import XCTest
import Storage

class RecentlySavedDataAdaptorTests: XCTestCase {

    let oneDay: TimeInterval = 86400
    var subject: RecentlySavedDataAdaptor!
    var mockSiteImageHelper: SiteImageHelperMock!
    var mockReadingList: ReadingListMock!
    var mockBookmarksHandler: BookmarksHandlerMock!
    var spyNotificationCenter: SpyNotificationCenter!
    var mockDelegate: RecentlySavedDelegateMock?

    override func setUp() {
        super.setUp()
        mockSiteImageHelper = SiteImageHelperMock()
        mockReadingList = ReadingListMock()
        mockBookmarksHandler = BookmarksHandlerMock()
        spyNotificationCenter = SpyNotificationCenter()
        mockDelegate = RecentlySavedDelegateMock()
    }

    override func tearDown() {
        super.tearDown()
        mockSiteImageHelper = nil
        mockReadingList = nil
        mockBookmarksHandler = nil
        spyNotificationCenter = nil
        subject = nil
        mockDelegate = nil
    }

    // MARK: - getRecentlySavedData

    // With bookmarks and reading
    func testGetRecentlySavedData_withBookmarksAndReadingItems() {
        initializeSubject()

        mockReadingList.callGetAvailableRecordsCompletion(with: getMockReadingList())
        mockBookmarksHandler.callGetRecentBookmarksCompletion(with: getMockBookmarks())

        let savedData = subject.getRecentlySavedData()

        XCTAssert(savedData.count == 4)
        XCTAssert(mockReadingList.getAvailableRecordsCallCount == 1)
        XCTAssert(mockBookmarksHandler.getRecentBookmarksCallCount == 1)
        XCTAssert(mockDelegate?.didLoadNewDataCallCount == 2)
    }

    // With no bookmarks and reading
    func testGetRecentlySavedData_withNoBookmarksAndReadingItems() {
        initializeSubject()

        mockReadingList.callGetAvailableRecordsCompletion(with: getMockReadingList())
        mockBookmarksHandler.callGetRecentBookmarksCompletion(with: [])

        let savedData = subject.getRecentlySavedData()

        XCTAssert(savedData.count == 3)
        XCTAssert(mockReadingList.getAvailableRecordsCallCount == 1)
        XCTAssert(mockBookmarksHandler.getRecentBookmarksCallCount == 1)
        XCTAssert(mockDelegate?.didLoadNewDataCallCount == 2)
    }

    // With bookmarks and no reading
    func testGetRecentlySavedData_withBookmarksAndNoReadingItems() {
        initializeSubject()

        mockReadingList.callGetAvailableRecordsCompletion(with: [])
        mockBookmarksHandler.callGetRecentBookmarksCompletion(with: getMockBookmarks())

        let savedData = subject.getRecentlySavedData()

        XCTAssert(savedData.count == 1)
        XCTAssert(mockReadingList.getAvailableRecordsCallCount == 1)
        XCTAssert(mockBookmarksHandler.getRecentBookmarksCallCount == 1)
        XCTAssert(mockDelegate?.didLoadNewDataCallCount == 2)
    }

    // With no bookmarks and no reading
    func testGetRecentlySavedData_withNoItems() {
        initializeSubject()

        mockReadingList.callGetAvailableRecordsCompletion(with: [])
        mockBookmarksHandler.callGetRecentBookmarksCompletion(with: [])

        let savedData = subject.getRecentlySavedData()

        XCTAssert(savedData.count == 0)
        XCTAssert(mockReadingList.getAvailableRecordsCallCount == 1)
        XCTAssert(mockBookmarksHandler.getRecentBookmarksCallCount == 1)
        XCTAssert(mockDelegate?.didLoadNewDataCallCount == 2)
    }

    // MARK: - getHeroImage

    // Without image cached
    func testGetHeroImage_withoutImageCached() {
        initializeSubject()

        let site = Site(url: "www.google.com", title: "google")
        let image = subject.getHeroImage(forSite: site)

        XCTAssert(mockSiteImageHelper.getfetchImageForCallCount == 1)
        XCTAssert(image == nil)
        XCTAssert(mockDelegate?.didLoadNewDataCallCount == 0)
    }

    // With image cached
    func testGetHeroImage_withImageCached() {
        initializeSubject()

        let site = Site(url: "www.google.com", title: "google")
        _ = subject.getHeroImage(forSite: site)

        mockSiteImageHelper.callFetchImageForCompletion(with: UIImage())

        let image = subject.getHeroImage(forSite: site)

        XCTAssert(mockSiteImageHelper.getfetchImageForCallCount == 1)
        XCTAssert(image != nil)
        XCTAssert(mockDelegate?.didLoadNewDataCallCount == 1)
    }

    // MARK: - Helper functions

    private func initializeSubject() {
        let subject = RecentlySavedDataAdaptorImplementation(siteImageHelper: mockSiteImageHelper,
                                                             readingList: mockReadingList,
                                                             bookmarksHandler: mockBookmarksHandler,
                                                             notificationCenter: spyNotificationCenter)
        subject.delegate = mockDelegate
        self.subject = subject
    }

    private func getMockBookmarks() -> [BookmarkItemData] {
        let one = BookmarkItemData(guid: "abc",
                                   dateAdded: Int64(Date().toTimestamp()),
                                   lastModified: Int64(Date().toTimestamp()),
                                   parentGUID: "123",
                                   position: 0,
                                   url: "www.firefox.com",
                                   title: "bookmark1")
        return [one]
    }

    private func getMockReadingList() -> [ReadingListItem] {
        let one = ReadingListItem(id: 123,
                                  lastModified: Date().toTimestamp(),
                                  url: "www.facebook.com",
                                  title: "reading1",
                                  addedBy: "")
        let two = ReadingListItem(id: 456,
                                  lastModified: Date().toTimestamp(),
                                  url: "www.amazon.com",
                                  title: "reading2",
                                  addedBy: "")
        let three = ReadingListItem(id: 456,
                                  lastModified: Date().toTimestamp(),
                                  url: "www.google.com",
                                  title: "reading3",
                                  addedBy: "")
        return [one, two, three]
    }
}
