/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Core
import UIKit

final class NewsCell: UICollectionViewCell, Themeable {
    private var imageUrl: URL?
    private weak var image: UIImageView!
    private weak var title: UILabel!
    private weak var date: UILabel!
    private weak var border: UIView!
    
    required init?(coder: NSCoder) { nil }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        let border = UIView()
        border.translatesAutoresizingMaskIntoConstraints = false
        border.isUserInteractionEnabled = false
        contentView.addSubview(border)
        self.border = border
        
        let placeholder = UIImageView()
        placeholder.translatesAutoresizingMaskIntoConstraints = false
        placeholder.contentMode = .scaleAspectFill
        placeholder.clipsToBounds = true
        placeholder.image = UIImage(named: "image_placeholder")!
        placeholder.layer.cornerRadius = 5
        contentView.addSubview(placeholder)
        
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.alpha = 0
        image.layer.cornerRadius = 5
        contentView.addSubview(image)
        self.image = image
        
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.numberOfLines = 4
        title.lineBreakMode = .byTruncatingTail
        title.font = .preferredFont(forTextStyle: .footnote)
        contentView.addSubview(title)
        self.title = title
        
        let date = UILabel()
        date.translatesAutoresizingMaskIntoConstraints = false
        date.font = .preferredFont(forTextStyle: .caption1)
        contentView.addSubview(date)
        self.date = date
        
        placeholder.topAnchor.constraint(equalTo: image.topAnchor).isActive = true
        placeholder.bottomAnchor.constraint(equalTo: image.bottomAnchor).isActive = true
        placeholder.leftAnchor.constraint(equalTo: image.leftAnchor).isActive = true
        placeholder.rightAnchor.constraint(equalTo: image.rightAnchor).isActive = true
        
        image.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        image.widthAnchor.constraint(equalToConstant: 96).isActive = true
        image.heightAnchor.constraint(equalTo: image.widthAnchor).isActive = true
        
        title.leftAnchor.constraint(equalTo: image.rightAnchor, constant: 15).isActive = true
        title.topAnchor.constraint(equalTo: image.topAnchor, constant: 3).isActive = true
        
        date.bottomAnchor.constraint(equalTo: border.topAnchor, constant: -16).isActive = true
        
        border.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        border.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        border.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        image.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 0).isActive = true
        title.rightAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.rightAnchor, constant: -14).isActive = true
        date.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -14).isActive = true
        border.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 0).isActive = true

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
    
    func configure(_ item: NotificationModel, images: Images) {
        imageUrl = item.imageUrl
        image.image = nil
        title.text = item.text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        if #available(iOS 13.0, *) {
            date.text = RelativeDateTimeFormatter().localizedString(for: item.publishDate, relativeTo: .init())
        } else {
            let count = Calendar.current.dateComponents([.day], from: item.publishDate, to: .init()).day!
            date.text = count == 0 ? .localized(.today) : .init(format: .localized(.daysAgo), "\(count)")
        }
        
        images.load(self, url: item.imageUrl) { [weak self] in
            guard self?.imageUrl == $0.url else { return }
            self?.updateImage($0.data)
        }
    }
    
    private func updateImage(_ data: Data) {
        image.image = UIImage(data: data)
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: { [weak self] in
            self?.image.alpha = 1
        })
    }
    
    private func hover() {
        backgroundColor = isSelected || isHighlighted ? UIColor.theme.ecosia.hoverBackgroundColor : UIColor.theme.ecosia.primaryBackground
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()

    }

    func applyTheme() {
        backgroundColor = UIColor.theme.ecosia.primaryBackground
        border?.backgroundColor = UIColor.theme.ecosia.underlineGrey
        title?.textColor = UIColor.theme.ecosia.primaryText
        date?.textColor = UIColor.theme.ecosia.secondaryText
    }
}

final class NewsButtonCell: UICollectionReusableView {
    lazy var moreButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(UIColor.theme.ecosia.primaryButton, for: .normal)
        button.setTitleColor(UIColor.Photon.Grey50, for: .highlighted)
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.DeviceFontMedium
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(moreButton)

        moreButton.translatesAutoresizingMaskIntoConstraints = false
        moreButton.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        moreButton.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        moreButton.topAnchor.constraint(equalTo: topAnchor).isActive = true
        moreButton.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        moreButton.setTitleColor(UIColor.theme.ecosia.primaryButton, for: .normal)
        moreButton.setTitleColor(UIColor.Photon.Grey50, for: .highlighted)
    }
}
