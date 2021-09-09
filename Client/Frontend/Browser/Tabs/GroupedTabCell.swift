/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import UIKit
import Shared

enum GroupedTabSection: Int, CaseIterable {
    case grouped
}

protocol GroupedTabsDelegate {
    func toggleGroupedTabSection(hasExpanded: Bool)
    func didSelectGroupedTab(tab: Tab?)
    func didTapRecentlyClosed()
}

struct GroupedTabCellUX {
    static let headerAndRowHeight: CGFloat = 45
}

class GroupedTabCell: UICollectionViewCell, Themeable, UITableViewDataSource, UITableViewDelegate {
    var groupedTabsViewModel: InactiveTabViewModel?
    static let Identifier = "GroupedTabCellIdentifier"
    let GroupedTabsTableIdentifier = "GroupedTabsTableIdentifier"
    let GroupedTabsHeaderIdentifier = "GroupedTabsHeaderIdentifier"
    let GroupedTabCellIdentifier = "GroupedTabCellIdentifier"
    var hasExpanded = true
    var delegate: GroupedTabsDelegate?
    static let defaultCellHeight: CGFloat = 300
    // Views
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(OneLineTableViewCell.self, forCellReuseIdentifier: GroupedTabsTableIdentifier)
        tableView.register(GroupedTabContainerCell.self, forCellReuseIdentifier: GroupedTabCellIdentifier)
        tableView.register(InactiveTabHeader.self, forHeaderFooterViewReuseIdentifier: GroupedTabsHeaderIdentifier)
        tableView.allowsMultipleSelectionDuringEditing = false
        tableView.sectionHeaderHeight = 0
        tableView.sectionFooterHeight = 0
        tableView.tableHeaderView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 0, height: CGFloat.leastNormalMagnitude)))
//        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.isScrollEnabled = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        return tableView
    }()

    convenience init(viewModel: InactiveTabViewModel) {
        self.init()
        groupedTabsViewModel = viewModel
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
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupedTabsViewModel?.tabGroups?.keys.count ?? 0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return GroupedTabCell.defaultCellHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: GroupedTabCellIdentifier, for: indexPath) as! GroupedTabContainerCell
        cell.tabs = groupedTabsViewModel?.tabGroups?.map { $0.value }[indexPath.item]
        cell.titleLabel.text = groupedTabsViewModel?.tabGroups?.map { $0.key }[indexPath.item] ?? ""
        cell.backgroundColor = .clear
        cell.accessoryView = nil
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let section = indexPath.section
        print(section)
    }
    
    @objc func toggleInactiveTabSection() {
        hasExpanded = !hasExpanded
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
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

class GroupedTabContainerCell: UITableViewCell, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    // Views
    var selectedView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.theme.tableView.selectedBackground
        return view
    }()
    
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.theme.homePanel.activityStreamHeaderText
        titleLabel.font = UIFont.systemFont(ofSize: FirefoxHomeHeaderViewUX.sectionHeaderSize, weight: .bold)
        titleLabel.minimumScaleFactor = 0.6
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        return titleLabel
    }()
    
    let containerView = UIView()
    let midView = UIView()

    let singleTabCellIdentifier = "singleTabCellIdentifier"
    var tabs: [Tab]? = nil
    var searchGroupName: String = ""
    
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: TopTabsViewLayout())
        collectionView.register(TabCell.self, forCellWithReuseIdentifier: singleTabCellIdentifier)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.bounces = false
        collectionView.clipsToBounds = false
        collectionView.accessibilityIdentifier = "Top Tabs View"
        collectionView.semanticContentAttribute = .forceLeftToRight
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .white
        collectionView.layer.cornerRadius = 6.0
        collectionView.layer.borderWidth = 1.0
        collectionView.layer.masksToBounds = true

        return collectionView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initialViewSetup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initialViewSetup() {
        self.selectionStyle = .default
        containerView.addSubview(collectionView)
        containerView.addSubview(titleLabel)
        addSubview(containerView)
        contentView.addSubview(containerView)
        bringSubviewToFront(containerView)
        
        containerView.snp.makeConstraints { make in
            make.height.equalTo(230)
            make.edges.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.top.equalToSuperview().offset(30)
            make.leading.equalTo(self.safeArea.leading).inset(20)
            make.centerX.equalToSuperview()
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(25)
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        applyTheme()
    }
    
    func applyTheme() {
        let theme = BuiltinThemeName(rawValue: ThemeManager.instance.current.name) ?? .normal
        if theme == .dark {
            self.backgroundColor = UIColor.Photon.Grey80
            self.titleLabel.textColor = .white
            collectionView.layer.borderColor = UIColor.Photon.DarkGrey40.cgColor
            collectionView.layer.backgroundColor = UIColor.Photon.DarkGrey40.cgColor
        } else {
            self.backgroundColor = .white
            self.titleLabel.textColor = .black
            collectionView.layer.borderColor = UIColor.Photon.LightGrey30.cgColor
            collectionView.layer.backgroundColor = UIColor.Photon.LightGrey05.cgColor
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.selectionStyle = .none
        self.titleLabel.text = searchGroupName
        applyTheme()
    }
    
    // UICollectionViewDelegateFlowLayout
    
    fileprivate var numberOfColumns: Int {
        // iPhone 4-6+ portrait
        if traitCollection.horizontalSizeClass == .compact && traitCollection.verticalSizeClass == .regular {
            return GridTabTrayControllerUX.CompactNumberOfColumnsThin
        } else {
            return GridTabTrayControllerUX.NumberOfColumnsWide
        }
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return GridTabTrayControllerUX.Margin
    }

    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = floor((collectionView.bounds.width - GridTabTrayControllerUX.Margin * CGFloat(numberOfColumns + 1)) / CGFloat(numberOfColumns))
        let padding = 10
        return CGSize(width: Int(cellWidth) - padding, height: 185)
    }

    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(equalInset: GridTabTrayControllerUX.Margin)
    }

    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return GridTabTrayControllerUX.Margin
    }

    @objc func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(indexPath.row)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tabs?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: singleTabCellIdentifier, for: indexPath)
        guard let tabCell = cell as? TabCell, let tab = tabs?[indexPath.item] else { return cell }
        tabCell.configureWith(tab: tab, is: false)
        return tabCell
    }
}
