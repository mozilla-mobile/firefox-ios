// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol ParentCoordinatorDelegate: AnyObject {
    /// Notifies the parent coordinator that a child coordinator has finished his session.
    func didFinish(from childCoordinator: Coordinator)
}
