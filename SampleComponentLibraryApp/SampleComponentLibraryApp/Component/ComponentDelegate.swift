// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

class ComponentDelegate: NSObject, UITableViewDelegate, UIPopoverPresentationControllerDelegate {
    private var componentData: ComponentData
    weak var presenter: Presenter?

    init(componentData: ComponentData) {
        self.componentData = componentData
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let component = componentData.data[indexPath.row]

        // Contextual hint is a popover
        if let viewController = component.viewController as? ContextualHintViewViewController,
           let cell = tableView.cellForRow(at: indexPath) as? ComponentCell {
            viewController.configure(anchor: cell,
                                     popOverDelegate: self)
        }

        component.present(with: presenter)
    }

    // MARK: UIPopoverPresentationControllerDelegate

    // Returning none here makes sure that the Popover is actually presented as a Popover
    func adaptivePresentationStyle(for controller: UIPresentationController,
                                   traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
