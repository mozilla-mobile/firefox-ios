// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

@MainActor
class BrowserViewControllerLayoutManager {
    private var headerTopConstraint: NSLayoutConstraint?

    func setupHeaderConstraints(parentView: UIView,
                                headerView: UIView,
                                isBottomSearchBar: Bool,
                                toolbarHelper: ToolbarHelperInterface = ToolbarHelper()) {
        print("YRD - setupHeaderConstraints")
        let isNavToolbar = toolbarHelper.shouldShowNavigationToolbar(for: parentView.traitCollection)
        let shouldShowTopTabs = toolbarHelper.shouldShowTopTabs(for: parentView.traitCollection)

        if isBottomSearchBar {
            // TODO: [iOS 26 Bug] - Remove this workaround when Apple fixes safe area inset updates.
            // Bug: Safe area top inset doesn't update correctly on landscape rotation (remains 20pt)
            // on iOS 26. Prior to iOS 26, safe area inset was updating correctly on rotation.
            // Impact: Header remains partially visible when scrolling.
            // Workaround: Manually adjust constraints based on orientation.
            // Related Bug: https://mozilla-hub.atlassian.net/browse/FXIOS-13756
            // Apple Developer Forums: https://developer.apple.com/forums/thread/798014
            NSLayoutConstraint.activate([
                headerView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
                headerView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
                // The status bar is covered by the statusBarOverlay,
                // if we don't have the URL bar at the top then header height is 0
                headerView.heightAnchor.constraint(equalToConstant: 0)
            ])
            headerTopConstraint = headerView.topAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.topAnchor)
        } else {
            // TODO: Yoana & Winnie deal with scrollController
            let topConstraint = (isNavToolbar || shouldShowTopTabs) ?
                parentView.safeAreaLayoutGuide.topAnchor : parentView.topAnchor
            NSLayoutConstraint.activate([
                headerView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
                headerView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            ])
            headerTopConstraint = headerView.topAnchor.constraint(equalTo: topConstraint)
        }

        headerTopConstraint?.isActive = true
    }

    func updateHeaderConstraints(parentView: UIView,
                                 headerView: UIView,
                                 shouldShowToolbar: Bool,
                                 isBottomSearchBar: Bool) {
        // TODO: Yoana & Winnie Just update the topConstraint
        print("YRD - updateHeaderConstraints without SnapKit")
        switch (isBottomSearchBar, shouldShowToolbar) {
        case (false, false):
            headerTopConstraint?.constant = 20
        case (false, true):
            headerTopConstraint?.constant = -headerView.frame.height
        default:
            headerTopConstraint?.constant = 0
        }

        headerTopConstraint?.isActive = true
    }
}
