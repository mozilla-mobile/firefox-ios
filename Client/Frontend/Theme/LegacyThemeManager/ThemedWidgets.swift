// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0
import UIKit

class ThemedTableViewCell: UITableViewCell, NotificationThemeable {
    var detailTextColor = UIColor.theme.tableView.disabledRowText
    let style: UITableViewCell.CellStyle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.style = style
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectedBackgroundView = UIView()
        applyTheme()

        // Ecosia: adjust layout margins
        contentView.directionalLayoutMargins.leading = 16
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme() {
        textLabel?.textColor = UIColor.theme.ecosia.primaryText
        detailTextLabel?.textColor = .theme.ecosia.secondaryText
        backgroundColor = UIColor.theme.tableView.rowBackground
        selectedBackgroundView?.backgroundColor = .theme.ecosia.primarySelectedBackground
        tintColor = UIColor.theme.general.controlTint
    }


    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }

    // Ecosia: fix layouting
    private var textFrame: CGRect?
    private var detailFrame: CGRect?

    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {

        // Fix autosizing of UITableViewCellStyle.Value1
        guard style == .value1, let textLabel = self.textLabel, let detailTextLabel = self.detailTextLabel else {
            return super.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
        }

        self.layoutIfNeeded()
        var size = super.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)

        let detailHeight = detailTextLabel.frame.size.height
        let textHeight = textLabel.frame.size.height
        let xMargin: CGFloat = 16
        let yMargin:CGFloat = 10
        let labelsMargin: CGFloat = 6
        let factor: CGFloat = 0.6

        size.height = max(detailHeight, textHeight) + 2 * yMargin

        var accessoryOffset = accessoryView?.frame.size.width ?? 0.0
        if accessoryOffset > 0 { accessoryOffset += 8 }

        if textLabel.frame.maxX > size.width * factor, textLabel.frame.maxX + labelsMargin >= detailTextLabel.frame.minX {
            var textFrame = textLabel.frame
            textFrame.origin.y = yMargin
            textFrame.size.width = size.width * factor
            textFrame.size.height = size.height - 2.0 * yMargin
            textFrame.size = textLabel.sizeThatFits(textFrame.size)
            self.textFrame = textFrame

            var detailFrame = detailTextLabel.frame
            detailFrame.origin.y = yMargin
            detailFrame.origin.x = textFrame.maxX + labelsMargin
            detailFrame.size.height = size.height - 2 * yMargin
            detailFrame.size.width = size.width - 2 * xMargin - textFrame.width - accessoryOffset - labelsMargin
            self.detailFrame = detailFrame
            size.height = max(detailFrame.height, textFrame.height) + 2 * yMargin
        } else if textFrame != nil, detailFrame != nil {
            // fix position on rotation
            textFrame!.size = textLabel.sizeThatFits(size)
            detailFrame!.size = detailTextLabel.sizeThatFits(size)
            size.height = max(detailFrame!.height, textFrame!.height) + 2 * yMargin
            detailFrame!.origin.x = textFrame!.maxX + labelsMargin
            detailFrame!.size.height = size.height - 2 * yMargin
            detailFrame!.size.width = size.width - 2 * xMargin - textFrame!.width - accessoryOffset - labelsMargin
        }
        return size
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let textFrame = textFrame, let detailFrame = detailFrame {
            self.textLabel?.frame = textFrame
            self.detailTextLabel?.frame = detailFrame
        }
    }
}

class ThemedTableViewController: UITableViewController, NotificationThemeable {
    override init(style: UITableView.Style = .grouped) {
        super.init(style: style)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ThemedTableViewCell(style: .subtitle, reuseIdentifier: nil)
        return cell
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        applyTheme()
    }

    func applyTheme() {
        tableView.separatorColor = UIColor.theme.tableView.separator
        tableView.backgroundColor = UIColor.theme.tableView.headerBackground
        tableView.reloadData()

        (tableView.tableHeaderView as? NotificationThemeable)?.applyTheme()
        (tableView.tableFooterView as? NotificationThemeable)?.applyTheme()
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
        topBorder.backgroundColor = UIColor.theme.ecosia.border
        bottomBorder.backgroundColor = UIColor.theme.ecosia.border
    }
}

class UISwitchThemed: UISwitch {
    override func layoutSubviews() {
        super.layoutSubviews()
        onTintColor = UIColor.theme.general.controlTint
        subviews.first?.subviews.first?.backgroundColor = .theme.ecosia.tertiaryBackground
    }
}
