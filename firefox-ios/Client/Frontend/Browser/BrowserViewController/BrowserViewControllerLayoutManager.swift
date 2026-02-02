// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

@MainActor
class BrowserViewControllerLayoutManager {
    private unowned let parentView: UIView
    private unowned let headerView: UIView
    private let toolbarHelper: ToolbarHelperInterface
    private weak var scrollController: LegacyTabScrollProvider?

    // Constraints
    private var headerTopConstraint: NSLayoutConstraint?

    init(parentView: UIView,
         headerView: UIView,
         toolbarHelper: ToolbarHelperInterface = ToolbarHelper()) {
        self.parentView = parentView
        self.headerView = headerView
        self.toolbarHelper = toolbarHelper
    }

    func setScrollController(_ scrollController: LegacyTabScrollProvider?) {
        self.scrollController = scrollController
    }

    func setupHeaderConstraints(isBottomSearchBar: Bool) {
        print("YRD - setupHeaderConstraints")

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
            let topAnchor = getHeaderTopAnchor(isBottomSearchBar: isBottomSearchBar)
            headerTopConstraint = headerView.topAnchor.constraint(equalTo: topAnchor)
        } else {
            NSLayoutConstraint.activate([
                headerView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
                headerView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            ])
            let topAnchor = getHeaderTopAnchor(isBottomSearchBar: isBottomSearchBar)
            headerTopConstraint = headerView.topAnchor.constraint(equalTo: topAnchor)
        }

        headerTopConstraint?.isActive = true
        updateScrollControllerConstraint()
    }

    func updateHeaderConstraints(isBottomSearchBar: Bool) {
        print("YRD - updateHeaderConstraints without SnapKit")

        // Get the correct anchor based on current conditions
        let targetAnchor = getHeaderTopAnchor(isBottomSearchBar: isBottomSearchBar)

        // Preserve current offset
        let currentConstant = headerTopConstraint?.constant ?? 0
        headerTopConstraint?.isActive = false

        // Create new with correct anchor
        headerTopConstraint = headerView.topAnchor.constraint(equalTo: targetAnchor)
        headerTopConstraint?.constant = currentConstant
        headerTopConstraint?.isActive = true

        updateScrollControllerConstraint()

    }

    private func updateScrollControllerConstraint() {
        guard let scrollController = scrollController,
              let constraint = headerTopConstraint else { return }
        scrollController.headerTopConstraint = ConstraintReference(native: constraint)
    }

    /// Returns the correct top anchor for the header based on search bar position and trait collection
    /// - Parameter isBottomSearchBar: Whether the search bar is positioned at the bottom
    /// - Returns: The appropriate NSLayoutYAxisAnchor to constrain the header to
    private func getHeaderTopAnchor(isBottomSearchBar: Bool) -> NSLayoutYAxisAnchor {
        // Bottom search bar always uses safeArea
        guard !isBottomSearchBar else {
            return parentView.safeAreaLayoutGuide.topAnchor
        }

        // Top toolbar: depends on nav toolbar visibility
        let isNavToolbar = toolbarHelper.shouldShowNavigationToolbar(for: parentView.traitCollection)
        let shouldShowTopTabs = toolbarHelper.shouldShowTopTabs(for: parentView.traitCollection)

        return (isNavToolbar || shouldShowTopTabs) ?
            parentView.safeAreaLayoutGuide.topAnchor :
            parentView.topAnchor
    }
}
