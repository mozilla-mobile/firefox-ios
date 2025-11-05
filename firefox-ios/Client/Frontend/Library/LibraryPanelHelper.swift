// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

import enum MozillaAppServices.VisitType

protocol LibraryPanelDelegate: AnyObject {
    @MainActor
    func libraryPanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool)

    @MainActor
    func libraryPanel(didSelectURL url: URL, visitType: VisitType)

    @MainActor
    var libraryPanelWindowUUID: WindowUUID { get }
}

protocol LibraryPanel: UIViewController {
    @MainActor
    var libraryPanelDelegate: LibraryPanelDelegate? { get set }

    @MainActor
    var state: LibraryPanelMainState { get set }

    @MainActor
    var bottomToolbarItems: [UIBarButtonItem] { get }

    @MainActor
    func handleLeftTopButton()

    @MainActor
    func handleRightTopButton()

    @MainActor
    func shouldDismissOnDone() -> Bool
}

@MainActor
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
            return .LegacyAppMenu.AppMenuBookmarksTitleString
        case .history:
            return .LegacyAppMenu.AppMenuHistoryTitleString
        case .downloads:
            return .LegacyAppMenu.AppMenuDownloadsTitleString
        case .readingList:
            return .LegacyAppMenu.AppMenuReadingListTitleString
        }
    }

    var homepanelSection: Route.HomepanelSection {
        switch self {
        case .bookmarks: return .bookmarks
        case .history: return .history
        case .readingList: return .readingList
        case .downloads: return .downloads
        }
    }
}

class LibraryPanelHelper {
    private let profile: Profile

    init(profile: Profile) {
        self.profile = profile
    }

    lazy var enabledPanels: [LibraryPanelDescriptor] = {
        let bookmarksViewModel = BookmarksPanelViewModel(profile: profile, bookmarksHandler: profile.places)

        return [
            LibraryPanelDescriptor(
                accessibilityLabel: .LibraryPanelBookmarksAccessibilityLabel,
                accessibilityIdentifier: AccessibilityIdentifiers.LibraryPanels.bookmarksView,
                panelType: .bookmarks),

            LibraryPanelDescriptor(
                accessibilityLabel: .LibraryPanelHistoryAccessibilityLabel,
                accessibilityIdentifier: AccessibilityIdentifiers.LibraryPanels.historyView,
                panelType: .history),

            LibraryPanelDescriptor(
                accessibilityLabel: .LibraryPanelDownloadsAccessibilityLabel,
                accessibilityIdentifier: AccessibilityIdentifiers.LibraryPanels.downloadsView,
                panelType: .downloads),

            LibraryPanelDescriptor(
                accessibilityLabel: .LibraryPanelReadingListAccessibilityLabel,
                accessibilityIdentifier: AccessibilityIdentifiers.LibraryPanels.readingListView,
                panelType: .readingList)
        ]
    }()
}
