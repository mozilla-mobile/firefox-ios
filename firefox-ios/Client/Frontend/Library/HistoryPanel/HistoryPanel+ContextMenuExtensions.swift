// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Storage

extension HistoryPanel: LibraryPanelContextMenu {
    func presentContextMenu(for site: Site, with indexPath: IndexPath, completionHandler: @escaping () -> PhotonActionSheet?) {
        guard let contextMenu = completionHandler() else { return }

        present(contextMenu, animated: true, completion: nil)
    }

    func getSiteDetails(for indexPath: IndexPath) -> Site? {
        return siteAt(indexPath: indexPath)
    }

    func getContextMenuActions(for site: Site, with indexPath: IndexPath) -> [PhotonRowActions]? {
        guard var actions = getDefaultContextMenuActions(for: site, libraryPanelDelegate: libraryPanelDelegate) else { return nil }

        let removeAction = SingleActionViewModel(title: .DeleteFromHistoryContextMenuTitle,
                                                 iconString: StandardImageIdentifiers.Large.delete,
                                                 tapHandler: { _ in
            self.removeHistoryItem(at: indexPath)
        })

        let pinTopSite = SingleActionViewModel(title: .AddToShortcutsActionTitle,
                                               iconString: StandardImageIdentifiers.Large.pin,
                                               tapHandler: { _ in
            self.pinToTopSites(site)
        })

        actions.append(PhotonRowActions(pinTopSite))
        actions.append(PhotonRowActions(removeAction))
        return actions
    }
}
