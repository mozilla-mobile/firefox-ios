/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

protocol SearchbarCellDelegate: AnyObject {
    func searchbarCellPressed(_ cell: SearchbarCell)
}

final class SearchbarCell: UICollectionViewCell, NotificationThemeable {
    private weak var search: UIButton!
    private weak var image: UIImageView!
    weak var widthConstraint: NSLayoutConstraint!
    weak var delegate: SearchbarCellDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        let search = SearchButton(type: .custom)
        search.translatesAutoresizingMaskIntoConstraints = false
        search.layer.cornerRadius = 20
        search.titleEdgeInsets.left = 44
        search.titleEdgeInsets.right = 12
        search.setTitle(.localized(.searchAndPlant), for: .normal)
        search.titleLabel?.lineBreakMode = .byTruncatingTail
        search.titleLabel?.font = .preferredFont(forTextStyle: .body)
        search.titleLabel?.adjustsFontForContentSizeCategory = true
        search.contentHorizontalAlignment = .left
        search.accessibilityTraits = .searchField
        self.search = search

        search.addTarget(self, action: #selector(tapped), for: .touchUpInside)

        contentView.addSubview(search)
        search.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        search.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true
        search.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0).isActive = true
        search.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0).isActive = true

        let height = search.heightAnchor.constraint(equalToConstant: 42)
        height.priority = .defaultHigh
        height.isActive = true

        let widthConstraint = search.widthAnchor.constraint(equalToConstant: 100)
        widthConstraint.priority = .defaultHigh
        widthConstraint.isActive = true
        self.widthConstraint = widthConstraint

        let image = UIImageView(image: .init(named: "quickSearch"))
        image.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(image)
        self.image = image

        image.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12).isActive = true
        image.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        image.heightAnchor.constraint(equalToConstant: 24).isActive = true
        image.widthAnchor.constraint(equalToConstant: 24).isActive = true
        image.contentMode = .scaleAspectFit

        applyTheme()
    }

    func applyTheme() {
        search.backgroundColor = UIColor.theme.textField.backgroundInCell
        search.setTitleColor(UIColor.theme.ecosia.secondaryText, for: .normal)
        image.tintColor = UIColor.theme.ecosia.textfieldIconTint

        search.layer.borderColor = UIColor.theme.ecosia.border.cgColor
        search.layer.borderWidth = 1

        if LegacyThemeManager.instance.current.isDark {
            search.layer.shadowOpacity = 0
        } else {
            search.layer.shadowOpacity = 1
            search.layer.shadowColor = UIColor(red: 0.059, green: 0.059, blue: 0.059, alpha: 0.18).cgColor
            search.layer.shadowOpacity = 1
            search.layer.shadowRadius = 2
            search.layer.shadowOffset = CGSize(width: 0, height: 1)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }

    @objc func tapped() {
        delegate?.searchbarCellPressed(self)
    }
}

class SearchButton: UIButton {
    override var isSelected: Bool {
        get { return super.isSelected }
        set { super.isSelected = newValue }
    }
}
