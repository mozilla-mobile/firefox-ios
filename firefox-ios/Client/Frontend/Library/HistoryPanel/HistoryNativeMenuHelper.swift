// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import Storage

@MainActor
final class HistoryNativeMenuHelper {
    private typealias A11y = AccessibilityIdentifiers.LibraryPanels.HistoryPanel.ContextMenu

    private weak var libraryPanelDelegate: LibraryPanelDelegate?
    private weak var historyCoordinatorDelegate: HistoryCoordinatorDelegate?

    init(libraryPanelDelegate: LibraryPanelDelegate?,
         historyCoordinatorDelegate: HistoryCoordinatorDelegate?) {
        self.libraryPanelDelegate = libraryPanelDelegate
        self.historyCoordinatorDelegate = historyCoordinatorDelegate
    }

    func menu(for site: Site,
              sourceView: UIView,
              onPin: @escaping () -> Void,
              onRemove: @escaping () -> Void) -> UIMenu? {
        guard let siteURL = URL(string: site.url) else { return nil }

        return UIMenu(children: [
            getOpenInNewTabAction(url: siteURL),
            getOpenInPrivateTabAction(url: siteURL),
            getAddToShortcutsAction(onPin: onPin),
            getDeleteFromHistoryAction(onRemove: onRemove),
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

    private func getAddToShortcutsAction(onPin: @escaping () -> Void) -> UIAction {
        let action = UIAction(
            title: .AddToShortcutsActionTitle,
            image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.pin)
        ) { _ in
            onPin()
        }
        action.accessibilityIdentifier = A11y.addToShortcuts
        return action
    }

    private func getDeleteFromHistoryAction(onRemove: @escaping () -> Void) -> UIAction {
        let action = UIAction(
            title: .DeleteFromHistoryContextMenuTitle,
            image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.delete),
            attributes: .destructive
        ) { _ in
            onRemove()
        }
        action.accessibilityIdentifier = A11y.deleteFromHistory
        return action
    }

    private func getShareAction(url: URL, sourceView: UIView) -> UIAction {
        let action = UIAction(
            title: .ShareContextMenuTitle,
            image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.shareApple)
        ) { [weak historyCoordinatorDelegate, weak sourceView] _ in
            guard let sourceView else { return }
            historyCoordinatorDelegate?.shareLibraryItem(url: url, sourceView: sourceView)
        }
        action.accessibilityIdentifier = A11y.share
        return action
    }
}
