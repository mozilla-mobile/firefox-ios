// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared
import ComponentLibrary

class NoAnalysisCardViewModel {
    let cardA11yId: String
    let headlineLabelText: String
    let headlineLabelA11yId: String
    let bodyLabelText: String
    let bodyLabelA11yId: String
    let footerLabelText: String
    let footerLabelA11yId: String
    var onTapStartAnalysis: (() -> Void)?

    init(cardA11yId: String,
         headlineLabelText: String,
         headlineLabelA11yId: String,
         bodyLabelText: String,
         bodyLabelA11yId: String,
         footerLabelText: String,
         footerLabelA11yId: String) {
        self.cardA11yId = cardA11yId
        self.headlineLabelText = headlineLabelText
        self.headlineLabelA11yId = headlineLabelA11yId
        self.bodyLabelText = bodyLabelText
        self.bodyLabelA11yId = bodyLabelA11yId
        self.footerLabelText = footerLabelText
        self.footerLabelA11yId = footerLabelA11yId
    }
}

final class NoAnalysisCardView: UIView, ThemeApplicable {
    private struct UX {
        static let noAnalysisImageViewSize: CGFloat = 104
        static let headlineLabelFontSize: CGFloat = 15
        static let bodyLabelFontSize: CGFloat = 13
        static let footerLabellFontSize: CGFloat = 13
        static let contentStackViewSpacing: CGFloat = 8
        static let contentStackViewPadding: CGFloat = 16
    }

    private var viewModel: NoAnalysisCardViewModel?

    private lazy var cardContainer: ShadowCardView = .build()

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
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .headline,
                                                            size: UX.headlineLabelFontSize,
                                                            weight: .bold)
    }

    private lazy var bodyLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                            size: UX.bodyLabelFontSize)
    }

    private let footerLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        label.adjustsFontForContentSizeCategory = true
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                            size: UX.footerLabellFontSize)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        let tapGesture = UITapGestureRecognizer(target: self,
                                                action: #selector(didTapStartAnalysis))
        footerLabel.addGestureRecognizer(tapGesture)
        addSubview(cardContainer)
        addSubview(contentStackView)
        [noAnalysisImageView,
         headlineLabel,
         bodyLabel,
         footerLabel].forEach(contentStackView.addArrangedSubview)

        NSLayoutConstraint.activate([
            cardContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardContainer.topAnchor.constraint(equalTo: topAnchor),
            cardContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: topAnchor,
                                                  constant: UX.contentStackViewPadding),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor,
                                                     constant: -UX.contentStackViewPadding),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor,
                                                      constant: UX.contentStackViewPadding),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                       constant: -UX.contentStackViewPadding),

            noAnalysisImageView.widthAnchor.constraint(equalToConstant: UX.noAnalysisImageViewSize),
            noAnalysisImageView.heightAnchor.constraint(equalToConstant: UX.noAnalysisImageViewSize)
        ])
    }

    @objc
    private func didTapStartAnalysis() {
        viewModel?.onTapStartAnalysis?()
    }

    func configure(_ viewModel: NoAnalysisCardViewModel) {
        self.viewModel = viewModel

        headlineLabel.text = viewModel.headlineLabelText
        headlineLabel.accessibilityIdentifier = viewModel.headlineLabelA11yId

        bodyLabel.text = viewModel.bodyLabelText
        bodyLabel.accessibilityIdentifier = viewModel.bodyLabelA11yId

        footerLabel.text = viewModel.footerLabelText
        footerLabel.accessibilityIdentifier = viewModel.footerLabelA11yId

        let cardModel = ShadowCardViewModel(view: contentStackView, a11yId: viewModel.cardA11yId)
        cardContainer.configure(cardModel)
    }

    // MARK: - Theming System
    func applyTheme(theme: Theme) {
        cardContainer.applyTheme(theme: theme)
        let colors = theme.colors
        headlineLabel.textColor = colors.textPrimary
        bodyLabel.textColor = colors.textPrimary
        footerLabel.textColor = colors.textAccent
    }
}
