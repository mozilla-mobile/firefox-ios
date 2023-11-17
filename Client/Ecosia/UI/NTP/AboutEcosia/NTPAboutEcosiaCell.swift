// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

final class NTPAboutEcosiaCell: UICollectionViewCell, ReusableCell {
    struct UX {
        static let height: CGFloat = 64
    }
    private var section: AboutEcosiaSection?
    private weak var viewModel: NTPAboutEcosiaCellViewModel?
    private var isLastSection: Bool {
        section == viewModel?.sections.last
    }
    private lazy var outlineView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        return view
    }()
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.contentMode = .center
        return imageView
    }()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()
    private lazy var indicatorImageView: UIImageView = {
        let imageView = UIImageView(image: .init(named: "chevronDown"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.contentMode = .center
        return imageView
    }()
    private lazy var disclosureView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 10
        return view
    }()
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .callout)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.init(rawValue: 0), for: .horizontal)
        return label
    }()
    private lazy var learnMoreButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.borderWidth = 1
        button.backgroundColor = .clear
        button.layer.cornerRadius = 20
        button.addTarget(self, action: #selector(learnMoreAction), for: .touchUpInside)
        button.accessibilityLabel = learnMoreLabel.text
        return button
    }()
    private lazy var learnMoreLabel: UILabel = {
        let label = UILabel()
        label.isUserInteractionEnabled = false
        label.font = .preferredFont(forTextStyle: .callout)
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = .localized(.learnMore)
        label.isAccessibilityElement = false
        return label
    }()
    private lazy var dividerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        return view
    }()
    
    var expandedHeight: CGFloat {
        disclosureView.frame.maxY + (isLastSection ? 16 : 0)
    }
    
    // MARK: - Themeable Properties
    
    var themeManager: ThemeManager { AppContainer.shared.resolve() }
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        applyTheme()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
        applyTheme()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        dividerView.isHidden = isLastSection || frame.height > UX.height
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let isExpanded = viewModel?.expandedIndex == layoutAttributes.indexPath
        rotateIndicator(isExpanded: isExpanded)
        updateAccessibility(isExpanded: isExpanded)
        let height = isExpanded ? expandedHeight : UX.height
        layoutAttributes.frame.size = contentView
            .systemLayoutSizeFitting(CGSize(width: layoutAttributes.frame.width,
                                            height: height),
                                     withHorizontalFittingPriority: .required,
                                     verticalFittingPriority: .fittingSizeLevel)
        return layoutAttributes
    }
    
    private func setup() {
        contentView.addSubview(outlineView)
        outlineView.addSubview(imageView)
        outlineView.addSubview(titleLabel)
        outlineView.addSubview(indicatorImageView)
        outlineView.addSubview(dividerView)
        outlineView.addSubview(disclosureView)
        disclosureView.addSubview(subtitleLabel)
        disclosureView.addSubview(learnMoreButton)
        learnMoreButton.addSubview(learnMoreLabel)
        
        NSLayoutConstraint.activate([
            outlineView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            outlineView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            outlineView.topAnchor.constraint(equalTo: contentView.topAnchor),
            outlineView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            imageView.centerXAnchor.constraint(equalTo: outlineView.leftAnchor, constant: 38),
            imageView.centerYAnchor.constraint(equalTo: outlineView.topAnchor, constant: UX.height / 2),
            
            titleLabel.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: outlineView.leadingAnchor, constant: 72),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: indicatorImageView.leadingAnchor, constant: -5),
            
            indicatorImageView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            indicatorImageView.trailingAnchor.constraint(equalTo: outlineView.trailingAnchor, constant: -16),
            
            disclosureView.topAnchor.constraint(equalTo: outlineView.topAnchor, constant: UX.height),
            disclosureView.leadingAnchor.constraint(equalTo: outlineView.leadingAnchor, constant: 16),
            disclosureView.trailingAnchor.constraint(equalTo: outlineView.trailingAnchor, constant: -16),
            disclosureView.bottomAnchor.constraint(equalTo: learnMoreButton.bottomAnchor, constant: 14),
            
            subtitleLabel.topAnchor.constraint(equalTo: disclosureView.topAnchor, constant: 12),
            subtitleLabel.leadingAnchor.constraint(equalTo: disclosureView.leadingAnchor, constant: 12),
            subtitleLabel.widthAnchor.constraint(lessThanOrEqualToConstant: frame.width - 56),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: disclosureView.trailingAnchor, constant: -12),
            subtitleLabel.widthAnchor.constraint(equalToConstant: frame.width - 56).priority(.defaultLow),
            
            learnMoreButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 10),
            learnMoreButton.leadingAnchor.constraint(equalTo: subtitleLabel.leadingAnchor),
            learnMoreButton.heightAnchor.constraint(equalToConstant: 40),
            learnMoreButton.trailingAnchor.constraint(equalTo: learnMoreLabel.trailingAnchor, constant: 16),
            
            learnMoreLabel.leadingAnchor.constraint(equalTo: learnMoreButton.leadingAnchor, constant: 16),
            learnMoreLabel.centerYAnchor.constraint(equalTo: learnMoreButton.centerYAnchor),
            
            dividerView.leadingAnchor.constraint(equalTo: outlineView.leadingAnchor, constant: 16),
            dividerView.trailingAnchor.constraint(equalTo: outlineView.trailingAnchor, constant: -16),
            dividerView.bottomAnchor.constraint(equalTo: outlineView.bottomAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: 1)
        ])
        listenForThemeChange(contentView)
    }
    
    func rotateIndicator(isExpanded: Bool) {
        indicatorImageView.transform = isExpanded ? .init(rotationAngle: .pi) : .identity
    }
    
    func configure(section: AboutEcosiaSection,
                   viewModel: NTPAboutEcosiaCellViewModel) {
        self.section = section
        self.viewModel = viewModel
        
        titleLabel.text = section.title
        imageView.image = UIImage(named: section.image)
        subtitleLabel.text = section.subtitle
        dividerView.isHidden = isLastSection
        outlineView.setMaskedCornersUsingPosition(
            row: viewModel.sections.firstIndex(of: section) ?? 0,
            totalCount: viewModel.sections.count
        )
    }
    
    func updateAccessibility(isExpanded: Bool) {
        titleLabel.accessibilityTraits = .button
        titleLabel.accessibilityHint = isExpanded ? .localized(.aboutEcosiaCollapseAccessibility) : .localized(.aboutEcosiaExpandAccessibility)
        subtitleLabel.isAccessibilityElement = isExpanded
        learnMoreButton.isAccessibilityElement = isExpanded
    }
    
    @objc private func highlighted() {
        learnMoreLabel.alpha = 0.2
    }
    
    @objc private func unhighlighted() {
        learnMoreLabel.alpha = 1
    }
    
    @objc private func learnMoreAction() {
        guard let section = section else { return }
        viewModel?.delegate?.openLink(url: section.url)
        Analytics.shared.navigation(.open, label: section.label)
    }
}

extension NTPAboutEcosiaCell: Themeable {
    
    func applyTheme() {
        outlineView.backgroundColor = .legacyTheme.ecosia.ntpCellBackground
        titleLabel.textColor = .legacyTheme.ecosia.primaryText
        indicatorImageView.tintColor = .legacyTheme.ecosia.secondaryText
        dividerView.backgroundColor = .legacyTheme.ecosia.border
        disclosureView.backgroundColor = .legacyTheme.ecosia.quarternaryBackground
        subtitleLabel.textColor = .legacyTheme.ecosia.primaryTextInverted
        learnMoreButton.layer.borderColor = UIColor.legacyTheme.ecosia.primaryTextInverted.cgColor
        learnMoreLabel.textColor = .legacyTheme.ecosia.primaryTextInverted
    }
}
