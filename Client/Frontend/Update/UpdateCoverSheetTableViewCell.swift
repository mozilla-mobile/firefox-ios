/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

struct UpdateCoverSheetTableViewCellUX {
    struct ImageView {
        static let paddingTop: CGFloat = 2
        static let paddingLeft: CGFloat = 18
        static let height: CGFloat = 30
    }

    struct DescriptionLabel {
        static let paddingTop: CGFloat = 2
        static let paddingTrailing: CGFloat = -18
        static let bottom: CGFloat = -10
        static let leading: CGFloat = 10
    }
}

class UpdateCoverSheetTableViewCell: UITableViewCell {
    // Tableview cell items
    var updateCoverSheetCellImageView: UIImageView = .build { imgView in
        imgView.image = #imageLiteral(resourceName: "darkModeUpdate")
        imgView.contentMode = .scaleAspectFit
        imgView.clipsToBounds = true
    }
    var updateCoverSheetCellDescriptionLabel: UILabel = .build { label in
        label.text = .CoverSheetV22DarkModeTitle
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        label.textAlignment = .left
        label.numberOfLines = 0
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initialViewSetup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initialViewSetup() {
        self.selectionStyle = .none
        contentView.addSubviews(updateCoverSheetCellImageView, updateCoverSheetCellDescriptionLabel)
        NSLayoutConstraint.activate([
            updateCoverSheetCellImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: UpdateCoverSheetTableViewCellUX.ImageView.paddingLeft),
            updateCoverSheetCellImageView.heightAnchor.constraint(equalToConstant: UpdateCoverSheetTableViewCellUX.ImageView.height),
            updateCoverSheetCellImageView.widthAnchor.constraint(equalToConstant: UpdateCoverSheetTableViewCellUX.ImageView.height),
            updateCoverSheetCellImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UpdateCoverSheetTableViewCellUX.ImageView.paddingTop),
            updateCoverSheetCellDescriptionLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UpdateCoverSheetTableViewCellUX.DescriptionLabel.paddingTop),
            updateCoverSheetCellDescriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: UpdateCoverSheetTableViewCellUX.DescriptionLabel.paddingTrailing),
            updateCoverSheetCellDescriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: UpdateCoverSheetTableViewCellUX.DescriptionLabel.bottom),
            updateCoverSheetCellDescriptionLabel.leadingAnchor.constraint(equalTo: updateCoverSheetCellImageView.trailingAnchor, constant: UpdateCoverSheetTableViewCellUX.DescriptionLabel.leading)
        ])
        fxThemeSupport()
    }

    func fxThemeSupport() {
        if UpdateViewController.theme == .dark {
            self.updateCoverSheetCellImageView.setImageColor(color: .white)
            self.updateCoverSheetCellDescriptionLabel.textColor = .white
            self.contentView.backgroundColor = .black
        } else {
            self.updateCoverSheetCellImageView.setImageColor(color: .black)
            self.updateCoverSheetCellDescriptionLabel.textColor = .black
            self.contentView.backgroundColor = .white
        }
    }
}
