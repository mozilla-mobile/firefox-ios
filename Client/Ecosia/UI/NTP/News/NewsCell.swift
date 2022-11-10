/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Core
import UIKit

final class NewsCell: UICollectionViewCell, NotificationThemeable, ReusableCell {
    struct Positions: OptionSet {
        static let top = Positions(rawValue: 1)
        static let bottom = Positions(rawValue: 1 << 1)
        let rawValue: Int8

        static func derive(row: Int, items: Int) -> Positions {
            var pos = Positions()
            if row == 0 { pos.insert(.top) }
            if row == items - 1 { pos.insert(.bottom) }
            return pos
        }
    }

    private var imageUrl: URL?
    private weak var background: UIView!
    private weak var image: UIImageView!
    private weak var title: UILabel!
    private weak var bottomLine: UIStackView!
    private weak var bottomIcon: UIImageView!
    private weak var highlightLabel: UILabel!
    private weak var bottomLabel: UILabel!
    private weak var border: UIView!
    private weak var placeholder: UIImageView!
    var defaultBackgroundColor: (() -> UIColor) = { .theme.ecosia.ntpCellBackground }

    required init?(coder: NSCoder) { nil }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)

        container.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        container.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        container.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true

        let background = UIView()
        background.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(background)
        self.background = background
        background.layer.cornerRadius = 10

        background.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor).isActive = true
        background.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor).isActive = true
        background.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        background.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true

        let border = UIView()
        border.translatesAutoresizingMaskIntoConstraints = false
        border.isUserInteractionEnabled = false
        background.addSubview(border)
        self.border = border
        
        let placeholder = UIImageView()
        placeholder.translatesAutoresizingMaskIntoConstraints = false
        placeholder.contentMode = .scaleAspectFill
        placeholder.clipsToBounds = true
        placeholder.image = UIImage(named: "image_placeholder")!
        placeholder.layer.cornerRadius = 5
        background.addSubview(placeholder)
        self.placeholder = placeholder

        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.alpha = 0
        image.layer.cornerRadius = 5
        background.addSubview(image)
        self.image = image
        
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.numberOfLines = 4
        title.lineBreakMode = .byTruncatingTail
        title.font = .preferredFont(forTextStyle: .body)
        title.setContentHuggingPriority(.defaultHigh, for: .vertical)
        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        title.adjustsFontForContentSizeCategory = true
        title.adjustsFontSizeToFitWidth = true
        background.addSubview(title)
        self.title = title

        let bottomLine = UIStackView()
        bottomLine.translatesAutoresizingMaskIntoConstraints = false
        bottomLine.distribution = .fill
        bottomLine.axis = .horizontal
        bottomLine.spacing = 4
        bottomLine.setContentHuggingPriority(.defaultLow, for: .horizontal)
        background.addSubview(bottomLine)
        self.bottomLine = bottomLine

        let bottomIcon = UIImageView()
        bottomIcon.translatesAutoresizingMaskIntoConstraints = false
        bottomIcon.contentMode = .scaleAspectFill
        bottomIcon.clipsToBounds = true
        bottomLine.addArrangedSubview(bottomIcon)
        self.bottomIcon = bottomIcon

        let highlightLabel = UILabel()
        highlightLabel.translatesAutoresizingMaskIntoConstraints = false
        highlightLabel.font = .preferredFont(forTextStyle: .footnote).bold()
        highlightLabel.adjustsFontForContentSizeCategory = true
        highlightLabel.numberOfLines = 1
        highlightLabel.textAlignment = .left
        highlightLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        highlightLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        highlightLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        bottomLine.addArrangedSubview(highlightLabel)
        self.highlightLabel = highlightLabel

        let bottomLabel = UILabel()
        bottomLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomLabel.font = .preferredFont(forTextStyle: .footnote)
        bottomLabel.adjustsFontForContentSizeCategory = true
        bottomLabel.numberOfLines = 1
        bottomLabel.textAlignment = .left
        bottomLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        bottomLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        bottomLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        bottomLine.addArrangedSubview(bottomLabel)
        self.bottomLabel = bottomLabel

        placeholder.topAnchor.constraint(equalTo: image.topAnchor).isActive = true
        placeholder.bottomAnchor.constraint(equalTo: image.bottomAnchor).isActive = true
        placeholder.leftAnchor.constraint(equalTo: image.leftAnchor).isActive = true
        placeholder.rightAnchor.constraint(equalTo: image.rightAnchor).isActive = true
        
        image.rightAnchor.constraint(equalTo: background.rightAnchor, constant: -16).isActive = true

        let imageHeight = image.widthAnchor.constraint(equalToConstant: 80)
        imageHeight.priority = .init(999)
        imageHeight.isActive = true

        image.heightAnchor.constraint(equalTo: image.widthAnchor).isActive = true
        image.topAnchor.constraint(equalTo: background.topAnchor, constant: 16).isActive = true
        image.bottomAnchor.constraint(lessThanOrEqualTo: background.bottomAnchor, constant: -16).isActive = true

        title.leftAnchor.constraint(equalTo: background.leftAnchor, constant: 16).isActive = true
        title.rightAnchor.constraint(lessThanOrEqualTo: image.leftAnchor, constant: -16).isActive = true
        title.topAnchor.constraint(equalTo: background.topAnchor, constant: 16).isActive = true
        title.bottomAnchor.constraint(lessThanOrEqualTo: bottomLine.topAnchor, constant: -12).isActive = true

        let squeeze = title.bottomAnchor.constraint(equalTo: bottomLine.topAnchor, constant: -12)
        squeeze.priority = .init(700)
        squeeze.isActive = true

        bottomLine.leftAnchor.constraint(equalTo: background.leftAnchor, constant: 16).isActive = true
        bottomLine.bottomAnchor.constraint(equalTo: background.bottomAnchor, constant: -16).isActive = true
        bottomLine.rightAnchor.constraint(equalTo: background.rightAnchor, constant: -16).isActive = true

        bottomIcon.heightAnchor.constraint(equalTo: bottomIcon.widthAnchor).isActive = true
        bottomIcon.widthAnchor.constraint(equalToConstant: 24).isActive = true

        border.leftAnchor.constraint(equalTo: background.leftAnchor, constant: 16).isActive = true
        border.rightAnchor.constraint(equalTo: background.rightAnchor, constant: -16).isActive = true
        border.bottomAnchor.constraint(equalTo: background.bottomAnchor).isActive = true
        border.heightAnchor.constraint(equalToConstant: 1).isActive = true

        applyTheme()
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
    
    func configure(_ item: ViewModel, images: Images, positions: Positions) {
        title.text = item.text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        if let model = item.model {
            bottomLabel.text = RelativeDateTimeFormatter().localizedString(for: model.publishDate, relativeTo: .init())
            bottomIcon.isHidden = true
            highlightLabel.isHidden = true

            imageUrl = model.imageUrl
            image.image = nil
            images.load(self, url: model.imageUrl) { [weak self] in
                guard self?.imageUrl == $0.url else { return }
                self?.updateImage($0.data)
            }
        } else if let promo = item.promo {
            imageUrl = nil
            updateImage(UIImage(named: promo.image)!.pngData()!)
            bottomLabel.text = promo.description
            bottomIcon.isHidden = false
            bottomIcon.image = UIImage(named: promo.icon)
            highlightLabel.isHidden = promo.highlight == nil
            highlightLabel.text = promo.highlight
        }

        border.isHidden = positions.contains(.bottom)

        // Masking only specific corners
        var masked: CACornerMask = []
        if positions.contains(.top) {
            masked.formUnion(.layerMinXMinYCorner)
            masked.formUnion(.layerMaxXMinYCorner)
        }

        if positions.contains(.bottom) {
            masked.formUnion(.layerMinXMaxYCorner)
            masked.formUnion(.layerMaxXMaxYCorner)
        }
        background.layer.maskedCorners = masked
        applyTheme()
    }

    private func updateImage(_ data: Data) {
        image.image = .init(data: data)
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: { [weak self] in
            self?.image.alpha = 1
        })
    }
    
    private func hover() {
        background.backgroundColor = isSelected || isHighlighted ? .theme.ecosia.secondarySelectedBackground : defaultBackgroundColor()
    }

    func applyTheme() {
        background.backgroundColor = defaultBackgroundColor()
        placeholder.tintColor = .theme.ecosia.decorativeIcon
        placeholder.backgroundColor = .theme.ecosia.newsPlaceholder
        border?.backgroundColor = .theme.ecosia.border
        title?.textColor = .theme.ecosia.primaryText
        bottomLabel?.textColor = .theme.ecosia.secondaryText
        highlightLabel?.textColor = .theme.ecosia.secondaryText
    }
}
