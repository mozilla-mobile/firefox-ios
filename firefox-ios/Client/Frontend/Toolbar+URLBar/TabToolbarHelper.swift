// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import Common

protocol TabToolbarProtocol: AnyObject {
    var tabToolbarDelegate: TabToolbarDelegate? { get set }

    var addNewTabButton: ToolbarButton { get }
    var tabsButton: TabsButton { get }
    var appMenuButton: ToolbarButton { get }
    var bookmarksButton: ToolbarButton { get }
    var forwardButton: ToolbarButton { get }
    var backButton: ToolbarButton { get }
    var multiStateButton: ToolbarButton { get }
    var actionButtons: [ThemeApplicable & UIButton] { get }

    func updateBackStatus(_ canGoBack: Bool)
    func updateForwardStatus(_ canGoForward: Bool)
    func updateMiddleButtonState(_ state: MiddleButtonState)
    func updatePageStatus(_ isWebPage: Bool)
    func updateTabCount(_ count: Int, animated: Bool)
    func privateModeBadge(visible: Bool)
    func warningMenuBadge(setVisible: Bool)
    func addUILargeContentViewInteraction(interaction: UILargeContentViewerInteraction)
}

protocol TabToolbarDelegate: AnyObject {
    func configureDataClearanceContextualHint(_ view: UIView)
    func tabToolbarDidPressBack(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressForward(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidLongPressBack(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidLongPressForward(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressHome(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressDataClearance(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressMenu(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressBookmarks(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressTabs(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidLongPressTabs(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressSearch(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressAddNewTab(_ tabToolbar: TabToolbarProtocol, button: UIButton)
}

enum MiddleButtonState {
    case search
    case home
    case fire
}

@objcMembers
open class TabToolbarHelper: NSObject {
    let toolbar: TabToolbarProtocol
    let ImageSearch = UIImage.templateImageNamed(StandardImageIdentifiers.Large.search)
    let ImageNewTab = UIImage.templateImageNamed(StandardImageIdentifiers.Large.plus)
    let ImageHome = UIImage.templateImageNamed(StandardImageIdentifiers.Large.home)
    let ImageBookmark = UIImage.templateImageNamed(StandardImageIdentifiers.Large.bookmarkTrayFill)
    let ImageFire = UIImage.templateImageNamed(StandardImageIdentifiers.Large.dataClearance)

    func setMiddleButtonState(_ state: MiddleButtonState) {
        let device = UIDevice.current.userInterfaceIdiom
        switch (state, device) {
        case (.fire, _):
            middleButtonState = .fire
            toolbar.multiStateButton.setImage(ImageFire, for: .normal)
            toolbar.multiStateButton.accessibilityLabel = .TabToolbarDataClearanceAccessibilityLabel
            toolbar.multiStateButton.largeContentTitle = .TabToolbarDataClearanceAccessibilityLabel
            toolbar.multiStateButton.largeContentImage = ImageFire
            toolbar.multiStateButton.accessibilityIdentifier = AccessibilityIdentifiers.Toolbar.fireButton
        case (.search, _):
            middleButtonState = .search
            toolbar.multiStateButton.setImage(ImageSearch, for: .normal)
            toolbar.multiStateButton.accessibilityLabel = .TabToolbarSearchAccessibilityLabel
            toolbar.multiStateButton.largeContentTitle = .TabToolbarSearchAccessibilityLabel
            toolbar.multiStateButton.largeContentImage = ImageSearch
            toolbar.multiStateButton.accessibilityIdentifier = AccessibilityIdentifiers.Toolbar.searchButton
        default:
            toolbar.multiStateButton.setImage(ImageHome, for: .normal)
            toolbar.multiStateButton.accessibilityLabel = .TabToolbarHomeAccessibilityLabel
            toolbar.multiStateButton.largeContentImage = ImageHome
            toolbar.multiStateButton.largeContentTitle = .TabToolbarHomeAccessibilityLabel
            toolbar.multiStateButton.accessibilityIdentifier = AccessibilityIdentifiers.Toolbar.homeButton
            middleButtonState = .home
        }
    }

    // Default state as reload
    var middleButtonState: MiddleButtonState = .home

    private var longPressGestureRecognizers: [UILongPressGestureRecognizer] = []
    private let uiLargeContentViewInteraction: UILargeContentViewerInteraction = .init()

    init(toolbar: TabToolbarProtocol) {
        self.toolbar = toolbar
        super.init()

        toolbar.addUILargeContentViewInteraction(interaction: uiLargeContentViewInteraction)

        toolbar.backButton.setImage(
            UIImage.templateImageNamed(StandardImageIdentifiers.Large.back)?
                .imageFlippedForRightToLeftLayoutDirection(),
            for: .normal
        )
        toolbar.backButton.accessibilityLabel = .TabToolbarBackAccessibilityLabel
        toolbar.backButton.accessibilityIdentifier = AccessibilityIdentifiers.Toolbar.backButton
        toolbar.backButton.showsLargeContentViewer = true
        toolbar.backButton.largeContentTitle = .TabToolbarBackAccessibilityLabel
        let longPressGestureBackButton = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressBack))
        longPressGestureRecognizers.append(longPressGestureBackButton)
        toolbar.backButton.addGestureRecognizer(longPressGestureBackButton)
        toolbar.backButton.addTarget(self, action: #selector(didClickBack), for: .touchUpInside)

        toolbar.forwardButton.setImage(
            UIImage.templateImageNamed(StandardImageIdentifiers.Large.forward)?
                .imageFlippedForRightToLeftLayoutDirection(),
            for: .normal
        )
        toolbar.forwardButton.accessibilityLabel = .TabToolbarForwardAccessibilityLabel
        toolbar.forwardButton.accessibilityIdentifier = AccessibilityIdentifiers.Toolbar.forwardButton
        toolbar.forwardButton.showsLargeContentViewer = true
        toolbar.forwardButton.largeContentTitle = .TabToolbarForwardAccessibilityLabel
        let longPressGestureForwardButton = UILongPressGestureRecognizer(
            target: self,
            action: #selector(didLongPressForward)
        )
        longPressGestureRecognizers.append(longPressGestureForwardButton)

        toolbar.forwardButton.addGestureRecognizer(longPressGestureForwardButton)
        toolbar.forwardButton.addTarget(self, action: #selector(didClickForward), for: .touchUpInside)

        toolbar.multiStateButton.setImage(ImageHome, for: .normal)
        toolbar.multiStateButton.accessibilityLabel = .TabToolbarReloadAccessibilityLabel
        toolbar.multiStateButton.showsLargeContentViewer = true
        toolbar.multiStateButton.addTarget(self, action: #selector(didPressMultiStateButton), for: .touchUpInside)

        toolbar.tabsButton.addTarget(self, action: #selector(didClickTabs), for: .touchUpInside)
        let longPressGestureTabsButton = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressTabs))
        toolbar.tabsButton.addGestureRecognizer(longPressGestureTabsButton)
        toolbar.tabsButton.accessibilityIdentifier = AccessibilityIdentifiers.Toolbar.tabsButton
        toolbar.tabsButton.showsLargeContentViewer = true
        toolbar.tabsButton.largeContentTitle = .TabsButtonShowTabsAccessibilityLabel
        longPressGestureRecognizers.append(longPressGestureTabsButton)

        toolbar.addNewTabButton.setImage(UIImage.templateImageNamed(StandardImageIdentifiers.Large.plus), for: .normal)
        toolbar.addNewTabButton.accessibilityLabel = .AddTabAccessibilityLabel
        toolbar.addNewTabButton.showsLargeContentViewer = true
        toolbar.addNewTabButton.largeContentTitle = .AddTabAccessibilityLabel
        toolbar.addNewTabButton.addTarget(self, action: #selector(didClickAddNewTab), for: .touchUpInside)
        toolbar.addNewTabButton.accessibilityIdentifier = AccessibilityIdentifiers.Toolbar.addNewTabButton

        let appMenuImage = UIImage.templateImageNamed(StandardImageIdentifiers.Large.appMenu)
        toolbar.appMenuButton.contentMode = .center
        toolbar.appMenuButton.showsLargeContentViewer = true
        toolbar.appMenuButton.largeContentTitle = .LegacyAppMenu.Toolbar.MenuButtonAccessibilityLabel
        toolbar.appMenuButton.largeContentImage = appMenuImage
        toolbar.appMenuButton.setImage(appMenuImage, for: .normal)
        toolbar.appMenuButton.accessibilityLabel = .LegacyAppMenu.Toolbar.MenuButtonAccessibilityLabel
        toolbar.appMenuButton.addTarget(self, action: #selector(didClickMenu), for: .touchUpInside)
        toolbar.appMenuButton.accessibilityIdentifier = AccessibilityIdentifiers.Toolbar.settingsMenuButton

        toolbar.bookmarksButton.contentMode = .center
        toolbar.bookmarksButton.showsLargeContentViewer = true
        toolbar.bookmarksButton.largeContentImage = ImageBookmark
        toolbar.bookmarksButton.largeContentTitle = .LegacyAppMenu.Toolbar.BookmarksButtonAccessibilityLabel
        toolbar.bookmarksButton.setImage(ImageBookmark, for: .normal)
        toolbar.bookmarksButton.accessibilityLabel = .LegacyAppMenu.Toolbar.BookmarksButtonAccessibilityLabel
        toolbar.bookmarksButton.addTarget(self, action: #selector(didClickLibrary), for: .touchUpInside)
        toolbar.bookmarksButton.accessibilityIdentifier = AccessibilityIdentifiers.Toolbar.bookmarksButton

        // The default long press duration is 0.5.  Here we extend it if
        // UILargeContentViewInteraction is enabled to allow the large content
        // viewer time to display the content
        let longPressDuration = UILargeContentViewerInteraction.isEnabled ? 1.5 : 0.5
        longPressGestureRecognizers.forEach { gesture in
            gesture.minimumPressDuration = longPressDuration
            gesture.delegate = self
        }
        NotificationCenter.default.addObserver(
            forName: UILargeContentViewerInteraction.enabledStatusDidChangeNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.longPressGestureRecognizers.forEach { gesture in
                gesture.minimumPressDuration = longPressDuration
            }
        }
    }

    func didClickBack() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressBack(toolbar, button: toolbar.backButton)
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .navigateTabHistoryBack)
    }

    func didLongPressBack(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            toolbar.tabToolbarDelegate?.tabToolbarDidLongPressBack(toolbar, button: toolbar.backButton)
            uiLargeContentViewInteraction.gestureRecognizerForExclusionRelationship.state = .cancelled
            TelemetryWrapper.recordEvent(category: .action, method: .press, object: .navigateTabHistoryBack)
        }
    }

    func didClickTabs() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressTabs(toolbar, button: toolbar.tabsButton)
    }

    func didLongPressTabs(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            toolbar.tabToolbarDelegate?.tabToolbarDidLongPressTabs(toolbar, button: toolbar.tabsButton)
            uiLargeContentViewInteraction.gestureRecognizerForExclusionRelationship.state = .cancelled
        }
    }

    func didClickForward() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressForward(toolbar, button: toolbar.forwardButton)
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .navigateTabHistoryForward)
    }

    func didLongPressForward(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            toolbar.tabToolbarDelegate?.tabToolbarDidLongPressForward(toolbar, button: toolbar.forwardButton)
            uiLargeContentViewInteraction.gestureRecognizerForExclusionRelationship.state = .cancelled
            TelemetryWrapper.recordEvent(category: .action, method: .press, object: .navigateTabHistoryForward)
        }
    }

    func didClickMenu() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressMenu(toolbar, button: toolbar.appMenuButton)
    }

    func didClickLibrary() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressBookmarks(toolbar, button: toolbar.appMenuButton)
    }

    func didClickAddNewTab() {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .addNewTabButton)
        toolbar.tabToolbarDelegate?.tabToolbarDidPressAddNewTab(toolbar, button: toolbar.addNewTabButton)
    }

    func didPressMultiStateButton() {
        switch middleButtonState {
        case .home:
            toolbar.tabToolbarDelegate?.tabToolbarDidPressHome(toolbar, button: toolbar.multiStateButton)
        case .search:
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .startSearchButton)
            toolbar.tabToolbarDelegate?.tabToolbarDidPressSearch(toolbar, button: toolbar.multiStateButton)
        case .fire:
            toolbar.tabToolbarDelegate?.tabToolbarDidPressDataClearance(toolbar, button: toolbar.multiStateButton)
        }
    }
}

extension TabToolbarHelper: UIGestureRecognizerDelegate {
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        longPressGestureRecognizers.contains { $0 == gestureRecognizer }
            && otherGestureRecognizer == uiLargeContentViewInteraction.gestureRecognizerForExclusionRelationship
    }
}
