/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Core
import UIKit
import Common

final class NTPNewsCell: UICollectionViewCell, Themeable, ReusableCell {
    private var imageUrl: URL?
    private lazy var background: UIView = {
        let background = UIView()
        background.translatesAutoresizingMaskIntoConstraints = false
        background.layer.cornerRadius = 10
        return background
    }()
    private lazy var border: UIView = {
        let border = UIView()
        border.translatesAutoresizingMaskIntoConstraints = false
        border.isUserInteractionEnabled = false
        return border
    }()
    private lazy var placeholder: UIImageView = {
        let placeholder = UIImageView()
        placeholder.translatesAutoresizingMaskIntoConstraints = false
        placeholder.contentMode = .scaleAspectFill
        placeholder.clipsToBounds = true
        placeholder.image = UIImage(named: "image_placeholder")!
        placeholder.layer.cornerRadius = 10
        return placeholder
    }()
    private lazy var image: UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.alpha = 0
        image.layer.cornerRadius = 10
        return image
    }()
    private lazy var title: UILabel = {
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.numberOfLines = 4
        title.lineBreakMode = .byTruncatingTail
        title.font = .preferredFont(forTextStyle: .body)
        title.setContentHuggingPriority(.defaultHigh, for: .vertical)
        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        title.adjustsFontForContentSizeCategory = true
        title.adjustsFontSizeToFitWidth = true
        return title
    }()
    private lazy var bottomLine: UIStackView = {
        let bottomLine = UIStackView()
        bottomLine.translatesAutoresizingMaskIntoConstraints = false
        bottomLine.distribution = .fill
        bottomLine.axis = .horizontal
        bottomLine.spacing = 4
        bottomLine.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return bottomLine
    }()
    private lazy var bottomIcon: UIImageView = {
        let bottomIcon = UIImageView()
        bottomIcon.translatesAutoresizingMaskIntoConstraints = false
        bottomIcon.contentMode = .scaleAspectFill
        bottomIcon.clipsToBounds = true
        return bottomIcon
    }()
    private lazy var highlightLabel: UILabel = {
        let highlightLabel = UILabel()
        highlightLabel.translatesAutoresizingMaskIntoConstraints = false
        highlightLabel.font = .preferredFont(forTextStyle: .footnote).bold()
        highlightLabel.adjustsFontForContentSizeCategory = true
        highlightLabel.numberOfLines = 1
        highlightLabel.textAlignment = .left
        highlightLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        highlightLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        highlightLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return highlightLabel
    }()
    private lazy var bottomLabel: UILabel = {
        let bottomLabel = UILabel()
        bottomLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomLabel.font = .preferredFont(forTextStyle: .footnote)
        bottomLabel.adjustsFontForContentSizeCategory = true
        bottomLabel.numberOfLines = 1
        bottomLabel.textAlignment = .left
        bottomLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        bottomLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        bottomLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return bottomLabel
    }()
    var defaultBackgroundColor: (() -> UIColor) = { .legacyTheme.ecosia.ntpCellBackground }
    
    // MARK: - Themeable Properties
    
    var themeManager: ThemeManager { AppContainer.shared.resolve() }
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Init

    required init?(coder: NSCoder) { nil }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        contentView.addSubview(background)
        background.addSubview(border)
        background.addSubview(placeholder)
        background.addSubview(image)
        background.addSubview(title)
        background.addSubview(bottomLine)
        bottomLine.addArrangedSubview(bottomIcon)
        bottomLine.addArrangedSubview(highlightLabel)
        bottomLine.addArrangedSubview(bottomLabel)

        container.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        container.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        container.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true

        background.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor).isActive = true
        background.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor).isActive = true
        background.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        background.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true

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
        listenForThemeChange(contentView)
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
    
    func configure(_ model: NewsModel, images: Images, row: Int, totalCount: Int) {
        let titleString = model.text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        title.text = titleString
        let publishDateString = RelativeDateTimeFormatter().localizedString(for: model.publishDate, relativeTo: .init())
        bottomLabel.text = publishDateString
        bottomIcon.isHidden = true
        highlightLabel.isHidden = true

        imageUrl = model.imageUrl
        image.image = nil
        images.load(self, url: model.imageUrl) { [weak self] in
            guard self?.imageUrl == $0.url else { return }
            self?.updateImage($0.data)
        }

        border.isHidden = row == totalCount - 1

        background.setMaskedCornersUsingPosition(row: row, totalCount: totalCount)
        applyTheme()
            
        isAccessibilityElement = true
        accessibilityLabel = "\(titleString); \(publishDateString)"
        accessibilityTraits = .link
        shouldGroupAccessibilityChildren = true
    }

    private func updateImage(_ data: Data) {
        image.image = .init(data: data)
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: { [weak self] in
            self?.image.alpha = 1
        })
    }
    
    private func hover() {
        background.backgroundColor = isSelected || isHighlighted ? .legacyTheme.ecosia.secondarySelectedBackground : defaultBackgroundColor()
    }

    func applyTheme() {
        background.backgroundColor = defaultBackgroundColor()
        placeholder.tintColor = .legacyTheme.ecosia.decorativeIcon
        placeholder.backgroundColor = .legacyTheme.ecosia.newsPlaceholder
        border.backgroundColor = .legacyTheme.ecosia.border
        title.textColor = .legacyTheme.ecosia.primaryText
        bottomLabel.textColor = .legacyTheme.ecosia.secondaryText
        highlightLabel.textColor = .legacyTheme.ecosia.secondaryText
    }
}
