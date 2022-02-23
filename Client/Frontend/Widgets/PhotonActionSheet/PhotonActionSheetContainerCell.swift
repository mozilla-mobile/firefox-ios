// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol PhotonActionSheetContainerCellDelegate: AnyObject {
    func didClick(item: SingleActionViewModel?)
    func layoutChanged(item: SingleActionViewModel)
}

// A PhotonActionSheet cell
class PhotonActionSheetContainerCell: UITableViewCell {

    weak var delegate: PhotonActionSheetContainerCellDelegate?
    private lazy var containerStackView: UIStackView = .build { stackView in
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.axis = .horizontal
    }

    // MARK: - init

    override func prepareForReuse() {
        super.prepareForReuse()
        containerStackView.removeAllArrangedViews()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(containerStackView)
        setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Table view
    
    func configure(actions: PhotonRowActions, viewModel: PhotonActionSheetViewModel) {
        for item in actions.items {
            item.tintColor = viewModel.tintColor
            item.multipleItemsSetup.isMultiItems = actions.items.count > 1
            configure(with: item)
        }
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

    func configure(with item: SingleActionViewModel) {
        let childView = PhotonActionSheetView()
        childView.configure(with: item)
        childView.addVerticalBorder(ifShouldBeShown: !containerStackView.arrangedSubviews.isEmpty)
        childView.delegate = self
        containerStackView.addArrangedSubview(childView)
        containerStackView.axis = item.multipleItemsSetup.axis
    }

    func hideBottomBorder(isHidden: Bool) {
        containerStackView.arrangedSubviews
          .compactMap { $0 as? PhotonActionSheetView }
          .forEach { $0.bottomBorder.isHidden = isHidden }
    }
}

// MARK: - PhotonActionSheetViewDelegate
extension PhotonActionSheetContainerCell: PhotonActionSheetViewDelegate {
    func didClick(item: SingleActionViewModel?) {
        delegate?.didClick(item: item)
    }

    func layoutChanged(item: SingleActionViewModel) {
        delegate?.layoutChanged(item: item)
    }
}
