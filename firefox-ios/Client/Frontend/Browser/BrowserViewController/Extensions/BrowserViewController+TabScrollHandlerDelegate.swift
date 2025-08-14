// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SnapKit

extension BrowserViewController: TabScrollHandler.Delegate {
    // TODO: Add bounce effect logic afterwards
    func startAnimatingToolbar(displayState: TabScrollHandler.ToolbarDisplayState) {}

    func showToolbar() {
        if isBottomSearchBar {
            updateBottomToolbar(bottomContainerOffset: 0,
                                overKeyboardContainerOffset: 0)
        } else {
            updateTopToolbar(topOffset: 0, alpha: 1)
        }
    }

    func hideToolbar() {
        if isBottomSearchBar {
            updateBottomToolbar(bottomContainerOffset: bottomContainer.frame.height,
                                overKeyboardContainerOffset: overKeyboardContainer.frame.height)
        } else {
            updateTopToolbar(topOffset: -header.frame.height, alpha: 0)
        }
    }

    // MARK: - Helper private functions

    private func updateTopToolbar(topOffset: CGFloat, alpha: CGFloat) {
        headerTopConstraint?.update(offset: topOffset)
        header.superview?.setNeedsLayout()

        header.updateAlphaForSubviews(0)
    }

    private func updateBottomToolbar(bottomContainerOffset: CGFloat, overKeyboardContainerOffset: CGFloat) {
        overKeyboardContainerConstraint?.update(offset: overKeyboardContainerOffset)
        overKeyboardContainer.superview?.setNeedsLayout()

        bottomContainerConstraint?.update(offset: bottomContainerOffset)
        bottomContainer.superview?.setNeedsLayout()
    }
}
