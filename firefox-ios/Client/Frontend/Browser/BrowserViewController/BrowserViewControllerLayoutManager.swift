// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

@MainActor
final class BrowserViewControllerLayoutManager {
    private unowned let parentView: UIView
    private unowned let headerView: UIView
    private unowned let bottomContainer: BaseAlphaStackView
    private unowned let overKeyboardContainer: BaseAlphaStackView
    private unowned let bottomContentStackView: BaseAlphaStackView
    private unowned let navigationToolbarContainer: UIView
    private let toolbarHelper: ToolbarHelperInterface
    private weak var scrollController: LegacyTabScrollProvider?

    // Constraints to store - header
    private var headerTopConstraint: NSLayoutConstraint?
    private var headerHeightConstraint: NSLayoutConstraint?

    // Constraints to store - bottom container
    var overKeyboardContainerConstraint: ConstraintReference?
    var bottomContainerConstraint: ConstraintReference?
    private var bottomContentStackViewKeyboardConstraint: NSLayoutConstraint?
    private var bottomContentStackViewBasicConstraint: NSLayoutConstraint?
    private var bottomContentStackViewOverKeyboardConstraint: NSLayoutConstraint?
    private var overKeyboardContainerTopZoomHeightConstraint: NSLayoutConstraint?
    private var overKeyboardContainerTopHeightConstraint: NSLayoutConstraint?

    init(parentView: UIView,
         headerView: UIView,
         bottomContainer: BaseAlphaStackView,
         overKeyboardContainer: BaseAlphaStackView,
         bottomContentStackView: BaseAlphaStackView,
         navigationToolbarContainer: UIView,
         toolbarHelper: ToolbarHelperInterface = ToolbarHelper()) {
        self.parentView = parentView
        self.headerView = headerView
        self.bottomContainer = bottomContainer
        self.overKeyboardContainer = overKeyboardContainer
        self.bottomContentStackView = bottomContentStackView
        self.navigationToolbarContainer = navigationToolbarContainer
        self.toolbarHelper = toolbarHelper
    }

    func setScrollController(_ scrollController: LegacyTabScrollProvider?) {
        self.scrollController = scrollController
    }

    // MARK: - Header Constraints

    func setupHeaderConstraints(isBottomSearchBar: Bool) {
        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
        ])
        let topAnchor = getHeaderTopAnchor(isBottomSearchBar: isBottomSearchBar)
        headerTopConstraint = headerView.topAnchor.constraint(equalTo: topAnchor)
        headerTopConstraint?.isActive = true

        if isBottomSearchBar {
            updateHeaderHeightConstraint(isBottomSearchBar: isBottomSearchBar)
        }

        updateScrollControllerHeaderConstraint()
    }

    func updateHeaderConstraints(isBottomSearchBar: Bool) {
        updateHeaderHeightConstraint(isBottomSearchBar: isBottomSearchBar)

        let targetAnchor = getHeaderTopAnchor(isBottomSearchBar: isBottomSearchBar)

        // Preserve current offset
        let currentConstant = headerTopConstraint?.constant ?? 0
        headerTopConstraint?.isActive = false

        // Create constraint with new correct anchor
        headerTopConstraint = headerView.topAnchor.constraint(equalTo: targetAnchor)
        headerTopConstraint?.constant = currentConstant
        headerTopConstraint?.isActive = true

        updateScrollControllerHeaderConstraint()
    }

    func addReaderModeBarHeight(_ readerModeBar: ReaderModeBarView) {
        readerModeBar.heightAnchor.constraint(equalToConstant: UIConstants.ToolbarHeight).isActive = true
    }

    // MARK: - Bottom Container Setup

    func setupBottomContainerConstraints() {
        NSLayoutConstraint.activate([
            bottomContainer.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            bottomContainer.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
        ])
        let constraint = bottomContainer.bottomAnchor.constraint(equalTo: parentView.bottomAnchor)
        constraint.isActive = true
        let constraintReference = ConstraintReference(native: constraint)

        scrollController?.bottomContainerConstraint = constraintReference
        bottomContainerConstraint = constraintReference
    }

    func setupOverKeyboardContainerConstraints() {
        NSLayoutConstraint.activate([
            overKeyboardContainer.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            overKeyboardContainer.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
        ])

        let constraint = overKeyboardContainer.bottomAnchor.constraint(equalTo: bottomContainer.topAnchor)
        constraint.isActive = true
        let constraintReference = ConstraintReference(native: constraint)

        scrollController?.overKeyboardContainerConstraint = constraintReference
        overKeyboardContainerConstraint = constraintReference

        overKeyboardContainerTopZoomHeightConstraint = overKeyboardContainer.heightAnchor.constraint(
            greaterThanOrEqualToConstant: 0
        )
        overKeyboardContainerTopHeightConstraint = overKeyboardContainer.heightAnchor.constraint(
            equalToConstant: 0
        )
    }

    func setupBottomContentStackViewConstraints() {
        // Default constraints 
        NSLayoutConstraint.activate([
            bottomContentStackView.leadingAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.leadingAnchor),
            bottomContentStackView.trailingAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.trailingAnchor),
            bottomContentStackView.heightAnchor.constraint(equalToConstant: 0).priority(.defaultLow)
        ])

        // above the address bar area (or toolbar when top search bar)
        bottomContentStackViewOverKeyboardConstraint = bottomContentStackView.bottomAnchor.constraint(
            equalTo: overKeyboardContainer.topAnchor
        )

        // above the keyboard (only top search bar — keyboard covers everything else)
        // on update the constant is updated to show above keyboard by bottom = parentView.bottom - keyboardHeight
        bottomContentStackViewKeyboardConstraint = bottomContentStackView.bottomAnchor.constraint(
            equalTo: parentView.bottomAnchor
        )

        // Fallback for iPad with top search bar + no toolbar + no keyboard
        bottomContentStackViewBasicConstraint = bottomContentStackView.bottomAnchor.constraint(
            equalTo: parentView.safeAreaLayoutGuide.bottomAnchor
        )

        bottomContentStackView.setContentHuggingPriority(.defaultHigh, for: .vertical)
    }

    // MARK: - Bottom Container Updates

    func updateOverKeyboardContainerConstraints(isBottomSearchBar: Bool, hasZoomPageBar: Bool) {
        overKeyboardContainerTopZoomHeightConstraint?.isActive = false
        overKeyboardContainerTopHeightConstraint?.isActive = false

        guard !isBottomSearchBar else { return }

        if hasZoomPageBar {
            overKeyboardContainerTopZoomHeightConstraint?.isActive = true
        } else {
            overKeyboardContainerTopHeightConstraint?.isActive = true
        }
    }

    /// Activates the correct bottom constraint for `bottomContentStackView` (login snackbar, FindInPageBar).
    /// Must be called on keyboard and toolbar changes. Bottom search bar relies on `overKeyboardContainer`
    /// growing with the keyboard spacer. Top search bar needs an explicit keyboard constraint because
    /// `overKeyboardContainer` collapses to `height = 0`, leaving its top below the keyboard frame.
    func updateBottomContentStackViewConstraints(isBottomSearchBar: Bool,
                                                 keyboardState: KeyboardState?) {
        // Deactivate all mutually exclusive constraints before activating the appropriate one.
        bottomContentStackViewOverKeyboardConstraint?.isActive = false
        bottomContentStackViewKeyboardConstraint?.isActive = false
        bottomContentStackViewBasicConstraint?.isActive = false

        guard !isBottomSearchBar else {
            updateBottomContentStackViewBottomSearchBar()
            return
        }

        updateBottomContentStackViewTopSearchBar(keyboardState: keyboardState)
    }

    private func updateBottomContentStackViewBottomSearchBar() {
        bottomContentStackViewOverKeyboardConstraint?.isActive = true
    }

    private func updateBottomContentStackViewTopSearchBar(keyboardState: KeyboardState?) {
        let keyboardHeight = keyboardState?.intersectionHeightForView(parentView) ?? 0
        let isKeyboardVisible = keyboardHeight > 0

        if isKeyboardVisible {
            bottomContentStackViewKeyboardConstraint?.constant = -keyboardHeight
            bottomContentStackViewKeyboardConstraint?.isActive = true
        } else if !navigationToolbarContainer.isHidden {
            bottomContentStackViewOverKeyboardConstraint?.isActive = true
        } else {
            bottomContentStackViewBasicConstraint?.isActive = true
        }
    }

    // MARK: - Private helpers (header)

    private func updateHeaderHeightConstraint(isBottomSearchBar: Bool) {
        guard isBottomSearchBar else {
            headerHeightConstraint?.isActive = false
            return
        }

        guard headerHeightConstraint == nil else {
            headerHeightConstraint?.isActive = true
            return
        }

        // The status bar is covered by the statusBarOverlay,
        // if we don't have the URL bar at the top then header height is 0
        headerHeightConstraint = headerView.heightAnchor.constraint(equalToConstant: 0)
        headerHeightConstraint?.isActive = true
    }

    /// Returns the correct top anchor for the header based on search bar position and trait collection
    /// - Parameter isBottomSearchBar: Whether the search bar is positioned at the bottom
    /// - Returns: The appropriate NSLayoutYAxisAnchor to constrain the header to
    private func getHeaderTopAnchor(isBottomSearchBar: Bool) -> NSLayoutYAxisAnchor {
        // Bottom toolbar always uses safeArea
        guard !isBottomSearchBar else {
            return parentView.safeAreaLayoutGuide.topAnchor
        }

        // Top toolbar depends on nav toolbar visibility
        let isNavToolbar = toolbarHelper.shouldShowNavigationToolbar(for: parentView.traitCollection)
        let shouldShowTopTabs = toolbarHelper.shouldShowTopTabs(for: parentView.traitCollection)

        // TODO: [iOS 26 Bug] - Remove this workaround when Apple fixes safe area inset updates.
        // Bug: Safe area top inset doesn't update correctly on landscape rotation (remains 20pt)
        // on iOS 26. Prior to iOS 26, safe area inset was updating correctly on rotation.
        // Impact: Header remains partially visible when scrolling.
        // Workaround: Manually adjust constraints based on orientation.
        // Related Bug: https://mozilla-hub.atlassian.net/browse/FXIOS-13756
        // Apple Developer Forums: https://developer.apple.com/forums/thread/798014
        return (isNavToolbar || shouldShowTopTabs) ? parentView.safeAreaLayoutGuide.topAnchor : parentView.topAnchor
    }

    private func updateScrollControllerHeaderConstraint() {
        guard let scrollController = scrollController,
              let constraint = headerTopConstraint else { return }
        scrollController.headerTopConstraint = ConstraintReference(native: constraint)
    }
}
