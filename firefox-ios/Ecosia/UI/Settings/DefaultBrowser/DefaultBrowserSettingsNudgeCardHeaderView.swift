// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SwiftUI
import Common

/// Reusable Nudge Card Header View that can be configured with any view model.
public final class DefaultBrowserSettingsNudgeCardHeaderView: UITableViewHeaderFooterView, ThemeApplicable, ReusableCell {

    // MARK: - Properties
    var theme: Theme!
    private var hostingController: UIHostingController<AnyView>?
    public var onDismiss: (() -> Void)?
    public var onTap: (() -> Void)?

    // MARK: - UX Constants

    private enum UX {
        static let paddingTop: CGFloat = 24
    }

    // MARK: - Initializer

    override public init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupHostingControllerForView(_ view: ConfigurableNudgeCardView) {
        let controller = UIHostingController(rootView: AnyView(
            VStack(spacing: 0) {
                view
                    .padding(.top, UX.paddingTop)
            }
        ))
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        controller.view.backgroundColor = .clear
        controller.view.isAccessibilityElement = false
        contentView.addSubview(controller.view)

        NSLayoutConstraint.activate([
            controller.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            controller.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            controller.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            controller.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        hostingController = controller
    }

    // MARK: - Configuration Method

    /// Configures the Nudge Card Header View using the ViewModel.
    public func configure(theme: Theme?) {
        self.theme = theme
        guard let theme else { return }
        let nudgeCardStyle = NudgeCardStyle(backgroundColor: Color(theme.colors.ecosia.backgroundElevation1),
                                            textPrimaryColor: Color(theme.colors.ecosia.textPrimary),
                                            textSecondaryColor: Color(theme.colors.ecosia.textSecondary),
                                            closeButtonTextColor: Color(theme.colors.ecosia.buttonContentSecondary),
                                            actionButtonTextColor: Color(theme.colors.ecosia.buttonBackgroundPrimary))
        let configurableCardViewModel = NudgeCardViewModel(title: .localized(.defaultBrowserCardTitle),
                                                           description: .localized(.defaultBrowserCardDescription),
                                                           image: .init(named: "default-browser-card-side-image-koto-illustrations",
                                                                        in: .ecosia,
                                                                        with: nil),
                                                           style: nudgeCardStyle,
                                                           layout: .default)
        let view = ConfigurableNudgeCardView(viewModel: configurableCardViewModel,
                                             delegate: self)
        setupHostingControllerForView(view)
    }

    // MARK: - Theming
    public func applyTheme(theme: Theme) {
        configure(theme: theme)
    }
}

extension DefaultBrowserSettingsNudgeCardHeaderView: ConfigurableNudgeCardActionDelegate {

    public func nudgeCardRequestToPerformAction() {}

    public func nudgeCardRequestToDimiss() {
        onDismiss?()
    }

    public func nudgeCardTapped() {
        onTap?()
    }
}
