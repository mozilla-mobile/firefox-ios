// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation


// A PhotonActionSheet cell
class PhotonActionSheetContainerCell: UITableViewCell {

    private lazy var containerStackView: UIStackView = .build { stackView in
        stackView.spacing = PhotonActionSheetViewUX.Padding
        stackView.alignment = .fill
        stackView.distribution = .fillProportionally

        // TODO: Laurie - Change alignment when needed
        stackView.axis = .horizontal
    }

    // MARK: - init

    override func prepareForReuse() {
        super.prepareForReuse()
        containerStackView.removeAllArrangedViews()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear

        contentView.addSubview(containerStackView)

        setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
        ])
    }

    func configure(with actions: [PhotonActionSheetItem]) {
        for action in actions {
            let childView = PhotonActionSheetView()
            childView.configure(with: action)
            containerStackView.addArrangedSubview(childView)
        }
    }

    func hideBottomBorder(isHidden: Bool) {
        containerStackView.arrangedSubviews
          .compactMap { $0 as? PhotonActionSheetView }
          .forEach { $0.bottomBorder.isHidden = isHidden }
    }

    // TODO: Laurie - Add border between child cells
    private func addVerticalBorder(action: PhotonActionSheetItem) {
//        bottomBorder.backgroundColor = UIColor.theme.tableView.separator
//        contentView.addSubview(bottomBorder)
//
//        var constraints = [NSLayoutConstraint]()
//        // Determine if border should be at top or bottom when flipping
//        let top = bottomBorder.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 1)
//        let bottom = bottomBorder.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
//        let anchor = action.isFlipped ? top : bottom
//
//        let borderConstraints = [
//            anchor,
//            bottomBorder.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
//            bottomBorder.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
//            bottomBorder.heightAnchor.constraint(equalToConstant: 1)
//        ]
//        constraints.append(contentsOf: borderConstraints)
//
//        NSLayoutConstraint.activate(constraints)
    }
}
