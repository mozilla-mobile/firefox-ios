// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Common

struct HomepageHeaderCellViewModel {
    var showiPadSetup: Bool
}

// Header for the homepage in both normal and private mode
// Contains the firefox logo and the private browsing shortcut button
class LegacyHomepageHeaderCell: UICollectionViewCell, ReusableCell, ThemeApplicable {
    enum UX {
        static let iPhoneTopConstant: CGFloat = 16
        static let iPadTopConstant: CGFloat = 54
        static let circleSize = CGRect(width: 40, height: 40)
    }

    var viewModel: HomepageHeaderCellViewModel?

    private lazy var stackContainer: UIStackView = .build { stackView in
        stackView.axis = .horizontal
    }

    private lazy var logoHeaderCell: HomeLogoHeaderCell = {
        let logoHeader = HomeLogoHeaderCell()
        return logoHeader
    }()

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup

    private func setupView(with showiPadSetup: Bool) {
        stackContainer.addArrangedSubview(logoHeaderCell.contentView)
        contentView.addSubview(stackContainer)

        setupConstraints(for: showiPadSetup)
    }

    private var logoConstraints = [NSLayoutConstraint]()

    private func setupConstraints(for iPadSetup: Bool) {
        NSLayoutConstraint.deactivate(logoConstraints)
        let topAnchorConstant = iPadSetup ? UX.iPadTopConstant : UX.iPhoneTopConstant
        logoConstraints = [
            stackContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: topAnchorConstant),
            stackContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).priority(.defaultLow),

            logoHeaderCell.contentView.centerYAnchor.constraint(equalTo: stackContainer.centerYAnchor)
        ]

        NSLayoutConstraint.activate(logoConstraints)
    }

    func configure(with viewModel: HomepageHeaderCellViewModel) {
        self.viewModel = viewModel
        setupView(with: viewModel.showiPadSetup)
        logoHeaderCell.configure(with: viewModel.showiPadSetup)
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        logoHeaderCell.applyTheme(theme: theme)
    }
}
