// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

protocol PhotonActionSheetContainerCellDelegate: AnyObject {
    func didClick(item: SingleActionViewModel?, animationCompletion: @escaping () -> Void)
}

// A PhotonActionSheet cell
class PhotonActionSheetContainerCell: UITableViewCell, ReusableCell, ThemeApplicable {
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

    func configure(actions: PhotonRowActions, viewModel: PhotonActionSheetViewModel, theme: Theme) {
        addViews(for: actions, theme: theme)
        applyTheme(theme: theme)
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

    private func addViews(for actions: PhotonRowActions, theme: Theme) {
        for item in actions.items {
            let childView = PhotonActionSheetView()
            childView.configure(with: item, theme: theme)
            childView.addVerticalBorder(ifShouldBeShown: !containerStackView.arrangedSubviews.isEmpty)
            let widthConstraint = childView.widthAnchor.constraint(
                lessThanOrEqualToConstant: contentView.bounds.size.width / CGFloat(actions.items.count)
            )
            widthConstraint.priority = UILayoutPriority(999)
            widthConstraint.isActive = true
            childView.delegate = self
            containerStackView.addArrangedSubview(childView)
        }
    }

    func hideBottomBorder(isHidden: Bool) {
        containerStackView.arrangedSubviews
          .compactMap { $0 as? PhotonActionSheetView }
          .forEach { $0.bottomBorder.isHidden = isHidden }
    }

    func applyTheme(theme: Theme) { }
}

// MARK: - PhotonActionSheetViewDelegate
extension PhotonActionSheetContainerCell: PhotonActionSheetViewDelegate {
    func didClick(item: SingleActionViewModel?, animationCompletion: @escaping () -> Void) {
        delegate?.didClick(item: item, animationCompletion: animationCompletion)
    }
}
