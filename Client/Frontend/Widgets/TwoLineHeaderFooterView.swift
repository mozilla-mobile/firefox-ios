// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// TODO: Add support for accessibility for when text size changes
class TwoLineHeaderFooterView: UITableViewHeaderFooterView, NotificationThemeable {
    fileprivate let bordersHelper = ThemedHeaderFooterViewBordersHelper()
    var leftImageView: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFit
        imgView.clipsToBounds = true
        return imgView
    }()

    var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.textAlignment = .natural
        label.numberOfLines = 1
        return label
    }()

    var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12.5, weight: .regular)
        label.textAlignment = .natural
        label.numberOfLines = 1
        return label
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        initialViewSetup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initialViewSetup() {
        bordersHelper.initBorders(view: self)
        setDefaultBordersValues()
        layoutMargins = .zero
        let stackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .equalCentering
        stackView.spacing = 2

        contentView.addSubview(stackView)
        contentView.addSubview(leftImageView)

        leftImageView.snp.makeConstraints { make in
            make.height.width.equalTo(29)
            make.leading.equalToSuperview().inset(15)
            make.centerY.equalToSuperview()
        }

        stackView.snp.makeConstraints { make in
            make.height.equalTo(35)
            make.top.equalToSuperview().offset(6)
            make.bottom.equalToSuperview().offset(-6)
            make.leading.equalTo(leftImageView.snp.trailing).offset(15)
            make.trailing.equalToSuperview().inset(2)
        }

        applyTheme()
    }

    func showBorder(for location: ThemedHeaderFooterViewBordersHelper.BorderLocation, _ show: Bool) {
        bordersHelper.showBorder(for: location, show)
    }

    fileprivate func setDefaultBordersValues() {
        bordersHelper.showBorder(for: .top, true)
        bordersHelper.showBorder(for: .bottom, true)
    }

    func applyTheme() {
        let theme = BuiltinThemeName(rawValue: LegacyThemeManager.instance.current.name) ?? .normal
        self.backgroundColor = UIColor.theme.tableView.selectedBackground
        if theme == .dark {
            self.titleLabel.textColor = .white
            self.descriptionLabel.textColor = UIColor.Photon.Grey40
        } else {
            self.titleLabel.textColor = .black
            self.descriptionLabel.textColor = UIColor.Photon.Grey60
        }
        bordersHelper.applyTheme()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        setDefaultBordersValues()
        applyTheme()
    }
}
