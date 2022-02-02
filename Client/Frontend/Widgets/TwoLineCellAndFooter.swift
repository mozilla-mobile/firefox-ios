// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import SnapKit

struct TwoLineCellUX {
    static let ImageSize: CGFloat = 29
    static let BorderViewMargin: CGFloat = 16
}

// TODO: Add support for accessibility for when text size changes

class TwoLineImageOverlayCell: UITableViewCell, NotificationThemeable {
    // Tableview cell items
    var selectedView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.theme.tableView.selectedBackground
        return view
    }()
    
    var leftImageView: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFit
        imgView.layer.cornerRadius = 5.0
        imgView.clipsToBounds = true
        return imgView
    }()
    
    var leftOverlayImageView: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFit
        imgView.clipsToBounds = true
        return imgView
    }()

    var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textAlignment = .left
        label.numberOfLines = 1
        return label
    }()
    
    var descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.Photon.Grey40
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .left
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
    
    let containerView = UIView()
    let midView = UIView()
    
    private func initialViewSetup() {
        separatorInset = UIEdgeInsets(top: 0, left: TwoLineCellUX.ImageSize + 2 * TwoLineCellUX.BorderViewMargin, bottom: 0, right: 0)
        self.selectionStyle = .default
        midView.addSubview(titleLabel)
        midView.addSubview(descriptionLabel)

        containerView.addSubview(leftImageView)
        containerView.addSubview(midView)

        containerView.addSubview(leftOverlayImageView)
        addSubview(containerView)
        contentView.addSubview(containerView)
        bringSubviewToFront(containerView)

        containerView.snp.makeConstraints { make in
            make.height.equalTo(58)
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalTo(accessoryView?.snp.leading ?? snp.trailing)
        }

        leftImageView.snp.makeConstraints { make in
            make.height.width.equalTo(28)
            make.leading.equalTo(containerView.snp.leading).offset(15)
            make.centerY.equalTo(containerView.snp.centerY)
        }

        leftOverlayImageView.snp.makeConstraints { make in
            make.height.width.equalTo(22)
            make.trailing.equalTo(leftImageView).offset(7)
            make.bottom.equalTo(leftImageView).offset(7)
        }

        midView.snp.makeConstraints { make in
            make.height.equalTo(46)
            make.centerY.equalToSuperview()
            make.leading.equalTo(leftImageView.snp.trailing).offset(13)
            make.trailing.equalTo(containerView.snp.trailing).offset(-7)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(midView.snp.top).offset(4)
            make.height.equalTo(18)
            make.leading.equalTo(midView.snp.leading)
            make.trailing.equalTo(midView.snp.trailing)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.height.equalTo(16)
            make.bottom.equalTo(midView.snp.bottom).offset(-4)
            make.leading.equalTo(midView.snp.leading)
            make.trailing.equalTo(midView.snp.trailing)
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
        separatorInset = UIEdgeInsets(top: 0, left: TwoLineCellUX.ImageSize + 2 * TwoLineCellUX.BorderViewMargin, bottom: 0, right: 0)
        applyTheme()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.snp.remakeConstraints { make in
            make.height.equalTo(58)
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalTo(accessoryView?.snp.leading ?? snp.trailing)
        }
    }
}


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
        label.textAlignment = .left
        label.numberOfLines = 1
        return label
    }()
    
    var descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.Photon.Grey40
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .left
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
        label.textAlignment = .left
        label.numberOfLines = 1
        return label
    }()
    
    var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12.5, weight: .regular)
        label.textAlignment = .left
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
