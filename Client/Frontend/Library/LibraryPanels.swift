// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Shared
import Storage

protocol LibraryPanel: NotificationThemeable {
    var libraryPanelDelegate: LibraryPanelDelegate? { get set }
}

struct LibraryPanelUX {
    static let EmptyTabContentOffset: CGFloat = -180
}

protocol LibraryPanelDelegate: AnyObject {
    func libraryPanelDidRequestToSignIn()
    func libraryPanelDidRequestToCreateAccount()
    func libraryPanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool)
    func libraryPanel(didSelectURL url: URL, visitType: VisitType)
    func libraryPanel(didSelectURLString url: String, visitType: VisitType)
}

enum LibraryPanelType: Int, CaseIterable {
    case bookmarks = 0
    case history = 1
    case downloads = 2
    case readingList = 3

    var title: String {
        switch self {
        case .bookmarks:
            return .AppMenu.AppMenuBookmarksTitleString
        case .history:
            return .AppMenu.AppMenuHistoryTitleString
        case .downloads:
            return .AppMenu.AppMenuDownloadsTitleString
        case .readingList:
            return .AppMenu.AppMenuReadingListTitleString
        }
    }
}

/**
 * Data for identifying and constructing a LibraryPanel.
 */
class LibraryPanelDescriptor {
    var viewController: UIViewController?
    var navigationController: UINavigationController?

    fileprivate let makeViewController: (_ profile: Profile, _ tabManager: TabManager) -> UIViewController
    fileprivate let profile: Profile
    fileprivate let tabManager: TabManager

    let accessibilityLabel: String
    let accessibilityIdentifier: String
    let panelType: LibraryPanelType

    init(makeViewController: @escaping ((_ profile: Profile, _ tabManager: TabManager) -> UIViewController), profile: Profile, tabManager: TabManager, accessibilityLabel: String, accessibilityIdentifier: String, panelType: LibraryPanelType) {
        self.makeViewController = makeViewController
        self.profile = profile
        self.tabManager = tabManager
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityIdentifier = accessibilityIdentifier
        self.panelType = panelType
    }

    func setup() {
        guard viewController == nil else { return }
        let viewController = makeViewController(profile, tabManager)
        self.viewController = viewController
        navigationController = ThemedNavigationController(rootViewController: viewController)
    }
}

class LibraryPanels: FeatureFlagsProtocol {
    fileprivate let profile: Profile
    fileprivate let tabManager: TabManager

    init(profile: Profile, tabManager: TabManager) {
        self.profile = profile
        self.tabManager = tabManager
    }

    lazy var enabledPanels = [
        LibraryPanelDescriptor(
            makeViewController: { profile, tabManager  in
                return BookmarksPanel(profile: profile)
            },
            profile: profile,
            tabManager: tabManager,
            accessibilityLabel: .LibraryPanelBookmarksAccessibilityLabel,
            accessibilityIdentifier: AccessibilityIdentifiers.LibraryPanels.bookmarksView,
            panelType: .bookmarks),

        LibraryPanelDescriptor(
            makeViewController: { profile, tabManager in
                return HistoryPanelWithGroups(profile: profile, tabManager: tabManager)
            },
            profile: profile,
            tabManager: tabManager,
            accessibilityLabel: .LibraryPanelHistoryAccessibilityLabel,
            accessibilityIdentifier: AccessibilityIdentifiers.LibraryPanels.historyView,
            panelType: .history),

        LibraryPanelDescriptor(
            makeViewController: { profile, tabManager in
                return DownloadsPanel(profile: profile)
            },
            profile: profile,
            tabManager: tabManager,
            accessibilityLabel: .LibraryPanelDownloadsAccessibilityLabel,
            accessibilityIdentifier: AccessibilityIdentifiers.LibraryPanels.downloadsView,
            panelType: .downloads),

        LibraryPanelDescriptor(
            makeViewController: { profile, tabManager in
                return ReadingListPanel(profile: profile)
            },
            profile: profile,
            tabManager: tabManager,
            accessibilityLabel: .LibraryPanelReadingListAccessibilityLabel,
            accessibilityIdentifier: AccessibilityIdentifiers.LibraryPanels.readingListView,
            panelType: .readingList)
    ]
}
