// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit


struct SummaryModel {
    let title: String?
    let titleA11yId: String
    
    let brandIcon: UIImage
    let brandName: String
    
    let summary: NSAttributedString?
    let contentOffset: UIEdgeInsets
}

class SummaryView: UIView, UITableViewDataSource, UITableViewDelegate, ThemeApplicable {
    private struct UX {
        static let closeButtonEdgePadding: CGFloat = 16.0
        static let tableViewHorizontalPadding: CGFloat = 16.0
        static let smallTitleAnimationOffset: CGFloat = 20.0
    }
    private enum Section: Int, CaseIterable {
        case title, brand, summary
    }
    private let tableView: UITableView = .build {
        $0.backgroundColor = .clear
        $0.separatorStyle = .none
        $0.allowsSelection = false
    }
    private let titleLabel: UILabel = .build {
        $0.numberOfLines = 2
        $0.font = FXFontStyles.Bold.body.scaledFont()
    }
    private let titleContainer: UIView = .build()
    private let titleBackgroundEffectView: UIVisualEffectView = .build {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            $0.effect = UIGlassEffect(style: .regular)
        } else {
            $0.effect = UIBlurEffect(style: .systemUltraThinMaterial)
        }
        #else
        $0.effect = UIBlurEffect(style: .systemUltraThinMaterial)
        #endif
    }
    private let closeButton: UIButton = .build {
        // This checks for Xcode 26 sdk availability thus we can compile on older Xcode version too
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
    private var model: SummaryModel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        tableView.dataSource = self
        tableView.delegate = self
        // Scroll events are handled to update titleContainer visibility
        
        tableView.register(cellType: SummaryTitleCell.self)
        tableView.register(cellType: SummaryBrandCell.self)
        tableView.register(cellType: SummaryTextCell.self)
        
        titleContainer.addSubviews(titleBackgroundEffectView, titleLabel, closeButton)
        addSubviews(tableView, titleContainer)
        
        closeButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleBackgroundEffectView.pinToSuperview()
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.tableViewHorizontalPadding),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.tableViewHorizontalPadding),
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            titleContainer.topAnchor.constraint(equalTo: topAnchor),
            titleContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: titleContainer.safeAreaLayoutGuide.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: titleContainer.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: titleContainer.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: titleContainer.bottomAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            
            closeButton.trailingAnchor.constraint(equalTo: titleContainer.trailingAnchor, constant: -UX.closeButtonEdgePadding),
            closeButton.topAnchor.constraint(equalTo: titleContainer.safeAreaLayoutGuide.topAnchor, constant: UX.closeButtonEdgePadding),
        ])
        
        titleLabel.alpha = 0.0
        titleBackgroundEffectView.alpha = 0.0
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
                cell.configure(text: model.title)
            }
        case .brand:
            cell = tableView.dequeueReusableCell(withIdentifier: SummaryBrandCell.cellIdentifier, for: indexPath)
            if let cell = cell as? SummaryBrandCell {
                cell.configure(text: model.brandName, logo: model.brandIcon)
            }
        case .summary:
            cell = tableView.dequeueReusableCell(withIdentifier: SummaryTextCell.cellIdentifier, for: indexPath)
            if let cell = cell as? SummaryTextCell {
                cell.configure(text: model.summary)
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
    
    func configure(model: SummaryModel) {
        self.model = model
        titleLabel.text = model.title
        titleLabel.accessibilityIdentifier = model.titleA11yId
        tableView.contentInset = model.contentOffset
        tableView.reloadData()
    }
    
    // MARK: - UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let topInset = abs(tableView.contentInset.top) + abs(tableView.safeAreaInsets.top)
        let shouldShowTitle = abs(scrollView.contentOffset.y) < topInset - UX.smallTitleAnimationOffset
        let shouldAnimate = titleLabel.alpha != (shouldShowTitle ? 1.0 : 0.0)
        guard shouldAnimate else { return }
        UIView.animate(withDuration: 0.25) { [self] in
            titleLabel.alpha = shouldShowTitle ? 1.0 : 0.0
            titleBackgroundEffectView.alpha = shouldShowTitle ? 1.0 : 0.0
        }
    }
    
    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        self.theme = theme
        titleLabel.textColor = theme.colors.textPrimary
        if #unavailable(iOS 26) {
            closeButton.configuration?.baseBackgroundColor = theme.colors.actionTabActive
        }
        closeButton.configuration?.baseForegroundColor = theme.colors.textPrimary
        tableView.reloadData()
    }
}

class SummaryTitleCell: UITableViewCell, ReusableCell, ThemeApplicable {
    private let titleLabel: UILabel = .build {
        $0.font = FXFontStyles.Bold.title1.scaledFont()
        $0.numberOfLines = 0
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }

    func configure(text: String?) {
        titleLabel.text = text
    }
    
    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        titleLabel.textColor = theme.colors.textPrimary
        backgroundColor = .clear
    }
}

class SummaryBrandCell: UITableViewCell, ReusableCell, ThemeApplicable {
    private struct UX {
        static let logoSize: CGFloat = 16.0
        static let hPadding: CGFloat = 6.0
        static let spacing: CGFloat = 8.0
        static let bottomInset: CGFloat = 16.0
    }

    private let logoImageView: UIImageView = .build {
        $0.contentMode = .scaleAspectFit
        $0.adjustsImageSizeForAccessibilityContentSizeCategory = true
    }
    private let containerView: UIView = .build()
    private let brandLabel: UILabel = .build {
        $0.font = FXFontStyles.Regular.caption2.scaledFont()
        $0.numberOfLines = 1
        $0.adjustsFontForContentSizeCategory = true
        $0.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        $0.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup() {
        contentView.addSubview(containerView)
        containerView.addSubviews(logoImageView, brandLabel)
        
        logoImageView.setContentCompressionResistancePriority(.required, for: .vertical)
        logoImageView.setContentHuggingPriority(.required, for: .vertical)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -UX.bottomInset),

            logoImageView.widthAnchor.constraint(equalToConstant: UX.logoSize),
            logoImageView.heightAnchor.constraint(equalToConstant: UX.logoSize),
            logoImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: UX.hPadding),
            logoImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

            brandLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: UX.hPadding),
            brandLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -UX.hPadding),
            brandLabel.leadingAnchor.constraint(equalTo: logoImageView.trailingAnchor, constant: UX.spacing),
            brandLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -UX.hPadding),
        ])
        
        containerView.layoutIfNeeded()
        containerView.layer.cornerRadius = containerView.bounds.height / 2
    }

    func configure(text: String, logo: UIImage?) {
        brandLabel.text = text
        logoImageView.image = logo
        setNeedsLayout()
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        containerView.backgroundColor = theme.colors.actionSecondaryDisabled
        brandLabel.textColor = theme.colors.textSecondary
        backgroundColor = .clear
    }
}

class SummaryTextCell: UITableViewCell, ReusableCell, ThemeApplicable {
    private let summaryView: UITextView = .build {
        $0.isScrollEnabled = false
        $0.font = FXFontStyles.Regular.headline.scaledFont()
        $0.showsVerticalScrollIndicator = false
        $0.adjustsFontForContentSizeCategory = true
        $0.isEditable = false
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        contentView.addSubview(summaryView)
        summaryView.pinToSuperview()
    }

    func configure(text: NSAttributedString?) {
        summaryView.attributedText = text
    }
    
    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        summaryView.backgroundColor = .clear
        backgroundColor = .clear
    }
}

