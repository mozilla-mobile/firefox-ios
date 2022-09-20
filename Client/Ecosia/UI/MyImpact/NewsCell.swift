/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Core
import UIKit

final class NewsCell: UICollectionViewCell, NotificationThemeable {
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
    private weak var date: UILabel!
    private weak var border: UIView!
    private weak var placeholder: UIImageView!

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
        
        let date = UILabel()
        date.translatesAutoresizingMaskIntoConstraints = false
        date.font = .preferredFont(forTextStyle: .footnote)
        date.adjustsFontForContentSizeCategory = true
        date.numberOfLines = 1
        date.textAlignment = .left
        date.setContentCompressionResistancePriority(.required, for: .vertical)
        date.setContentHuggingPriority(.defaultHigh, for: .vertical)
        background.addSubview(date)
        self.date = date
        
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
        title.bottomAnchor.constraint(lessThanOrEqualTo: date.topAnchor, constant: -12).isActive = true

        let squeeze = title.bottomAnchor.constraint(equalTo: date.topAnchor, constant: -12)
        squeeze.priority = .init(700)
        squeeze.isActive = true

        date.leftAnchor.constraint(equalTo: title.leftAnchor).isActive = true
        date.bottomAnchor.constraint(equalTo: background.bottomAnchor, constant: -16).isActive = true
        date.rightAnchor.constraint(equalTo: title.rightAnchor).isActive = true

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
    
    func configure(_ item: NewsModel, images: Images, positions: Positions) {
        imageUrl = item.imageUrl
        image.image = nil
        title.text = item.text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        date.text = RelativeDateTimeFormatter().localizedString(for: item.publishDate, relativeTo: .init())
        
        images.load(self, url: item.imageUrl) { [weak self] in
            guard self?.imageUrl == $0.url else { return }
            self?.updateImage($0.data)
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
    }

    private func updateImage(_ data: Data) {
        image.image = .init(data: data)
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: { [weak self] in
            self?.image.alpha = 1
        })
    }
    
    private func hover() {
        background.backgroundColor = isSelected || isHighlighted ? .theme.ecosia.secondarySelectedBackground : .theme.ecosia.ntpCellBackground
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }

    func applyTheme() {
        background.backgroundColor = UIColor.theme.ecosia.ntpCellBackground
        placeholder.tintColor = .theme.ecosia.decorativeIcon
        placeholder.backgroundColor = .theme.ecosia.newsPlaceholder
        border?.backgroundColor = UIColor.theme.ecosia.border
        title?.textColor = UIColor.theme.ecosia.primaryText
        date?.textColor = UIColor.theme.ecosia.secondaryText
    }
}
