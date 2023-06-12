// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import Common

enum ThemedTableViewCellType {
    case standard, actionPrimary, destructive, disabled
}

class ThemedTableViewCellViewModel {
    var type: ThemedTableViewCellType

    var textColor: UIColor!
    var detailTextColor: UIColor!
    var backgroundColor: UIColor!
    var tintColor: UIColor!

    init(theme: Theme, type: ThemedTableViewCellType) {
        self.type = type
        setColors(theme: theme)
    }

    func setColors(theme: Theme) {
        detailTextColor = theme.colors.textSecondary
        backgroundColor = theme.colors.layer5
        tintColor = theme.colors.actionPrimary

        switch self.type {
        case .standard:
            textColor = theme.colors.textPrimary
        case .actionPrimary:
            textColor = theme.colors.actionPrimary
        case .destructive:
            textColor = theme.colors.textWarning
        case .disabled:
            textColor = theme.colors.textDisabled
        }
    }
}

class ThemedTableViewCell: UITableViewCell, ReusableCell, ThemeApplicable {
    var viewModel: ThemedTableViewCellViewModel?
    var cellStyle: UITableViewCell.CellStyle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.cellStyle = style
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // When UITableViewAutomaticDimension is enabled the system calls
    // -systemLayoutSizeFittingSize:withHorizontalFittingPriority:verticalFittingPriority: to calculate the cell height.
    // Unfortunately, it ignores the height of the detailTextLabel in its computation (bug !?).
    // As a result, for UITableViewCellStyleSubtitle the cell height is always going to be too short.
    // So we override to include detailTextLabel height.
    override func systemLayoutSizeFitting(_ targetSize: CGSize,
                                          withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
                                          verticalFittingPriority: UILayoutPriority) -> CGSize {
        self.layoutSubviews()
        var size = super.systemLayoutSizeFitting(targetSize,
                                                 withHorizontalFittingPriority: horizontalFittingPriority,
                                                 verticalFittingPriority: verticalFittingPriority)
        if cellStyle == .value2 || cellStyle == .value1 {
            if let textLabel = self.textLabel, let detailTextLabel = self.detailTextLabel {
                let detailHeight = detailTextLabel.frame.size.height
                if detailTextLabel.frame.minX > textLabel.frame.minX { // style = Value1 or Value2
                    let textHeight = textLabel.frame.size.height
                    if detailHeight > textHeight {
                        size.height += detailHeight - textHeight
                    }
                } else { // style = Subtitle, so always add subtitle height
                    size.height += detailHeight
                }
            }
            return size
        } else {
            return size
        }
    }
    func applyTheme(theme: Theme) {
        self.viewModel?.setColors(theme: theme)
        // Take view model color if it exists, otherwise fallback to default colors
        textLabel?.textColor = viewModel?.textColor ?? theme.colors.textPrimary
        detailTextLabel?.textColor = viewModel?.detailTextColor ?? theme.colors.textSecondary
        backgroundColor = viewModel?.backgroundColor ?? theme.colors.layer5
        tintColor = viewModel?.tintColor ?? theme.colors.actionPrimary
    }

    func configure(viewModel: ThemedTableViewCellViewModel) {
        self.viewModel = viewModel
    }
}

class ThemedTableViewController: UITableViewController, Themeable {
    var themeManager: ThemeManager
    @objc var notificationCenter: NotificationProtocol
    var themeObserver: NSObjectProtocol?

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(style: UITableView.Style = .grouped,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(style: style)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return ThemedTableViewCell(style: .subtitle, reuseIdentifier: nil)
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: ThemedTableSectionHeaderFooterView.cellIdentifier) as? ThemedTableSectionHeaderFooterView
        else { return nil }
        headerView.applyTheme(theme: themeManager.currentTheme)
        return headerView
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: ThemedTableSectionHeaderFooterView.cellIdentifier) as? ThemedTableSectionHeaderFooterView
        else { return nil}
        footerView.applyTheme(theme: themeManager.currentTheme)
        return footerView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        applyTheme()
        listenForThemeChange(view)
    }

    func applyTheme() {
        tableView.separatorColor = themeManager.currentTheme.colors.borderPrimary
        tableView.backgroundColor = themeManager.currentTheme.colors.layer1
        tableView.reloadData()
    }
}

class ThemedHeaderFooterViewBordersHelper: ThemeApplicable {
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

    func applyTheme(theme: Theme) {
        topBorder.backgroundColor = theme.colors.borderPrimary
        bottomBorder.backgroundColor = theme.colors.borderPrimary
    }
}
