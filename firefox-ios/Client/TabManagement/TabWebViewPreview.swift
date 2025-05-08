// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Redux

final class TabWebViewPreview: UIView, Notifiable, ThemeApplicable, StoreSubscriber {
    // MARK: - UX Constants
    private struct UX {
        static let addressBarCornerRadius: CGFloat = 8
        static let addressBarBorderHeight: CGFloat = 1
        static let addressBarHeight: CGFloat = 44
        static let addressBarMaxHeight: CGFloat = 54
        static let edgePadding: CGFloat = 7
        static let addressBarOnTopLayoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        static let addressBarOnBottomLayoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 4, right: 16)
    }
    var notificationCenter: any NotificationProtocol = NotificationCenter.default
    private var state: TabWebViewPreviewState = .init(windowUUID: .unavailable)
    private let windowUUID: WindowUUID

    // MARK: - UI Properties
    private lazy var webPageScreenshotImageView: UIImageView = .build()
    private lazy var addressBarBorderView: UIView = .build()

    private lazy var topStackView = createStackView()
    private lazy var bottomStackView = createStackView()

    private lazy var skeletonAddressBar: UIView = .build { addressBar in
        addressBar.layer.cornerRadius = TabWebViewPreviewAppearanceConfiguration.addressBarCornerRadius
    }
    // MARK: - Constraint Properties
    private var webViewTopConstraint: NSLayoutConstraint?
    private var webViewBottomConstraint: NSLayoutConstraint?
    private var addressBarBorderViewTopBottomConstraint: NSLayoutConstraint?
    private var addressBarHeightConstraint: NSLayoutConstraint?

    // MARK: Inits
    init(windowUUID: WindowUUID) {
        self.windowUUID = windowUUID
        super.init(frame: .zero)
        setupLayout()
        setupNotifications(forObserver: self, observing: [UIContentSizeCategory.didChangeNotification])
        setStackViewsLayoutMargins()
        adjustSkeletonAddressBarHeightForA11ySizeCategory()
        updateLayoutBasedOn(searchBarPosition: state.searchBarPosition)
        subscribeToRedux()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout
    private func setupLayout() {
        addSubviews(webPageScreenshotImageView, topStackView, bottomStackView, addressBarBorderView)

        addressBarHeightConstraint = skeletonAddressBar.heightAnchor
            .constraint(equalToConstant: UX.addressBarHeight)
        addressBarHeightConstraint?.isActive = true

        NSLayoutConstraint.activate([
            addressBarBorderView.heightAnchor.constraint(equalToConstant: UX.addressBarBorderHeight),
            addressBarBorderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            addressBarBorderView.trailingAnchor.constraint(equalTo: trailingAnchor),

            topStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            topStackView.topAnchor.constraint(equalTo: topAnchor),
            topStackView.trailingAnchor.constraint(equalTo: trailingAnchor),

            webPageScreenshotImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webPageScreenshotImageView.trailingAnchor.constraint(equalTo: trailingAnchor),

            bottomStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomStackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    // MARK: - Redux
    func subscribeToRedux() {
        store.dispatch(
            ScreenAction(
                windowUUID: windowUUID,
                actionType: ScreenActionType.showScreen,
                screen: .tabWebViewPreview
            )
        )

        let uuid = windowUUID
        store.subscribe(self, transform: {
            $0.select({ appState in
                return TabWebViewPreviewState(appState: appState, uuid: uuid)
            })
        })
    }

    func unsubscribeFromRedux() {
        store.unsubscribe(self)
    }

    func newState(state: TabWebViewPreviewState) {
        updateView(from: state)
    }

    private func updateView(from state: TabWebViewPreviewState) {
        webPageScreenshotImageView.image = state.screenshot
        guard self.state.searchBarPosition != state.searchBarPosition else { return }
        self.state = state
        updateLayoutBasedOn(searchBarPosition: state.searchBarPosition)
    }

    // MARK: - A11y
    private func adjustSkeletonAddressBarHeightForA11ySizeCategory() {
        let scaledHeight = min(UIFontMetrics.default.scaledValue(for: UX.addressBarHeight), UX.addressBarMaxHeight)
        let isA11yCategory = UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory
        addressBarHeightConstraint?.constant = isA11yCategory ? scaledHeight : UX.addressBarHeight
    }

    private func updateLayoutBasedOn(searchBarPosition: SearchBarPosition) {
        topStackView.removeAllArrangedViews()
        bottomStackView.removeAllArrangedViews()

        webViewTopConstraint?.isActive = false
        webViewBottomConstraint?.isActive = false
        addressBarBorderViewTopBottomConstraint?.isActive = false

        setStackViewsVisibility(by: searchBarPosition)
        switch searchBarPosition {
        case .bottom:
            bottomStackView.addArrangedSubview(skeletonAddressBar)
            webViewTopConstraint = webPageScreenshotImageView.topAnchor.constraint(equalTo: topAnchor)
            addressBarBorderViewTopBottomConstraint = addressBarBorderView.bottomAnchor.constraint(
                equalTo: skeletonAddressBar.topAnchor, constant: -UX.edgePadding
            )
            webViewBottomConstraint = webPageScreenshotImageView.bottomAnchor.constraint(
                equalTo: addressBarBorderView.topAnchor
            )
        case .top:
            topStackView.addArrangedSubview(skeletonAddressBar)
            webViewTopConstraint = webPageScreenshotImageView.topAnchor.constraint(equalTo: topStackView.bottomAnchor)
            addressBarBorderViewTopBottomConstraint = addressBarBorderView.topAnchor.constraint(
                equalTo: skeletonAddressBar.bottomAnchor, constant: UX.edgePadding
            )
            webViewBottomConstraint = webPageScreenshotImageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        }

        webViewTopConstraint?.isActive = true
        webViewBottomConstraint?.isActive = true
        addressBarBorderViewTopBottomConstraint?.isActive = true
    }

    private func setScreenshot(_ image: UIImage?) {
        webPageScreenshotImageView.image = image
    }

    // MARK: - Helper Functions
    private func createStackView() -> UIStackView {
        return .build { stackView in
            stackView.axis = .vertical
            stackView.isLayoutMarginsRelativeArrangement = true
        }
    }

    private func setStackViewsLayoutMargins() {
        topStackView.layoutMargins = UX.addressBarOnTopLayoutMargins
        bottomStackView.layoutMargins = UX.addressBarOnBottomLayoutMargins
    }

    private func setStackViewsVisibility(by searchBarPosition: SearchBarPosition) {
        let isBottom = searchBarPosition == .bottom
        bottomStackView.isHidden = !isBottom
        topStackView.isHidden = isBottom
    }

    // MARK: - Notifiable
    public func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIContentSizeCategory.didChangeNotification:
            adjustSkeletonAddressBarHeightForA11ySizeCategory()
        default: break
        }
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Common.Theme) {
        let colors = theme.colors
        let appearance: TabWebViewPreviewAppearanceConfiguration = .getAppearance(basedOn: theme)
        addressBarBorderView.backgroundColor = colors.borderPrimary
        topStackView.backgroundColor = appearance.containerStackViewBackgroundColor
        bottomStackView.backgroundColor = appearance.containerStackViewBackgroundColor
        skeletonAddressBar.backgroundColor = appearance.addressBarBackgroundColor
    }
}
