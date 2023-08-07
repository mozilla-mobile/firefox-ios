// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Common
import Storage
import XCTest

class TabLayoutDelegateTests: XCTestCase {
    private var collectionView: MockCollectionView!
    private var profile: TabManagerMockProfile!
    private var manager: TabManager!
    private var cfrDelegate: MockInactiveTabsCFRDelegate!
    private var delegate: MockTabDisplayerDelegate!
    private var tabSelectionDelegate: MockTabSelectionDelegate!
    private var tabPeekDelegate: MockTabPeekDelegate!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = TabManagerMockProfile(databasePrefix: "TabDisplayManagerTests")
        manager = LegacyTabManager(profile: profile, imageStore: nil)
        collectionView = MockCollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        cfrDelegate = MockInactiveTabsCFRDelegate()
        delegate = MockTabDisplayerDelegate()
        tabSelectionDelegate = MockTabSelectionDelegate()
        tabPeekDelegate = MockTabPeekDelegate()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
        profile = nil
        manager = nil
        collectionView = nil
        cfrDelegate = nil
        delegate = nil
    }

    func testTabCellDeinit() {
        let manager = createTabDisplayManager()
        let subject = TabLayoutDelegate(tabDisplayManager: manager,
                                        traitCollection: UITraitCollection())
        subject.tabSelectionDelegate = tabSelectionDelegate
        subject.tabPeekDelegate = tabPeekDelegate
        trackForMemoryLeaks(subject)
    }

    // MARK: - Helper

    func createTabDisplayManager() -> TabDisplayManager {
        let tabDisplayManager = TabDisplayManager(collectionView: collectionView,
                                                  tabManager: manager,
                                                  tabDisplayer: delegate,
                                                  reuseID: TopTabCell.cellIdentifier,
                                                  tabDisplayType: .TopTabTray,
                                                  profile: profile,
                                                  cfrDelegate: cfrDelegate,
                                                  theme: LightTheme())
        collectionView.dataSource = tabDisplayManager
        return tabDisplayManager
    }
}

// MARK: - MockTabDisplayerDelegate
class MockTabDisplayerDelegate: TabDisplayerDelegate {
    var tabCellIdentifier: TabCellIdentifier = "identifier"

    func focusSelectedTab() {}
    func cellFactory(for cell: UICollectionViewCell, using tab: Client.Tab) -> UICollectionViewCell {
        return UICollectionViewCell()
    }
}

// MARK: - MockTabSelectionDelegate
class MockTabSelectionDelegate: TabSelectionDelegate {
    func didSelectTabAtIndex(_ index: Int) {}
}

// MARK: - MockTabPeekDelegate
class MockTabPeekDelegate: TabPeekDelegate {
    func tabPeekDidAddToReadingList(_ tab: Tab) -> ReadingListItem? {
        return nil
    }

    func tabPeekDidAddBookmark(_ tab: Tab) {}

    func tabPeekRequestsPresentationOf(_ viewController: UIViewController) {}

    func tabPeekDidCloseTab(_ tab: Tab) {}

    func tabPeekDidCopyUrl() {}
}
