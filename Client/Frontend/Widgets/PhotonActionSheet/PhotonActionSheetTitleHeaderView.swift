// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

// MARK: - PhotonActionSheetTitleHeaderView
class PhotonActionSheetTitleHeaderView: UITableViewHeaderFooterView, ReusableCell, ThemeApplicable {
    static let Padding: CGFloat = 18

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = DynamicFontHelper.defaultHelper.SmallSizeRegularWeightAS
        titleLabel.numberOfLines = 1
        return titleLabel
    }()

    lazy var separatorView: UIView = {
        let separatorLine = UIView()
        return separatorLine
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        self.backgroundView = UIView()
        self.backgroundView?.backgroundColor = .clear
        contentView.addSubview(titleLabel)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(contentView).offset(PhotonActionSheetTitleHeaderView.Padding)
            make.trailing.equalTo(contentView)
            make.top.equalTo(contentView).offset(PhotonActionSheet.UX.tablePadding)
        }

        contentView.addSubview(separatorView)

        separatorView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.top.equalTo(titleLabel.snp.bottom).offset(PhotonActionSheet.UX.tablePadding)
            make.bottom.equalTo(contentView).inset(PhotonActionSheet.UX.tablePadding)
            make.height.equalTo(0.5)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with title: String) {
        self.titleLabel.text = title
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.titleLabel.text = nil
    }

    func applyTheme(theme: Theme) {
        separatorView.backgroundColor = theme.colors.borderPrimary
        titleLabel.textColor = theme.colors.textSecondary
    }
}
