// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class SimpleTwoLineCell: UITableViewCell, NotificationThemeable {
    // Tableview cell items
    var selectedView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.theme.tableView.selectedBackground
        return view
    }()

    var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        label.textAlignment = .natural
        label.numberOfLines = 1
        return label
    }()

    var descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.Photon.Grey40
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .natural
        label.numberOfLines = 1
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initialViewSetup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initialViewSetup() {
        separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        self.selectionStyle = .default
        let midView = UIView()
        midView.addSubview(titleLabel)
        midView.addSubview(descriptionLabel)
        let containerView = UIView()
        containerView.addSubview(midView)
        contentView.addSubview(containerView)

        containerView.snp.makeConstraints { make in
            make.height.equalTo(65)
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
        }

        midView.snp.makeConstraints { make in
            make.height.equalTo(46)
            make.centerY.equalToSuperview()
            make.leading.equalTo(containerView.snp.leading)
            make.trailing.equalTo(containerView.snp.trailing)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(midView.snp.top).offset(4)
            make.height.equalTo(18)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.height.equalTo(14)
            make.bottom.equalTo(midView.snp.bottom).offset(-4)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
        }

        selectedBackgroundView = selectedView
        applyTheme()
    }

    func applyTheme() {
        let theme = BuiltinThemeName(rawValue: LegacyThemeManager.instance.current.name) ?? .normal
        if theme == .dark {
            self.backgroundColor = UIColor.Photon.Grey80
            self.titleLabel.textColor = .white
            self.descriptionLabel.textColor = UIColor.Photon.Grey40
        } else {
            self.backgroundColor = .white
            self.titleLabel.textColor = .black
            self.descriptionLabel.textColor = UIColor.Photon.DarkGrey05
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.selectionStyle = .default
        separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        applyTheme()
    }
}
