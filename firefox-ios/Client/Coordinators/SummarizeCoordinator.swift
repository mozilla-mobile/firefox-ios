// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SummarizeKit
import Common
import ComponentLibrary
import UIKit

/// Conforming types can show and hide the browser content together with its toolbars.
protocol BrowserContentHiding: AnyObject {
    func showBrowserContent()

    func hideBrowserContent()
}

class SummarizeCoordinator: BaseCoordinator {
    private let browserSnapshot: UIImage
    private let browserSnapshotTopOffset: CGFloat
    private weak var browserContentHiding: BrowserContentHiding?
    private weak var parentCoordinatorDelegate: ParentCoordinatorDelegate?
    private let windowUUID: WindowUUID

    init(
        browserSnapshot: UIImage,
        browserSnapshotTopOffset: CGFloat,
        browserContentHiding: BrowserContentHiding,
        parentCoordinatorDelegate: ParentCoordinatorDelegate?,
        windowUUID: WindowUUID,
        router: Router
    ) {
        self.browserSnapshot = browserSnapshot
        self.browserSnapshotTopOffset = browserSnapshotTopOffset
        self.parentCoordinatorDelegate = parentCoordinatorDelegate
        self.browserContentHiding = browserContentHiding
        self.windowUUID = windowUUID
        super.init(router: router)
    }

    func start() {
        let model = SummarizeViewModel(
            summarizeLabel: "Summarizing...",
            summarizeA11yLabel: "summary-label",
            summarizeTextViewA11yLabel: "summary-text-view-label",
            closeButtonModel: CloseButtonViewModel(
                a11yLabel: "",
                a11yIdentifier: "",
                image: UIImage(named: StandardImageIdentifiers.Large.cross)?.withRenderingMode(.alwaysTemplate)
            ),
            tabSnapshot: browserSnapshot,
            tabSnapshotTopOffset: browserSnapshotTopOffset
        ) { [weak self] in
            guard let self else { return }
            parentCoordinatorDelegate?.didFinish(from: self)
            browserContentHiding?.showBrowserContent()
        } onShouldShowTabSnapshot: { [weak self] in
            self?.browserContentHiding?.hideBrowserContent()
        }

        let controller = SummarizeController(windowUUID: windowUUID, viewModel: model)
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .overFullScreen
        router.present(controller, animated: true)
    }
}
