// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SwiftUI
import Common
import Ecosia

/// Reusable Nudge Card Cell that can be configured with any view model.
class NTPConfigurableNudgeCardCell: UICollectionViewCell, ThemeApplicable, ReusableCell {

    // MARK: - Properties

    private var viewModel: NTPConfigurableNudgeCardCellViewModel?
    weak var delegate: NTPConfigurableNudgeCardCellDelegate?
    var theme: Theme!
    private var hostingController: UIHostingController<ConfigurableNudgeCardView>?

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHostingController()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupHostingController() {
        let view = ConfigurableNudgeCardView()
        let controller = UIHostingController(rootView: view)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        controller.view.backgroundColor = .clear

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

    /// Configures the Nudge Card Cell using the ViewModel.
    func configure(with viewModel: NTPConfigurableNudgeCardCellViewModel, theme: Theme?) {
        self.viewModel = viewModel
        self.theme = theme
        delegate = viewModel.delegate
        guard let theme else { return }
        let nudgeCardStyle = NudgeCardStyle(backgroundColor: theme.colors.ecosia.backgroundSecondary.color,
                                            textPrimaryColor: theme.colors.ecosia.textPrimary.color,
                                            textSecondaryColor: theme.colors.ecosia.textSecondary.color,
                                            closeButtonTextColor: theme.colors.ecosia.buttonContentSecondary.color,
                                            actionButtonTextColor: theme.colors.ecosia.buttonBackgroundPrimary.color)
        let configurableCardViewModel = NudgeCardViewModel(title: viewModel.title,
                                                           description: viewModel.description,
                                                           buttonText: viewModel.buttonText,
                                                           image: viewModel.image,
                                                           style: nudgeCardStyle)
        hostingController?.rootView = ConfigurableNudgeCardView(viewModel: configurableCardViewModel, delegate: self)
    }

    // MARK: - Theming
    func applyTheme(theme: Theme) {
        guard let viewModel else { return }
        configure(with: viewModel, theme: theme)
    }
}

extension NTPConfigurableNudgeCardCell: ConfigurableNudgeCardActionDelegate {

    func nudgeCardRequestToPerformAction() {
        guard let sectionType = viewModel?.sectionType else { return }
        delegate?.nudgeCardRequestToPerformAction(for: sectionType)
    }

    func nudgeCardRequestToDimiss() {
        guard let sectionType = viewModel?.sectionType else { return }
        delegate?.nudgeCardRequestToDimiss(for: sectionType)
    }

    func nudgeCardTapped() {}
}
