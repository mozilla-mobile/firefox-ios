// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import ComponentLibrary
import Foundation
import UIKit

struct BottomSheetComponentViewModel: ComponentViewModel {
    var title = "BottomSheetView"
    var viewController: UIViewController
    private var viewModel: BottomSheetViewModel

    init() {
        viewModel = BottomSheetViewModel(
            closeButtonA11yLabel: "Close button",
            closeButtonA11yIdentifier: "a11yCloseButton")
        viewModel.shouldDismissForTapOutside = true

        viewController = BottomSheetViewController(
            viewModel: viewModel,
            childViewController: BottomSheetChildViewController(),
            usingDimmedBackground: true,
            windowUUID: defaultSampleComponentUUID
        )
    }

    func present(with presenter: Presenter?) {
        presenter?.present(viewController: viewController)
    }
}
