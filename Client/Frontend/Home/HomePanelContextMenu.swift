// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Foundation
import Storage

protocol HomePanelContextMenu {
    func getContextMenuActions(for site: Site, with sourceView: UIView?, sectionType: FirefoxHomeSectionType) -> [PhotonRowActions]?
    func presentContextMenu(for site: Site, with sourceView: UIView?, sectionType: FirefoxHomeSectionType)
    func presentContextMenu(for site: Site, with sourceView: UIView?, sectionType: FirefoxHomeSectionType, completionHandler: @escaping () -> PhotonActionSheet?)
}

extension HomePanelContextMenu {
    func presentContextMenu(for site: Site, with sourceView: UIView?, sectionType: FirefoxHomeSectionType) {
        presentContextMenu(for: site, with: sourceView, sectionType: sectionType, completionHandler: {
            return self.contextMenu(for: site, with: sourceView, sectionType: sectionType)
        })
    }

    func contextMenu(for site: Site, with sourceView: UIView?, sectionType: FirefoxHomeSectionType) -> PhotonActionSheet? {
        guard let actions = getContextMenuActions(for: site, with: sourceView, sectionType: sectionType) else { return nil }

        let viewModel = PhotonActionSheetViewModel(actions: [actions], site: site, modalStyle: .overFullScreen)
        let contextMenu = PhotonActionSheet(viewModel: viewModel)
        contextMenu.modalTransitionStyle = .crossDissolve

        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        return contextMenu
    }
}
