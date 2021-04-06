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
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.separatorInset = .zero
        self.applyTheme()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let indentation = CGFloat(indentationLevel) * indentationWidth

        imageView?.translatesAutoresizingMaskIntoConstraints = true
        imageView?.contentMode = .scaleAspectFill
        imageView?.layer.cornerRadius = OneLineCellUX.ImageCornerRadius
        imageView?.layer.masksToBounds = true
        imageView?.snp.remakeConstraints { make in
            guard let _ = imageView?.superview else { return }

            make.width.height.equalTo(OneLineCellUX.ImageSize)
            make.leading.equalTo(indentation + OneLineCellUX.HorizontalMargin)
            make.centerY.equalToSuperview()
        }

        textLabel?.font = DynamicFontHelper.defaultHelper.DeviceFontHistoryPanel
        textLabel?.snp.remakeConstraints { make in
            guard let _ = textLabel?.superview else { return }

            make.leading.equalTo(indentation + OneLineCellUX.ImageSize + OneLineCellUX.HorizontalMargin*2)
            make.trailing.equalTo(isEditing ? 0 : -OneLineCellUX.HorizontalMargin)
            make.centerY.equalToSuperview()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.applyTheme()
    }

    func applyTheme() {
        backgroundColor = UIColor.theme.tableView.rowBackground
        textLabel?.textColor = UIColor.theme.tableView.rowText
    }
}


class SimpleOneLineFooterView: UITableViewHeaderFooterView, Themeable {
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

    private func initialViewSetup() {
        let containerView = UIView()
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
            self.backgroundColor = UIColor(rgb: 0x1C1C1E)
        } else {
            self.titleLabel.textColor = .black
            self.backgroundColor = UIColor(rgb: 0xF2F2F7)
        }
        bordersHelper.applyTheme()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        setDefaultBordersValues()
        applyTheme()
    }
}
