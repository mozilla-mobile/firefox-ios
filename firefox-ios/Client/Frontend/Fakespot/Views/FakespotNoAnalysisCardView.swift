// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared
import ComponentLibrary
import Account

struct FakespotNoAnalysisCardViewModel {
    let cardA11yId: String = AccessibilityIdentifiers.Shopping.NoAnalysisCard.card
    let headlineLabelText: String = .Shopping.NoAnalysisCardHeadlineLabelTitle
    let headlineLabelA11yId: String = AccessibilityIdentifiers.Shopping.NoAnalysisCard.headlineTitle
    let bodyLabelText: String = .Shopping.NoAnalysisCardBodyLabelTitle
    let bodyLabelA11yId: String = AccessibilityIdentifiers.Shopping.NoAnalysisCard.bodyTitle
    let analyzerButtonText: String = .Shopping.NoAnalysisCardAnalyzerButtonTitle
    let analyzerButtonA11yId: String = AccessibilityIdentifiers.Shopping.NoAnalysisCard.analyzerButtonTitle
    var onTapStartAnalysis: (() -> Void)?

    func recordStartAnalysisTelemetry() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .shoppingNoAnalysisCardViewPrimaryButton
        )
    }
}

final class FakespotNoAnalysisCardView: UIView, ThemeApplicable {
    private struct UX {
        static let noAnalysisImageViewSize = CGSize(width: 280, height: 108)
        static let contentStackViewSpacing: CGFloat = 8
        static let contentStackViewPadding: CGFloat = 8
        static let titleStackViewSpacing: CGFloat = 8
    }

    private var viewModel: FakespotNoAnalysisCardViewModel?

    private lazy var cardContainer: ShadowCardView = .build()
    private lazy var mainView: UIView = .build()

    private lazy var contentStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.contentStackViewSpacing
    }

    private lazy var noAnalysisImageView: UIImageView = .build { imageView in
        imageView.image = UIImage(named: ImageIdentifiers.shoppingNoAnalysisImage)
        imageView.contentMode = .scaleAspectFit
    }

    private lazy var headlineLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Bold.subheadline.scaledFont()
        label.accessibilityTraits.insert(.header)
    }

    private lazy var bodyLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.footnote.scaledFont()
    }

    private lazy var analyzerButton: PrimaryRoundedButton = .build { button in
        button.addTarget(self, action: #selector(self.didTapStartAnalysis), for: .touchUpInside)
    }

    private lazy var titleStackView: UIStackView = .build { view in
        view.axis = .horizontal
        view.spacing = UX.titleStackViewSpacing
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ viewModel: FakespotNoAnalysisCardViewModel) {
        self.viewModel = viewModel

        headlineLabel.text = viewModel.headlineLabelText
        headlineLabel.accessibilityIdentifier = viewModel.headlineLabelA11yId

        bodyLabel.text = viewModel.bodyLabelText
        bodyLabel.accessibilityIdentifier = viewModel.bodyLabelA11yId

        let buttonViewModel = PrimaryRoundedButtonViewModel(title: viewModel.analyzerButtonText,
                                                            a11yIdentifier: viewModel.analyzerButtonA11yId)
        analyzerButton.configure(viewModel: buttonViewModel)

        let cardModel = ShadowCardViewModel(view: mainView, a11yId: viewModel.cardA11yId)
        cardContainer.configure(cardModel)
    }

    // MARK: - Theming System
    func applyTheme(theme: Theme) {
        cardContainer.applyTheme(theme: theme)
        analyzerButton.applyTheme(theme: theme)

        let colors = theme.colors
        headlineLabel.textColor = colors.textPrimary
        bodyLabel.textColor = colors.textPrimary
    }

    private func setupLayout() {
        addSubviews(cardContainer)
        titleStackView.addArrangedSubview(headlineLabel)
        mainView.addSubview(contentStackView)
        contentStackView.addArrangedSubview(noAnalysisImageView)
        contentStackView.addArrangedSubview(titleStackView)
        contentStackView.addArrangedSubview(bodyLabel)
        contentStackView.addArrangedSubview(analyzerButton)

        NSLayoutConstraint.activate([
            cardContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardContainer.topAnchor.constraint(equalTo: topAnchor),
            cardContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: mainView.topAnchor,
                                                  constant: UX.contentStackViewPadding),
            contentStackView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor,
                                                     constant: -UX.contentStackViewPadding),
            contentStackView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor,
                                                      constant: UX.contentStackViewPadding),
            contentStackView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor,
                                                       constant: -UX.contentStackViewPadding),

            noAnalysisImageView.widthAnchor.constraint(equalToConstant: UX.noAnalysisImageViewSize.width),
            noAnalysisImageView.heightAnchor.constraint(equalToConstant: UX.noAnalysisImageViewSize.height)
        ])
    }

    @objc
    private func didTapStartAnalysis() {
        viewModel?.onTapStartAnalysis?()
        viewModel?.recordStartAnalysisTelemetry()
    }
}
