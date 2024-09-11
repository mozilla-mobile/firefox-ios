// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common

/// The history panel has a fixed first section and cells. In this case, we'll only need some
/// properties of that to serve as our model.
struct HistoryActionablesModel: Hashable {
    // MARK: - Properties

    typealias a11y = AccessibilityIdentifiers.LibraryPanels.HistoryPanel
    typealias History = String.LibraryPanel.History

    private(set) var itemImage: UIImage?
    let imageName: String?
    let itemTitle: String
    let itemA11yId: String
    let itemIdentity: ActionableItem
    let identifier = UUID()

    enum ActionableItem {
        case clearHistory, recentlyClosed, syncHistory
    }

    // MARK: - Init

    init(imageName: String?, title: String, a11yId: String, itemIdentity: ActionableItem) {
        self.itemTitle = title
        self.itemA11yId = a11yId
        self.itemIdentity = itemIdentity
        self.imageName = imageName
    }

    mutating func configureImage(for window: WindowUUID) {
        if let imageName = imageName {
            let themeManager: ThemeManager = AppContainer.shared.resolve()
            self.itemImage = UIImage(named: imageName)?
                .withTintColor(themeManager.getCurrentTheme(for: window).colors.iconSecondary)
        } else {
            self.itemImage = nil
        }
    }

    static let activeActionables: [HistoryActionablesModel] = [
        HistoryActionablesModel(imageName: StandardImageIdentifiers.Large.tabTray,
                                title: History.RecentlyClosedTabsButtonTitle,
                                a11yId: a11y.recentlyClosedCell,
                                itemIdentity: .recentlyClosed)
    ]
}
