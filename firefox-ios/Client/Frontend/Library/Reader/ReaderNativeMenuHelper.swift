// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import Storage

@MainActor
final class ReaderNativeMenuHelper {
    private typealias A11y = AccessibilityIdentifiers.LibraryPanels.ReadingListPanel.ContextMenu

    private weak var libraryPanelDelegate: LibraryPanelDelegate?
    private weak var navigationHandler: ReadingListNavigationHandler?

    init(libraryPanelDelegate: LibraryPanelDelegate?,
         navigationHandler: ReadingListNavigationHandler?) {
        self.libraryPanelDelegate = libraryPanelDelegate
        self.navigationHandler = navigationHandler
    }

    func menu(for site: Site, sourceView: UIView, onRemove: @escaping () -> Void) -> UIMenu? {
        guard let siteURL = URL(string: site.url) else { return nil }

        return UIMenu(children: [
            getOpenInNewTabAction(url: siteURL),
            getOpenInPrivateTabAction(url: siteURL),
            getRemoveAction(onRemove: onRemove),
            getShareAction(url: siteURL, sourceView: sourceView)
        ])
    }

    private func getOpenInNewTabAction(url: URL) -> UIAction {
        let action = UIAction(
            title: .OpenInNewTabContextMenuTitle,
            image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.plus)
        ) { [weak libraryPanelDelegate] _ in
            libraryPanelDelegate?.libraryPanelDidRequestToOpenInNewTab(url, isPrivate: false)
        }
        action.accessibilityIdentifier = A11y.openInNewTab
        return action
    }

    private func getOpenInPrivateTabAction(url: URL) -> UIAction {
        let action = UIAction(
            title: .OpenInNewPrivateTabContextMenuTitle,
            image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.privateMode)
        ) { [weak libraryPanelDelegate] _ in
            libraryPanelDelegate?.libraryPanelDidRequestToOpenInNewTab(url, isPrivate: true)
        }
        action.accessibilityIdentifier = A11y.openInPrivateTab
        return action
    }

    private func getRemoveAction(onRemove: @escaping () -> Void) -> UIAction {
        let action = UIAction(
            title: .RemoveContextMenuTitle,
            image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.cross),
            attributes: .destructive
        ) { _ in
            onRemove()
        }
        action.accessibilityIdentifier = A11y.remove
        return action
    }

    private func getShareAction(url: URL, sourceView: UIView) -> UIAction {
        let action = UIAction(
            title: .ShareContextMenuTitle,
            image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.shareApple)
        ) { [weak navigationHandler, weak sourceView] _ in
            guard let sourceView else { return }
            navigationHandler?.shareLibraryItem(url: url, sourceView: sourceView)
        }
        action.accessibilityIdentifier = A11y.share
        return action
    }
}
