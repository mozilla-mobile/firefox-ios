/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Storage

protocol LibraryPanel: AnyObject, Themeable {
    var libraryPanelDelegate: LibraryPanelDelegate? { get set }
}

struct LibraryPanelUX {
    static let EmptyTabContentOffset = -180
}

protocol LibraryPanelDelegate: AnyObject {
    func libraryPanelDidRequestToSignIn()
    func libraryPanelDidRequestToCreateAccount()
    func libraryPanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool)
    func libraryPanel(didSelectURL url: URL, visitType: VisitType)
    func libraryPanel(didSelectURLString url: String, visitType: VisitType)
}

enum LibraryPanelType: Int {
    case bookmarks = 0
    case history = 1
    case readingList = 2
    case downloads = 3
}

/**
 * Data for identifying and constructing a LibraryPanel.
 */
class LibraryPanelDescriptor {
    var viewController: UIViewController?
    var navigationController: UINavigationController?

    fileprivate let makeViewController: (_ profile: Profile) -> UIViewController
    fileprivate let profile: Profile

    let imageName: String
    let accessibilityLabel: String
    let accessibilityIdentifier: String

    init(makeViewController: @escaping ((_ profile: Profile) -> UIViewController), profile: Profile, imageName: String, accessibilityLabel: String, accessibilityIdentifier: String) {
        self.makeViewController = makeViewController
        self.profile = profile

        self.imageName = imageName
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    func setup() {
        let viewController = makeViewController(profile)
        self.viewController = viewController
        navigationController = ThemedNavigationController(rootViewController: viewController)
    }
}

class LibraryPanels {
    fileprivate let profile: Profile

    init(profile: Profile) {
        self.profile = profile
    }

    lazy var enabledPanels = [
        LibraryPanelDescriptor(
            makeViewController: { profile in
                return BookmarksPanel(profile: profile)
            },
            profile: profile,
            imageName: "Bookmarks",
            accessibilityLabel: NSLocalizedString("Bookmarks", comment: "Panel accessibility label"),
            accessibilityIdentifier: "LibraryPanels.Bookmarks"),

        LibraryPanelDescriptor(
            makeViewController: { profile in
                return HistoryPanel(profile: profile)
            },
            profile: profile,
            imageName: "History",
            accessibilityLabel: NSLocalizedString("History", comment: "Panel accessibility label"),
            accessibilityIdentifier: "LibraryPanels.History"),

        LibraryPanelDescriptor(
            makeViewController: { profile in
                return ReadingListPanel(profile: profile)
            },
            profile: profile,
            imageName: "ReadingList",
            accessibilityLabel: NSLocalizedString("Reading list", comment: "Panel accessibility label"),
            accessibilityIdentifier: "LibraryPanels.ReadingList"),

        LibraryPanelDescriptor(
            makeViewController: { profile in
                return DownloadsPanel(profile: profile)
            },
            profile: profile,
            imageName: "Downloads",
            accessibilityLabel: NSLocalizedString("Downloads", comment: "Panel accessibility label"),
            accessibilityIdentifier: "LibraryPanels.Downloads"),
    ]
}
