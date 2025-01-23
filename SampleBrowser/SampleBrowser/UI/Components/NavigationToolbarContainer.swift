// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ToolbarKit
import UIKit

protocol NavigationToolbarDelegate: AnyObject {
    func backButtonTapped()
    func forwardButtonTapped()
    func reloadButtonTapped()
    func stopButtonTapped()
    func menuButtonTapped()
}

class NavigationToolbarContainer: UIView,
                                  ThemeApplicable,
                                  BrowserNavigationToolbarDelegate {
    private enum UX {
        static let toolbarHeight: CGFloat = 48
    }

    private lazy var toolbar: BrowserNavigationToolbar =  .build { _ in }
    private var toolbarHeightConstraint: NSLayoutConstraint?

    private var bottomToolbarHeight: CGFloat { return UX.toolbarHeight + bottomInset }

    private var bottomInset: CGFloat {
        var bottomInset: CGFloat = 0.0
        if let window = attachedKeyWindow {
            bottomInset = window.safeAreaInsets.bottom
        }
        return bottomInset
    }

    private var attachedKeyWindow: UIWindow? {
        // swiftlint:disable first_where
        return UIApplication.shared.connectedScenes
            .filter { $0.activationState != .unattached }
            .first(where: { $0 is UIWindowScene })
            .flatMap({ $0 as? UIWindowScene })?.windows
            .first(where: \.isKeyWindow)
        // swiftlint:enable first_where
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // when the layout is setup the window scene is not attached yet so we need to update the constant later
        toolbarHeightConstraint?.constant = bottomToolbarHeight
    }

    func configure(_ model: NavigationToolbarContainerModel) {
        toolbar.configure(state: model.state, toolbarDelegate: self)
    }

    private func setupLayout() {
        addSubview(toolbar)

        toolbarHeightConstraint = heightAnchor.constraint(equalToConstant: bottomToolbarHeight)
        toolbarHeightConstraint?.isActive = true

        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbar.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            toolbar.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    // MARK: - BrowserNavigationToolbarDelegate
    func configureContextualHint(for button: UIButton, with contextualHintType: String) {
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        toolbar.applyTheme(theme: theme)
        backgroundColor = theme.colors.layer1
    }
}
