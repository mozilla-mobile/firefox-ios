/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

protocol EcosiaInfoCellModel {
    var title: String { get }
    var subTitle: String? { get }
    var description: String? { get }
    var image: String { get }
}

extension EcosiaHome.Section.Info: EcosiaInfoCellModel {}

final class EcosiaInfoCell: UICollectionViewCell, Themeable {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    var title: UILabel!
    var subtitle: UILabel!
    var image: UIImageView!
    var desc: UILabel!
    var outline: UIView!

    private func setup() {
        outline = UIView()
        contentView.addSubview(outline)
        outline.layer.cornerRadius = 8
        outline.translatesAutoresizingMaskIntoConstraints = false

        title = UILabel()
        contentView.addSubview(title)
        title.font = DynamicFontHelper.defaultHelper.DefaultStandardFont
        title.numberOfLines = 1
        title.translatesAutoresizingMaskIntoConstraints = false
        title.setContentHuggingPriority(.required, for: .vertical)

        image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.contentMode = .scaleAspectFit
        contentView.addSubview(image)

        let stack = UIStackView()
        stack.alignment = .top
        stack.distribution = .fill
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        subtitle = UILabel()
        subtitle.font = DynamicFontHelper.defaultHelper.DeviceFontMediumBold
        stack.addArrangedSubview(subtitle)

        desc = UILabel()
        desc.numberOfLines = 0
        desc.font = .preferredFont(forTextStyle: .footnote)
        desc.adjustsFontSizeToFitWidth = true
        desc.minimumScaleFactor = 0.8
        stack.addArrangedSubview(desc)


        outline.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        outline.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        outline.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        outline.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true

        title.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16).isActive = true
        title.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).isActive = true
        title.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16).isActive = true

        image.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16).isActive = true
        image.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 16).isActive = true
        image.bottomAnchor.constraint(greaterThanOrEqualTo: contentView.bottomAnchor, constant: -16).isActive = true
        image.widthAnchor.constraint(equalToConstant: 44).isActive = true

        let bottomImage = image.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        bottomImage.priority = .defaultHigh
        bottomImage.isActive = true

        stack.leadingAnchor.constraint(equalTo: image.trailingAnchor, constant: 16).isActive = true
        stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).isActive = true
        stack.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 16).isActive = true
        stack.bottomAnchor.constraint(greaterThanOrEqualTo: contentView.bottomAnchor, constant: -16).isActive = true
        let bottomStack = stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        bottomStack.priority = .defaultHigh
        bottomStack.isActive = true

        applyTheme()
    }

    func display(_ model: EcosiaInfoCellModel) {
        title.text = model.title
        subtitle.text = model.subTitle
        subtitle.isHidden = model.subTitle == nil
        image.image = UIImage(named: model.image)
        desc.text = model.description
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

    private func hover() {
        outline.backgroundColor = isSelected || isHighlighted ? UIColor.theme.ecosia.hoverBackgroundColor : UIColor.theme.ecosia.highlightedBackground
    }

    func applyTheme() {
        title.textColor = UIColor.theme.ecosia.primaryText
        subtitle.textColor = UIColor.theme.ecosia.primaryBrand
        desc.textColor = UIColor.theme.ecosia.primaryText
        outline.elevate()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
}
