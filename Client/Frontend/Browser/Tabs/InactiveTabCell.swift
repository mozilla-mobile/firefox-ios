/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import UIKit
import Shared

enum InactiveTabSection: Int, CaseIterable {
    case inactive
    case recentlyClosed
}

protocol InactiveTabsDelegate {
    func toggleInactiveTabSection(hasExpanded: Bool)
    func didSelectInactiveTab(tab: Tab?)
    func didTapRecentlyClosed()
}

struct InactiveTabCellUX {
    static let headerAndRowHeight: CGFloat = 45
}

class InactiveTabCell: UICollectionViewCell, Themeable, UITableViewDataSource, UITableViewDelegate {
    var inactiveTabsViewModel: InactiveTabViewModel?
    static let Identifier = "InactiveTabCellIdentifier"
    let InactiveTabsTableIdentifier = "InactiveTabsTableIdentifier"
    let InactiveTabsHeaderIdentifier = "InactiveTabsHeaderIdentifier"
    var hasExpanded = false
    var delegate: InactiveTabsDelegate?
    
    // Views
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(OneLineTableViewCell.self, forCellReuseIdentifier: InactiveTabsTableIdentifier)
        tableView.register(InactiveTabHeader.self, forHeaderFooterViewReuseIdentifier: InactiveTabsHeaderIdentifier)
        tableView.allowsMultipleSelectionDuringEditing = false
        tableView.sectionHeaderHeight = 0
        tableView.sectionFooterHeight = 0
        tableView.tableHeaderView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 0, height: CGFloat.leastNormalMagnitude)))
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 0)
        tableView.isScrollEnabled = false
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()

    convenience init(viewModel: InactiveTabViewModel) {
        self.init()
        inactiveTabsViewModel = viewModel
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews(tableView)
        setupConstraints()
        applyTheme()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.bringSubviewToFront(tableView)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return InactiveTabSection.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !hasExpanded { return 0 }
        switch InactiveTabSection(rawValue: section) {
        case .inactive:
            return inactiveTabsViewModel?.inactiveTabs.count ?? 0
        case .recentlyClosed:
            return 1
        case .none:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return InactiveTabCellUX.headerAndRowHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: InactiveTabsTableIdentifier, for: indexPath) as! OneLineTableViewCell
        cell.customization = .inactiveCell
        cell.backgroundColor = .clear
        cell.accessoryView = nil
        switch InactiveTabSection(rawValue: indexPath.section) {
        case .inactive:
            guard let tab = inactiveTabsViewModel?.inactiveTabs[indexPath.item] else { return cell }
            cell.titleLabel.text = tab.displayTitle
            cell.leftImageView.setImageAndBackground(forIcon: tab.displayFavicon, website: getTabDomainUrl(tab: tab)) {}
            cell.shouldLeftAlignTitle = false
            cell.updateMidConstraint()
            cell.accessoryType = .none
            return cell
        case .recentlyClosed:
            cell.titleLabel.text = String.TabsTrayRecentlyCloseTabsSectionTitle
            cell.leftImageView.image = nil
            cell.shouldLeftAlignTitle = true
            cell.updateMidConstraint()
            cell.accessoryType = .disclosureIndicator
            return cell
        case .none:
            return cell
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if !hasExpanded { return nil }
        switch InactiveTabSection(rawValue: section) {
        case .inactive, .none:
            return nil
        case .recentlyClosed:
            return String.TabsTrayRecentlyClosedTabsDescritpion
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if !hasExpanded { return CGFloat.leastNormalMagnitude }
        switch InactiveTabSection(rawValue: section) {
        case .inactive, .none:
            return CGFloat.leastNormalMagnitude
        case .recentlyClosed:
            return InactiveTabCellUX.headerAndRowHeight
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let section = indexPath.section
        switch InactiveTabSection(rawValue: section) {
        case .inactive:
            if let tab = inactiveTabsViewModel?.inactiveTabs[indexPath.item] {
                delegate?.didSelectInactiveTab(tab: tab)
            }
        case .recentlyClosed, .none:
            delegate?.didTapRecentlyClosed()
        }
        
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch InactiveTabSection(rawValue: section) {
        case .inactive, .none:
            guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: InactiveTabsHeaderIdentifier) as? InactiveTabHeader else { return nil }
            headerView.state = hasExpanded ? .down : .right
            headerView.title = String.TabsTrayInactiveTabsSectionTitle
            headerView.moreButton.isHidden = false
            headerView.moreButton.addTarget(self, action: #selector(toggleInactiveTabSection), for: .touchUpInside)
            headerView.contentView.backgroundColor = .clear
            return headerView
        case .recentlyClosed:
            return nil
        }
    }
    
    @objc func toggleInactiveTabSection() {
        hasExpanded = !hasExpanded
        tableView.reloadData()
        delegate?.toggleInactiveTabSection(hasExpanded: hasExpanded)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch InactiveTabSection(rawValue: section) {
        case .inactive, .none:
            return InactiveTabCellUX.headerAndRowHeight
        case .recentlyClosed:
            return CGFloat.leastNormalMagnitude
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        switch InactiveTabSection(rawValue: section) {
        case .inactive, .none:
            return InactiveTabCellUX.headerAndRowHeight
        case .recentlyClosed:
            return CGFloat.leastNormalMagnitude
        }
    }
    
    func getTabDomainUrl(tab: Tab) -> URL? {
        guard tab.url != nil else {
            return tab.sessionData?.urls.last?.domainURL
        }
        return tab.url?.domainURL
    }

    func applyTheme() {
        self.backgroundColor = .clear
        self.tableView.backgroundColor = .clear
        tableView.reloadData()
    }
}

enum ExpandButtonState {
    case right
    case down
    
    var image: UIImage {
        switch self {
        case .right:
            return UIImage(named: "menu-Disclosure")!
        case .down:
            return UIImage(named: "find_next")!
        }
    }
}

class InactiveTabHeader: UITableViewHeaderFooterView, Themeable {
    var state: ExpandButtonState? {
        willSet(state) {
            moreButton.setImage(state?.image, for: .normal)
        }
    }
    
    lazy var containerView: UIView = {
        let containerView = UIView()
        return titleLabel
    }()
    
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = self.title
        titleLabel.textColor = UIColor.theme.homePanel.activityStreamHeaderText
        titleLabel.font = UIFont.systemFont(ofSize: FirefoxHomeHeaderViewUX.sectionHeaderSize, weight: .bold)
        titleLabel.minimumScaleFactor = 0.6
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        return titleLabel
    }()
    
    lazy var moreButton: UIButton = {
        let button = UIButton()
        button.isHidden = true
        button.setImage(state?.image, for: .normal)
        button.contentHorizontalAlignment = .right
        return button
    }()

    var title: String? {
        willSet(newTitle) {
            titleLabel.text = newTitle
        }
    }

    var titleInsets: CGFloat {
        get {
            return UIScreen.main.bounds.size.width == self.frame.size.width && UIDevice.current.userInterfaceIdiom == .pad ? FirefoxHomeHeaderViewUX.Insets : FirefoxHomeUX.MinimumInsets
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
        moreButton.setTitle(nil, for: .normal)
        moreButton.accessibilityIdentifier = nil;
        titleLabel.text = nil
        moreButton.removeTarget(nil, action: nil, for: .allEvents)
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.addSubview(titleLabel)
        contentView.addSubview(moreButton)
        
        moreButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.equalTo(titleLabel.snp.trailing)
            let insetValue = UIDevice.current.userInterfaceIdiom == .pad ? 8 : 12
            make.trailing.equalTo(self.safeArea.trailing).inset(insetValue)
        }
        moreButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(self.safeArea.leading).inset(5)
            make.centerX.equalToSuperview()
        }
        
        applyTheme()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme() {
        let theme = BuiltinThemeName(rawValue: ThemeManager.instance.current.name) ?? .normal
        self.titleLabel.textColor = theme == .dark ? .white : .black
    }
}
