/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
import UIKit

class ThemedTableViewCell: UITableViewCell, Themeable {
    var detailTextColor = UIColor.theme.tableView.disabledRowText

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        applyTheme()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme() {
        textLabel?.textColor = UIColor.theme.tableView.rowText
        detailTextLabel?.textColor = detailTextColor
        backgroundColor = UIColor.theme.tableView.rowBackground
        tintColor = UIColor.theme.general.controlTint
    }
}

class ThemedTableViewController: UITableViewController, Themeable {
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

        (tableView.tableHeaderView as? Themeable)?.applyTheme()
    }
}

class ThemedTableSectionHeaderFooterView: UITableViewHeaderFooterView, Themeable {
    private struct UX {
        static let titleHorizontalPadding: CGFloat = 15
        static let titleVerticalPadding: CGFloat = 6
        static let titleVerticalLongPadding: CGFloat = 20
    }

    enum TitleAlignment {
        case top
        case bottom
    }

    var titleAlignment: TitleAlignment = .bottom {
        didSet {
            remakeTitleAlignmentConstraints()
        }
    }

    lazy var titleLabel: UILabel = {
        var headerLabel = UILabel()
        headerLabel.font = UIFont.systemFont(ofSize: 12.0, weight: UIFont.Weight.regular)
        headerLabel.numberOfLines = 0
        return headerLabel
    }()

    fileprivate lazy var bordersHelper = ThemedHeaderFooterViewBordersHelper()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.addSubview(titleLabel)
        bordersHelper.initBorders(view: self)
        setDefaultBordersValues()
        setupInitialConstraints()
        applyTheme()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme() {
        bordersHelper.applyTheme()
        contentView.backgroundColor = UIColor.theme.tableView.headerBackground
        titleLabel.textColor = UIColor.theme.tableView.headerTextLight
    }

    func setupInitialConstraints() {
        remakeTitleAlignmentConstraints()
    }

    func showBorder(for location: ThemedHeaderFooterViewBordersHelper.BorderLocation, _ show: Bool) {
        bordersHelper.showBorder(for: location, show)
    }

    func setDefaultBordersValues() {
        bordersHelper.showBorder(for: .top, false)
        bordersHelper.showBorder(for: .bottom, false)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        setDefaultBordersValues()
        titleLabel.text = nil
        titleAlignment = .bottom

        applyTheme()
    }

    fileprivate func remakeTitleAlignmentConstraints() {
        switch titleAlignment {
        case .top:
            titleLabel.snp.remakeConstraints { make in
                make.left.right.equalTo(self.contentView).inset(UX.titleHorizontalPadding)
                make.top.equalTo(self.contentView).offset(UX.titleVerticalPadding)
                make.bottom.equalTo(self.contentView).offset(-UX.titleVerticalLongPadding)
            }
        case .bottom:
            titleLabel.snp.remakeConstraints { make in
                make.left.right.equalTo(self.contentView).inset(UX.titleHorizontalPadding)
                make.bottom.equalTo(self.contentView).offset(-UX.titleVerticalPadding)
                make.top.equalTo(self.contentView).offset(UX.titleVerticalLongPadding)
            }
        }
    }
}

class ThemedHeaderFooterViewBordersHelper: Themeable {
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

    func initBorders(view: UITableViewHeaderFooterView) {
        view.contentView.addSubview(topBorder)
        view.contentView.addSubview(bottomBorder)

        topBorder.snp.makeConstraints { make in
            make.left.right.top.equalTo(view.contentView)
            make.height.equalTo(0.25)
        }

        bottomBorder.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(view.contentView)
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
