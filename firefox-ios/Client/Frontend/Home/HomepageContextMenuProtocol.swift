// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Foundation
import Storage

protocol HomepageContextMenuProtocol {
    func getContextMenuActions(
        for site: Site,
        with sourceView: UIView?,
        sectionType: HomepageSectionType
    ) -> [PhotonRowActions]?
    func presentContextMenu(
        for site: Site,
        with sourceView: UIView?,
        sectionType: HomepageSectionType
    )
    func presentContextMenu(
        for site: Site,
        with sourceView: UIView?,
        sectionType: HomepageSectionType,
        completionHandler: @escaping (Site) -> PhotonActionSheet?
    )
}

extension HomepageContextMenuProtocol {
    // MARK: Site
    func presentContextMenu(for site: Site, with sourceView: UIView?, sectionType: HomepageSectionType) {
        presentContextMenu(for: site, with: sourceView, sectionType: sectionType, completionHandler: { site in
            return self.contextMenu(for: site, with: sourceView, sectionType: sectionType)
        })
    }

    func contextMenu(
        for site: Site,
        with sourceView: UIView?,
        sectionType: HomepageSectionType
    ) -> PhotonActionSheet? {
        guard let windowUUID = sourceView?.currentWindowUUID else { return nil }
        guard let actions = getContextMenuActions(
            for: site,
            with: sourceView,
            sectionType: sectionType
        )
        else { return nil }

        let viewModel = PhotonActionSheetViewModel(
            actions: [actions],
            site: site,
            modalStyle: .overFullScreen
        )
        let contextMenu = PhotonActionSheet(viewModel: viewModel, windowUUID: windowUUID)
        contextMenu.modalTransitionStyle = .crossDissolve

        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        return contextMenu
    }
}
