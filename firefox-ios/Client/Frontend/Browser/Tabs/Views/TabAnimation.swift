// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension TabDisplayPanelViewController: UIViewControllerTransitioningDelegate {
    // TODO: Move variables later

    // this animation is using the ExperimentTabCell as part of Tabs Experimentation
    var selectedCell: ExperimentTabCell?
    // Can use the existing snapshot for the tab?
    var selectedCellImageViewSnapshot: UIView?

    func animationController(
      forPresented presented: UIViewController,
      presenting: UIViewController,
      source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
      return nil
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }
}
