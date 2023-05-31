// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import Storage

protocol LibraryPanelDelegate: AnyObject {
    func libraryPanelDidRequestToSignIn()
    func libraryPanelDidRequestToCreateAccount()
    func libraryPanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool)
    func libraryPanel(didSelectURL url: URL, visitType: VisitType)
    func libraryPanel(didSelectURLString url: String, visitType: VisitType)
}

protocol LibraryPanel: UIViewController, LegacyNotificationThemeable {
    var libraryPanelDelegate: LibraryPanelDelegate? { get set }
    var state: LibraryPanelMainState { get set }
    var bottomToolbarItems: [UIBarButtonItem] { get }

    func handleLeftTopButton()
    func handleRightTopButton()
    func shouldDismissOnDone() -> Bool
}

extension LibraryPanel {
    var flexibleSpace: UIBarButtonItem {
        return UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    }

    func updatePanelState(newState: LibraryPanelMainState) {
        state = newState
    }

    func shouldDismissOnDone() -> Bool {
        return true
    }

    func handleLeftTopButton() {
        // no implementation needed
    }

    func handleRightTopButton() {
        // no implementation needed
    }
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

class LibraryPanelHelper {
    private let profile: Profile
    private let tabManager: TabManager

    init(profile: Profile, tabManager: TabManager) {
        self.profile = profile
        self.tabManager = tabManager
    }

    lazy var enabledPanels: [LibraryPanelDescriptor] = {
        let bookmarksViewModel = BookmarksPanelViewModel(profile: profile)

        return [
            LibraryPanelDescriptor(
                viewController: BookmarksPanel(viewModel: bookmarksViewModel),
                profile: profile,
                tabManager: tabManager,
                accessibilityLabel: .LibraryPanelBookmarksAccessibilityLabel,
                accessibilityIdentifier: AccessibilityIdentifiers.LibraryPanels.bookmarksView,
                panelType: .bookmarks),

            LibraryPanelDescriptor(
                viewController: HistoryPanel(profile: profile, tabManager: tabManager),
                profile: profile,
                tabManager: tabManager,
                accessibilityLabel: .LibraryPanelHistoryAccessibilityLabel,
                accessibilityIdentifier: AccessibilityIdentifiers.LibraryPanels.historyView,
                panelType: .history),

            LibraryPanelDescriptor(
                viewController: DownloadsPanel(),
                profile: profile,
                tabManager: tabManager,
                accessibilityLabel: .LibraryPanelDownloadsAccessibilityLabel,
                accessibilityIdentifier: AccessibilityIdentifiers.LibraryPanels.downloadsView,
                panelType: .downloads),

            LibraryPanelDescriptor(
                viewController: ReadingListPanel(profile: profile),
                profile: profile,
                tabManager: tabManager,
                accessibilityLabel: .LibraryPanelReadingListAccessibilityLabel,
                accessibilityIdentifier: AccessibilityIdentifiers.LibraryPanels.readingListView,
                panelType: .readingList)
        ]
    }()
}
