/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

struct OneLineCellUX {
    static let ImageSize: CGFloat = 29
    static let ImageCornerRadius: CGFloat = 6
    static let HorizontalMargin: CGFloat = 16
}

class OneLineTableViewCell: UITableViewCell, Themeable {
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
        label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
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
        containerView.addSubview(leftImageView)
        containerView.addSubview(midView)
        
        addSubview(containerView)
        bringSubviewToFront(containerView)
        
        containerView.snp.makeConstraints { make in
            make.height.equalTo(50)
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalTo(accessoryView?.snp.leading ?? snp.trailing)
        }
        
        leftImageView.snp.makeConstraints { make in
            make.height.width.equalTo(34)
            make.leading.equalTo(containerView.snp.leading).offset(15)
            make.centerY.equalTo(containerView.snp.centerY)
        }
        
        midView.snp.makeConstraints { make in
            make.height.equalTo(42)
            make.centerY.equalToSuperview()
            make.leading.equalTo(leftImageView.snp.trailing).offset(13)
            make.trailing.equalTo(containerView.snp.trailing).offset(-7)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.centerY.equalTo(midView.snp.centerY)
            make.leading.equalTo(midView.snp.leading)
            make.trailing.equalTo(midView.snp.trailing)
        }
        
        selectedBackgroundView = selectedView
        applyTheme()
    }
    
    func applyTheme() {
        let theme = BuiltinThemeName(rawValue: ThemeManager.instance.current.name) ?? .normal
        if theme == .dark {
            self.backgroundColor = UIColor.Photon.Grey70
            self.titleLabel.textColor = .white
        } else {
            self.backgroundColor = .white
            self.titleLabel.textColor = .black
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
            make.height.equalTo(50)
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalTo(accessoryView?.snp.leading ?? snp.trailing)
        }
    }
}

class OneLineFooterView: UITableViewHeaderFooterView, Themeable {
    fileprivate let bordersHelper = ThemedHeaderFooterViewBordersHelper()

    var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
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
    
    let containerView = UIView()
    
    private func initialViewSetup() {
        bordersHelper.initBorders(view: containerView)
        setDefaultBordersValues()
        layoutMargins = .zero

        containerView.addSubview(titleLabel)
        addSubview(containerView)
        
        containerView.snp.makeConstraints { make in
            make.height.equalTo(58)
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.height.equalTo(16)
            make.bottom.equalToSuperview().offset(-14)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
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
        let theme = BuiltinThemeName(rawValue: ThemeManager.instance.current.name) ?? .normal
        // TODO: Replace this color with proper value once tab tray refresh is done
        if theme == .dark {
            self.titleLabel.textColor = .white
            self.containerView.backgroundColor = UIColor(rgb: 0x1C1C1E)
        } else {
            self.titleLabel.textColor = .black
            self.containerView.backgroundColor = UIColor(rgb: 0xF2F2F7)
        }
        bordersHelper.applyTheme()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        setDefaultBordersValues()
        applyTheme()
    }
}
