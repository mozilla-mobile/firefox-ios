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

//    var footerText: String? {
//        switch self {
//        case .inactive: return nil
//        case .recentlyClosed: return String.TabsTrayRecentlyClosedTabsDescritpion
//        }
//    }
}

class InactiveTabCell: UICollectionViewCell, Themeable, UITableViewDataSource, UITableViewDelegate {
    var inactiveTabsViewModel: InactiveViewModel?
    static let Identifier = "InactiveTabCellIdentifier"
    let InactiveTabsTableIdentifier = "InactiveTabsTableIdentifier"

    // Views
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(OneLineTableViewCell.self, forCellReuseIdentifier: InactiveTabsTableIdentifier)
        tableView.allowsMultipleSelectionDuringEditing = false
        tableView.sectionHeaderHeight = 0
        tableView.sectionFooterHeight = 0
        tableView.tableHeaderView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 0, height: CGFloat.leastNormalMagnitude)))
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 0)
        tableView.isScrollEnabled = false
//        tableView.tableFooterView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 0, height: CGFloat.leastNormalMagnitude)))
//        tableView.style = .grouped
        return tableView
    }()

    convenience init(viewModel: InactiveViewModel) {
        self.init()
        inactiveTabsViewModel = viewModel
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        tableView.dataSource = self
        tableView.delegate = self
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
//        super.init(frame: .zero)
//        super.init(frame: CGRect(width: 150, height: 150))
//        tableView.frame = CGRect(width: 150, height: 150)
        addSubviews(tableView)
        addSubviews(tableView)
        setupConstraints()
        applyTheme()

    }
//    init() {
//        super.init(frame: .zero)
//        addSubviews(tableView)
//        setupConstraints()
//        applyTheme()
//    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
//        tableView.frame = self.frame
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.bringSubviewToFront(tableView)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return InactiveTabSection.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        guard let count = inactiveTabsViewModel?.inactiveTabs.count else { return 0 }
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
        return 45
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: InactiveTabsTableIdentifier, for: indexPath) as! OneLineTableViewCell
        switch InactiveTabSection(rawValue: indexPath.section) {
        case .inactive:
            guard let tab = inactiveTabsViewModel?.inactiveTabs[indexPath.item] else { return cell }
            cell.backgroundColor = .clear
            cell.accessoryView = nil
            cell.titleLabel.text = tab.displayTitle
            cell.leftImageView.setImageAndBackground(forIcon: tab.displayFavicon, website: getTabDomainUrl(tab: tab)) {}
            cell.shouldLeftAlignTitle = false
            cell.updateMidConstraint()
            cell.accessoryType = .none
            return cell
        case .recentlyClosed:
            cell.backgroundColor = .clear
            cell.accessoryView = nil
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
        switch InactiveTabSection(rawValue: section) {
        case .inactive, .none:
            return nil
        case .recentlyClosed:
            return String.TabsTrayRecentlyClosedTabsDescritpion
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch InactiveTabSection(rawValue: section) {
        case .inactive, .none:
            return CGFloat.leastNormalMagnitude
        case .recentlyClosed:
            return 45
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("\(indexPath)")
    }
//    
//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        return nil
//    }
//    
//    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return CGFloat.leastNormalMagnitude
//    }
//
//    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
//        return CGFloat.leastNormalMagnitude
//    }
    
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
