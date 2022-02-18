// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation


// A PhotonActionSheet cell
class PhotonActionSheetContainerCell: UITableViewCell {

    weak var delegate: PhotonActionSheetViewDelegate?
    private lazy var containerStackView: UIStackView = .build { stackView in
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

        selectionStyle = .none
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear

        contentView.addSubview(containerStackView)

        setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Table view
    
    func configure(actions: PhotonRowItems, viewModel: PhotonActionSheetViewModel) {
        for action in actions.items {
            action.tintColor = viewModel.tintColor
            configure(with: action)
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

    func configure(with action: SingleSheetItem) {
        let childView = PhotonActionSheetView()
        childView.configure(with: action)
        childView.addVerticalBorder(shouldAdd: !containerStackView.arrangedSubviews.isEmpty)
        childView.delegate = self
        containerStackView.addArrangedSubview(childView)
    }

    func hideBottomBorder(isHidden: Bool) {
        containerStackView.arrangedSubviews
          .compactMap { $0 as? PhotonActionSheetView }
          .forEach { $0.bottomBorder.isHidden = isHidden }
    }
}

// MARK: - PhotonActionSheetViewDelegate
extension PhotonActionSheetContainerCell: PhotonActionSheetViewDelegate {
    func didClick(action: SingleSheetItem?) {
        delegate?.didClick(action: action)
    }
}
