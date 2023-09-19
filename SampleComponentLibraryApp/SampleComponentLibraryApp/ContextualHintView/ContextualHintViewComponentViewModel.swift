// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

struct ContextualHintViewComponentViewModel: ComponentViewModel {
    var title = "ContextualHintView"
    var viewController: UIViewController = ContextualHintViewViewController()

    func present(with presenter: Presenter?) {
        presenter?.present(viewController: viewController)
    }
}
