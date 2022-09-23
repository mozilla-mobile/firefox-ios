// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0
import UIKit

class ThemedTableViewCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme(theme: Theme) {
        textLabel?.textColor = theme.colors.textPrimary
        detailTextLabel?.textColor = theme.colors.textSecondary
        backgroundColor = theme.colors.layer2
        tintColor = theme.colors.actionPrimary
    }
}

class ThemedTableViewController: UITableViewController, Themeable {

    var themeManager: ThemeManager = AppContainer.shared.resolve()
    var notificationCenter: NotificationProtocol = NotificationCenter.default
    var themeObserver: NSObjectProtocol?

    override init(style: UITableView.Style = .grouped) {
        super.init(style: style)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return ThemedTableViewCell(style: .subtitle, reuseIdentifier: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        applyTheme()
        listenForThemeChange()
    }

    func applyTheme() {
        tableView.separatorColor = themeManager.currentTheme.colors.layer4
        tableView.backgroundColor = themeManager.currentTheme.colors.layer1
        tableView.reloadData()

        // TODO: Remove with legacy theme clean up FXIOS-3960
        (tableView.tableHeaderView as? NotificationThemeable)?.applyTheme()
    }
}

class ThemedHeaderFooterViewBordersHelper: NotificationThemeable {
    enum BorderLocation {
        case top
        case bottom
    }

    fileprivate lazy var topBorder: UIView = {
        let topBorder = UIView()
        return topBorder
    }()

    fileprivate lazy var bottomBorder: UIView = {
        let bottomBorder = UIView()
        return bottomBorder
    }()

    func showBorder(for location: BorderLocation, _ show: Bool) {
        switch location {
        case .top:
            topBorder.isHidden = !show
        case .bottom:
            bottomBorder.isHidden = !show
        }
    }

    func initBorders(view: UIView) {
        view.addSubview(topBorder)
        view.addSubview(bottomBorder)

        topBorder.snp.makeConstraints { make in
            make.left.right.top.equalTo(view)
            make.height.equalTo(0.25)
        }

        bottomBorder.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(view)
            make.height.equalTo(0.5)
        }
    }

    func applyTheme() {
        topBorder.backgroundColor = UIColor.theme.tableView.separator
        bottomBorder.backgroundColor = UIColor.theme.tableView.separator
    }
}

class UISwitchThemed: UISwitch {
    override func layoutSubviews() {
        super.layoutSubviews()
        onTintColor = UIColor.theme.general.controlTint
    }
}
