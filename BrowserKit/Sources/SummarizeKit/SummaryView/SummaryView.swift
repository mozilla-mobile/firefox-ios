// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit
import ComponentLibrary

struct SummaryViewModel {
    let title: String?
    let titleA11yId: String
    let compactTitleA11yId: String

    let brandIcon: UIImage?
    let brandIconA11yId: String
    let brandName: String
    let brandNameA11yId: String

    let summary: NSAttributedString?
    let summaryA11yId: String
    let contentOffset: UIEdgeInsets
}

final class SummaryView: UIView, UITableViewDataSource, UITableViewDelegate, ThemeApplicable {
    private struct UX {
        static let closeButtonEdgePadding: CGFloat = 16.0
        static let tableViewHorizontalPadding: CGFloat = 16.0
        static let compactTitleAnimationOffset: CGFloat = 20.0
        static let compactTitleAnimationDuration: CGFloat = 0.3
        static let compactTitlePadding: CGFloat = 16.0
    }
    private enum Section: Int, CaseIterable {
        case title, brand, summary
    }
    private let tableView: UITableView = .build {
        $0.backgroundColor = .clear
        $0.separatorStyle = .none
        $0.allowsSelection = false
        $0.showsVerticalScrollIndicator = false
        $0.alpha = 0.0
    }
    private let compactTitleLabel: UILabel = .build {
        $0.numberOfLines = 2
        $0.font = FXFontStyles.Bold.body.scaledFont()
        $0.adjustsFontForContentSizeCategory = true
        $0.showsLargeContentViewer = true
        $0.isUserInteractionEnabled = true
        $0.addInteraction(UILargeContentViewerInteraction())
        $0.accessibilityTraits.insert(.header)
        $0.alpha = 0.0
    }
    private let compactTitleContainer: UIView = .build()
    private let compactTitleBackgroundEffectView: UIVisualEffectView = .build {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            $0.effect = UIGlassEffect(style: .regular)
        } else {
            $0.effect = UIBlurEffect(style: .systemUltraThinMaterial)
        }
        #else
        $0.effect = UIBlurEffect(style: .systemUltraThinMaterial)
        #endif
        $0.alpha = 0.0
    }
    private let closeButton: UIButton = .build {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            $0.configuration = .prominentClearGlass()
        } else {
            $0.configuration = .filled()
            $0.configuration?.cornerStyle = .capsule
        }
        #else
            $0.configuration = .filled()
            $0.configuration?.cornerStyle = .capsule
        #endif
        $0.adjustsImageSizeForAccessibilityContentSizeCategory = true
        $0.setImage(UIImage(named: StandardImageIdentifiers.Large.cross)?.withRenderingMode(.alwaysTemplate),
                    for: .normal)
    }
    private var theme: Theme?
    private var model: SummaryViewModel?

    init(closeButtonViewModel: CloseButtonViewModel,
         closeButtonAction: @escaping () -> Void) {
        super.init(frame: .zero)
        setup(closeButtonViewModel: closeButtonViewModel, closeButtonAction: closeButtonAction)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup(closeButtonViewModel: CloseButtonViewModel, closeButtonAction: @escaping () -> Void) {
        tableView.dataSource = self
        tableView.delegate = self

        tableView.register(cellType: SummaryTitleCell.self)
        tableView.register(cellType: SummaryBrandCell.self)
        tableView.register(cellType: SummaryTextCell.self)
        
        closeButton.accessibilityIdentifier = closeButtonViewModel.a11yIdentifier
        closeButton.accessibilityLabel = closeButtonViewModel.a11yLabel
        closeButton.addAction(UIAction(handler: { _ in
            closeButtonAction()
        }), for: .touchUpInside)

        compactTitleContainer.addSubviews(compactTitleBackgroundEffectView, compactTitleLabel)
        addSubviews(tableView, compactTitleContainer, closeButton)

        closeButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        closeButton.setContentHuggingPriority(.required, for: .vertical)
        compactTitleBackgroundEffectView.pinToSuperview()
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.tableViewHorizontalPadding),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.tableViewHorizontalPadding),
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),

            compactTitleContainer.topAnchor.constraint(equalTo: topAnchor),
            compactTitleContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            compactTitleContainer.trailingAnchor.constraint(equalTo: trailingAnchor),

            compactTitleLabel.topAnchor.constraint(equalTo: compactTitleContainer.safeAreaLayoutGuide.topAnchor,
                                                   constant: UX.compactTitlePadding),
            compactTitleLabel.leadingAnchor.constraint(equalTo: compactTitleContainer.leadingAnchor,
                                                       constant: UX.compactTitlePadding),
            compactTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor,
                                                        constant: -UX.compactTitlePadding),
            compactTitleLabel.bottomAnchor.constraint(equalTo: compactTitleContainer.bottomAnchor,
                                                      constant: -UX.compactTitlePadding),

            closeButton.trailingAnchor.constraint(equalTo: compactTitleContainer.trailingAnchor,
                                                  constant: -UX.closeButtonEdgePadding),
            closeButton.topAnchor.constraint(equalTo: compactTitleContainer.safeAreaLayoutGuide.topAnchor,
                                             constant: UX.closeButtonEdgePadding),
            closeButton.bottomAnchor.constraint(lessThanOrEqualTo: compactTitleContainer.bottomAnchor)
        ])
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.row), let model else {
            return UITableViewCell()
        }
        let cell: UITableViewCell
        switch section {
        case .title:
            cell = tableView.dequeueReusableCell(withIdentifier: SummaryTitleCell.cellIdentifier, for: indexPath)
            if let cell = cell as? SummaryTitleCell {
                cell.configure(text: model.title, a11yId: model.titleA11yId)
            }
        case .brand:
            cell = tableView.dequeueReusableCell(withIdentifier: SummaryBrandCell.cellIdentifier, for: indexPath)
            if let cell = cell as? SummaryBrandCell {
                cell.configure(
                    text: model.brandName,
                    textA11yId: model.brandNameA11yId,
                    logo: model.brandIcon,
                    logoA11yId: model.brandIconA11yId
                )
            }
        case .summary:
            cell = tableView.dequeueReusableCell(withIdentifier: SummaryTextCell.cellIdentifier, for: indexPath)
            if let cell = cell as? SummaryTextCell {
                cell.configure(text: model.summary, a11yId: model.summaryA11yId)
            }
        }
        if let cell = cell as? ThemeApplicable, let theme {
            cell.applyTheme(theme: theme)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func configure(model: SummaryViewModel) {
        self.model = model
        compactTitleLabel.text = model.title
        compactTitleLabel.accessibilityIdentifier = model.titleA11yId
        tableView.contentInset = model.contentOffset
        tableView.reloadData()
    }

    func showContent() {
        tableView.alpha = 1.0
    }

    // MARK: - UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Determine the threshold for showing/hiding the compact title.
        // The threshold must include both the table view’s top contentInset
        // and its safe area inset, since the contentOffset.y does not start
        // at 0 but instead reflects these insets.
        let topInset = abs(tableView.contentInset.top) + abs(tableView.safeAreaInsets.top)
        let shouldShowTitle = scrollView.contentOffset.y + topInset - UX.compactTitleAnimationOffset > 0
        let shouldAnimate = compactTitleLabel.alpha != (shouldShowTitle ? 1.0 : 0.0)
        guard shouldAnimate else { return }
        UIView.animate(withDuration: UX.compactTitleAnimationDuration) { [self] in
            compactTitleLabel.alpha = shouldShowTitle ? 1.0 : 0.0
            compactTitleBackgroundEffectView.alpha = shouldShowTitle ? 1.0 : 0.0
        }
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        self.theme = theme
        compactTitleLabel.textColor = theme.colors.textPrimary
        if #unavailable(iOS 26) {
            closeButton.configuration?.baseBackgroundColor = theme.colors.actionTabActive
        }
        closeButton.configuration?.baseForegroundColor = theme.colors.textPrimary
        tableView.reloadData()
    }
}
