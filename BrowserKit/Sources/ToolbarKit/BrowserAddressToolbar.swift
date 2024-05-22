// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

/// Simple address toolbar implementation.
/// +-------------+------------+-----------------------+----------+
/// | navigation  | indicators | url       [ page    ] | browser  |
/// |   actions   |            |           [ actions ] | actions  |
/// +-------------+------------+-----------------------+----------+
public class BrowserAddressToolbar: UIView, AddressToolbar, ThemeApplicable, LocationViewDelegate {
    private enum UX {
        static let horizontalEdgeSpace: CGFloat = 16
        static let verticalEdgeSpace: CGFloat = 8
        static let horizontalSpace: CGFloat = 8
        static let cornerRadius: CGFloat = 8
        static let dividerWidth: CGFloat = 4
        static let borderHeight: CGFloat = 1
        static let actionSpacing: CGFloat = 0
        static let buttonSize = CGSize(width: 40, height: 40)
        static let locationHeight: CGFloat = 44
    }

    private weak var toolbarDelegate: AddressToolbarDelegate?
    private var theme: Theme?

    private lazy var toolbarContainerView: UIView = .build()
    private lazy var navigationActionStack: UIStackView = .build()

    private lazy var locationContainer: UIView = .build { view in
        view.layer.cornerRadius = UX.cornerRadius
    }

    private lazy var locationView: LocationView = .build()
    private lazy var locationDividerView: UIView = .build()

    private lazy var pageActionStack: UIStackView = .build { view in
        view.spacing = UX.actionSpacing
    }
    private lazy var browserActionStack: UIStackView = .build()
    private lazy var toolbarTopBorderView: UIView = .build()
    private lazy var toolbarBottomBorderView: UIView = .build()

    private var leadingBrowserActionConstraint: NSLayoutConstraint?
    private var leadingLocationContainerConstraint: NSLayoutConstraint?
    private var dividerWidthConstraint: NSLayoutConstraint?
    private var toolbarTopBorderHeightConstraint: NSLayoutConstraint?
    private var toolbarBottomBorderHeightConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(state: AddressToolbarState, toolbarDelegate: any AddressToolbarDelegate) {
        configure(state: state)
        self.toolbarDelegate = toolbarDelegate
    }

    public func configure(state: AddressToolbarState) {
        updateActions(state: state)
        updateBorder(shouldDisplayTopBorder: state.shouldDisplayTopBorder,
                     shouldDisplayBottomBorder: state.shouldDisplayBottomBorder)

        locationView.configure(state.locationViewState, delegate: self)

        setNeedsLayout()
        layoutIfNeeded()
    }

    override public func becomeFirstResponder() -> Bool {
        return locationView.becomeFirstResponder()
    }

    override public func resignFirstResponder() -> Bool {
        return locationView.resignFirstResponder()
    }

    // MARK: - Private
    private func setupLayout() {
        addSubview(toolbarContainerView)
        addSubview(toolbarTopBorderView)
        addSubview(toolbarBottomBorderView)

        locationContainer.addSubview(locationView)
        locationContainer.addSubview(locationDividerView)
        locationContainer.addSubview(pageActionStack)

        toolbarContainerView.addSubview(navigationActionStack)
        toolbarContainerView.addSubview(locationContainer)
        toolbarContainerView.addSubview(browserActionStack)

        leadingLocationContainerConstraint = navigationActionStack.trailingAnchor.constraint(
            equalTo: locationContainer.leadingAnchor,
            constant: -UX.horizontalSpace)
        leadingLocationContainerConstraint?.isActive = true

        leadingBrowserActionConstraint = browserActionStack.leadingAnchor.constraint(
            equalTo: locationContainer.trailingAnchor,
            constant: UX.horizontalSpace)
        leadingBrowserActionConstraint?.isActive = true

        dividerWidthConstraint = locationDividerView.widthAnchor.constraint(equalToConstant: UX.dividerWidth)
        dividerWidthConstraint?.isActive = true

        [navigationActionStack, pageActionStack, browserActionStack].forEach(setZeroWidthConstraint)

        toolbarTopBorderHeightConstraint = toolbarTopBorderView.heightAnchor.constraint(equalToConstant: 0)
        toolbarBottomBorderHeightConstraint = toolbarBottomBorderView.heightAnchor.constraint(equalToConstant: 0)
        toolbarTopBorderHeightConstraint?.isActive = true
        toolbarBottomBorderHeightConstraint?.isActive = true

        NSLayoutConstraint.activate([
            toolbarContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbarContainerView.topAnchor.constraint(equalTo: toolbarTopBorderView.topAnchor,
                                                      constant: UX.verticalEdgeSpace),
            toolbarContainerView.bottomAnchor.constraint(equalTo: toolbarBottomBorderView.bottomAnchor,
                                                         constant: -UX.verticalEdgeSpace),
            toolbarContainerView.trailingAnchor.constraint(equalTo: trailingAnchor),

            toolbarTopBorderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbarTopBorderView.topAnchor.constraint(equalTo: topAnchor),
            toolbarTopBorderView.trailingAnchor.constraint(equalTo: trailingAnchor),

            toolbarBottomBorderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbarBottomBorderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            toolbarBottomBorderView.bottomAnchor.constraint(equalTo: bottomAnchor),

            navigationActionStack.leadingAnchor.constraint(equalTo: toolbarContainerView.leadingAnchor,
                                                           constant: UX.horizontalEdgeSpace),
            navigationActionStack.topAnchor.constraint(equalTo: toolbarContainerView.topAnchor),
            navigationActionStack.bottomAnchor.constraint(equalTo: toolbarContainerView.bottomAnchor),

            locationContainer.topAnchor.constraint(equalTo: toolbarContainerView.topAnchor),
            locationContainer.bottomAnchor.constraint(equalTo: toolbarContainerView.bottomAnchor),
            locationContainer.heightAnchor.constraint(equalToConstant: UX.locationHeight),

            locationView.leadingAnchor.constraint(equalTo: locationContainer.leadingAnchor),
            locationView.topAnchor.constraint(equalTo: locationContainer.topAnchor),
            locationView.trailingAnchor.constraint(equalTo: locationDividerView.leadingAnchor),
            locationView.bottomAnchor.constraint(equalTo: locationContainer.bottomAnchor),

            locationDividerView.topAnchor.constraint(equalTo: locationContainer.topAnchor),
            locationDividerView.trailingAnchor.constraint(equalTo: pageActionStack.leadingAnchor),
            locationDividerView.bottomAnchor.constraint(equalTo: locationContainer.bottomAnchor),

            pageActionStack.topAnchor.constraint(equalTo: locationContainer.topAnchor),
            pageActionStack.trailingAnchor.constraint(equalTo: locationContainer.trailingAnchor),
            pageActionStack.bottomAnchor.constraint(equalTo: locationContainer.bottomAnchor),

            browserActionStack.topAnchor.constraint(equalTo: toolbarContainerView.topAnchor),
            browserActionStack.trailingAnchor.constraint(equalTo: toolbarContainerView.trailingAnchor,
                                                         constant: -UX.horizontalEdgeSpace),
            browserActionStack.bottomAnchor.constraint(equalTo: toolbarContainerView.bottomAnchor),
        ])

        updateActionSpacing()
    }

    internal func updateActions(state: AddressToolbarState) {
        // Browser actions
        updateActionStack(stackView: browserActionStack, toolbarElements: state.browserActions)

        // Navigation actions
        updateActionStack(stackView: navigationActionStack, toolbarElements: state.navigationActions)

        // Page actions
        updateActionStack(stackView: pageActionStack, toolbarElements: state.pageActions)

        updateActionSpacing()
    }

    private func setZeroWidthConstraint(_ stackView: UIStackView) {
        let widthAnchor = stackView.widthAnchor.constraint(equalToConstant: 0)
        widthAnchor.isActive = true
        widthAnchor.priority = .defaultHigh
    }

    private func updateActionStack(stackView: UIStackView, toolbarElements: [ToolbarElement]) {
        stackView.removeAllArrangedViews()
        toolbarElements.forEach { toolbarElement in
            let button = toolbarElement.numberOfTabs != nil ? TabNumberButton() : ToolbarButton()
            button.configure(element: toolbarElement)
            stackView.addArrangedSubview(button)

            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: UX.buttonSize.width),
                button.heightAnchor.constraint(equalToConstant: UX.buttonSize.height),
            ])

            if let theme {
                // As we recreate the buttons we need to apply the theme for them to be displayed correctly
                button.applyTheme(theme: theme)
            }
        }
    }

    private func updateActionSpacing() {
        // Browser action spacing
        let hasBrowserActions = !browserActionStack.arrangedSubviews.isEmpty
        leadingBrowserActionConstraint?.constant = hasBrowserActions ? UX.horizontalSpace : 0

        // Navigation action spacing
        let hasNavigationActions = !navigationActionStack.arrangedSubviews.isEmpty
        leadingLocationContainerConstraint?.constant = hasNavigationActions ? -UX.horizontalSpace : 0

        // Page action spacing
        let hasPageActions = !pageActionStack.arrangedSubviews.isEmpty
        dividerWidthConstraint?.constant = hasPageActions ? UX.dividerWidth : 0
    }

    private func updateBorder(shouldDisplayTopBorder: Bool, shouldDisplayBottomBorder: Bool) {
        let topBorderHeight = shouldDisplayTopBorder ? UX.borderHeight : 0
        toolbarTopBorderHeightConstraint?.constant = topBorderHeight

        let bottomBorderHeight = shouldDisplayBottomBorder ? UX.borderHeight : 0
        toolbarBottomBorderHeightConstraint?.constant = bottomBorderHeight
    }

    // MARK: - LocationViewDelegate
    func locationViewDidEnterText(_ text: String) {
        toolbarDelegate?.searchSuggestions(searchTerm: text)
    }

    func locationViewDidBeginEditing(_ text: String) {
        toolbarDelegate?.openSuggestions(searchTerm: text.lowercased())
    }

    func locationViewShouldSearchFor(_ text: String) {
        guard !text.isEmpty else { return }

        toolbarDelegate?.openBrowser(searchTerm: text.lowercased())
    }

    func locationViewDisplayTextForURL(_ url: URL?) -> String? {
        toolbarDelegate?.shouldDisplayTextForURL(url)
    }

    // MARK: - ThemeApplicable
    public func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer1
        locationContainer.backgroundColor = theme.colors.layerSearch
        locationDividerView.backgroundColor = theme.colors.layer2
        toolbarTopBorderView.backgroundColor = theme.colors.borderPrimary
        toolbarBottomBorderView.backgroundColor = theme.colors.borderPrimary
        locationView.applyTheme(theme: theme)
        self.theme = theme
    }
}
