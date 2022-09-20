/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

final class EcosiaExploreCell: UICollectionViewCell, NotificationThemeable {
    private(set) weak var learnMore: UIButton!
    private weak var title: UILabel!
    private weak var subtitle: UILabel!
    private weak var image: UIImageView!
    private weak var indicator: UIImageView!
    private weak var outline: UIView!
    private weak var divider: UIView!
    private weak var disclosure: UIView!
    private weak var learnMoreLabel: UILabel!
    
    var model: EcosiaHome.Section.Explore? {
        didSet {
            guard let model = model, model != oldValue else { return }
            title.text = model.title
            image.image = UIImage(named: model.image)
            outline.layer.maskedCorners = model.maskedCorners
            subtitle.text = model.subtitle
            divider.isHidden = model == .faq
        }
    }
    
    var expandedHeight: CGFloat {
        disclosure.frame.maxY + (model == .faq ? 16 : 0)
    }
    
    override var isSelected: Bool {
        didSet {
            hover()
        }
    }

    override var isHighlighted: Bool {
        didSet {
            hover()
        }
    }
    
    required init?(coder: NSCoder) { super.init(coder: coder) }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let outline = UIView()
        outline.layer.cornerRadius = 10
        outline.translatesAutoresizingMaskIntoConstraints = false
        outline.clipsToBounds = true
        contentView.addSubview(outline)
        self.outline = outline

        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.translatesAutoresizingMaskIntoConstraints = false
        image.clipsToBounds = true
        image.contentMode = .center
        outline.addSubview(image)
        self.image = image
        
        let title = UILabel()
        title.font = .preferredFont(forTextStyle: .body)
        title.adjustsFontForContentSizeCategory = true
        title.numberOfLines = 0
        title.translatesAutoresizingMaskIntoConstraints = false
        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        outline.addSubview(title)
        self.title = title

        let indicator = UIImageView(image: .init(named: "chevronDown"))
        indicator.contentMode = .scaleAspectFit
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.clipsToBounds = true
        indicator.contentMode = .center
        outline.addSubview(indicator)
        self.indicator = indicator
        
        let disclosure = UIView()
        disclosure.translatesAutoresizingMaskIntoConstraints = false
        disclosure.layer.cornerRadius = 10
        outline.addSubview(disclosure)
        self.disclosure = disclosure
        
        let subtitle = UILabel()
        subtitle.font = .preferredFont(forTextStyle: .callout)
        subtitle.adjustsFontForContentSizeCategory = true
        subtitle.numberOfLines = 0
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.setContentCompressionResistancePriority(.init(rawValue: 0), for: .horizontal)
        disclosure.addSubview(subtitle)
        self.subtitle = subtitle
        
        let learnMore = UIButton()
        learnMore.translatesAutoresizingMaskIntoConstraints = false
        learnMore.backgroundColor = .white
        learnMore.layer.cornerRadius = 20
        learnMore.addTarget(self, action: #selector(highlighted), for: .touchDown)
        learnMore.addTarget(self, action: #selector(unhighlighted), for: .touchUpInside)
        learnMore.addTarget(self, action: #selector(unhighlighted), for: .touchCancel)
        disclosure.addSubview(learnMore)
        self.learnMore = learnMore
        
        let learnMoreLabel = UILabel()
        learnMoreLabel.isUserInteractionEnabled = false
        learnMoreLabel.font = .preferredFont(forTextStyle: .callout)
        learnMoreLabel.adjustsFontForContentSizeCategory = true
        learnMoreLabel.translatesAutoresizingMaskIntoConstraints = false
        learnMoreLabel.text = .localized(.learnMore)
        learnMoreLabel.textColor = .init(white: 0.1, alpha: 1)
        learnMore.addSubview(learnMoreLabel)
        self.learnMoreLabel = learnMoreLabel
        
        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.isUserInteractionEnabled = false
        outline.addSubview(divider)
        self.divider = divider
        
        outline.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        outline.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        outline.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        outline.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true

        image.centerXAnchor.constraint(equalTo: outline.leftAnchor, constant: 38).isActive = true
        image.centerYAnchor.constraint(equalTo: outline.topAnchor, constant: EcosiaHome.Section.explore.height / 2).isActive = true
        
        title.centerYAnchor.constraint(equalTo: image.centerYAnchor).isActive = true
        title.leadingAnchor.constraint(equalTo: outline.leadingAnchor, constant: 72).isActive = true
        title.trailingAnchor.constraint(lessThanOrEqualTo: indicator.leadingAnchor, constant: -5).isActive = true
        
        indicator.centerYAnchor.constraint(equalTo: image.centerYAnchor).isActive = true
        indicator.trailingAnchor.constraint(equalTo: outline.trailingAnchor, constant: -16).isActive = true
        
        disclosure.topAnchor.constraint(equalTo: outline.topAnchor, constant: EcosiaHome.Section.explore.height).isActive = true
        disclosure.leadingAnchor.constraint(equalTo: outline.leadingAnchor, constant: 16).isActive = true
        disclosure.trailingAnchor.constraint(equalTo: outline.trailingAnchor, constant: -16).isActive = true
        disclosure.bottomAnchor.constraint(equalTo: learnMore.bottomAnchor, constant: 14).isActive = true
        
        subtitle.topAnchor.constraint(equalTo: disclosure.topAnchor, constant: 12).isActive = true
        subtitle.leadingAnchor.constraint(equalTo: disclosure.leadingAnchor, constant: 12).isActive = true
        subtitle.widthAnchor.constraint(lessThanOrEqualToConstant: frame.width - 56).isActive = true
        subtitle.trailingAnchor.constraint(lessThanOrEqualTo: disclosure.trailingAnchor, constant: -12).isActive = true
        let subtitleWidth = subtitle.widthAnchor.constraint(equalToConstant: frame.width - 56)
        subtitleWidth.priority = .defaultLow
        subtitleWidth.isActive = true
        
        learnMore.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 10).isActive = true
        learnMore.leadingAnchor.constraint(equalTo: subtitle.leadingAnchor).isActive = true
        learnMore.heightAnchor.constraint(equalToConstant: 40).isActive = true
        learnMore.trailingAnchor.constraint(equalTo: learnMoreLabel.trailingAnchor, constant: 16).isActive = true
        
        learnMoreLabel.leadingAnchor.constraint(equalTo: learnMore.leadingAnchor, constant: 16).isActive = true
        learnMoreLabel.centerYAnchor.constraint(equalTo: learnMore.centerYAnchor).isActive = true
        
        divider.leadingAnchor.constraint(equalTo: outline.leadingAnchor, constant: 16).isActive = true
        divider.trailingAnchor.constraint(equalTo: outline.trailingAnchor, constant: -16).isActive = true
        divider.bottomAnchor.constraint(equalTo: outline.bottomAnchor).isActive = true
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true

        applyTheme()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        divider?.isHidden = model == .faq || frame.height > EcosiaHome.Section.explore.height
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }

    func applyTheme() {
        outline.backgroundColor = .theme.ecosia.ntpCellBackground
        title.textColor = .theme.ecosia.primaryText
        indicator.tintColor = .theme.ecosia.secondaryText
        divider.backgroundColor = .theme.ecosia.border
        disclosure.backgroundColor = .theme.ecosia.quarternaryBackground
        subtitle.textColor = .theme.ecosia.primaryTextInverted
    }
    
    private func hover() {
        outline.backgroundColor = isSelected || isHighlighted ? .theme.ecosia.secondarySelectedBackground : .theme.ecosia.ntpCellBackground
    }
    
    @objc private func highlighted() {
        learnMoreLabel.alpha = 0.2
    }
    
    @objc private func unhighlighted() {
        learnMoreLabel.alpha = 1
    }
}
