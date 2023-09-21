// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import ComponentLibrary
import Foundation
import UIKit

struct ActionFooterComponentViewModel: ComponentViewModel {
    var title = "ActionFooterView"
    var viewController: UIViewController
    private var viewModel: ActionFooterViewModel

    init() {
        viewModel = ActionFooterViewModel(
            title: "Footer Title",
            actionTitle: "Action Title",
            a11yTitleIdentifier: "ActionFooterViewTitleIdentifier",
            a11yActionIdentifier: "ActionFooterViewActionIdentifier",
            onTap: nil
        )

        viewController = ActionFooterViewController(
            viewModel: viewModel
        )
    }

    func present(with presenter: Presenter?) {
        presenter?.push(viewController: viewController)
    }
}
