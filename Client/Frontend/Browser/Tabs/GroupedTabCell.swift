// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import SnapKit
import UIKit
import Shared

struct GroupedTabCellProperties {
    struct CellUX {
        static let titleFontSize: CGFloat = 17
        static let defaultCellHeight: CGFloat = 300
    }

    struct CellStrings {
        static let showMoreAccessibilityId = "GroupedTabCell.ShowMoreButton"
        static let searchButtonAccessibilityId = "GroupTabCell.SearchButton"
    }
}

protocol GroupedTabsDelegate: AnyObject {
    func didSelectGroupedTab(tab: Tab?)
    func closeTab(tab: Tab)
    func performSearchOfGroupInNewTab(searchTerm: String?)
}

protocol GroupedTabDelegate: AnyObject {
    func closeGroupTab(tab: Tab)
    func selectGroupTab(tab: Tab)
    func newSearchFromGroup(searchTerm: String)
}

class GroupedTabCell: UICollectionViewCell,
                      UITableViewDataSource,
                      UITableViewDelegate,
                      GroupedTabsDelegate,
                      ReusableCell,
                      ThemeApplicable {
    var tabDisplayManagerDelegate: GroupedTabDelegate?
    var tabGroups: [ASGroup<Tab>]?
    var selectedTab: Tab?
    var hasExpanded = true
    var theme: Theme = LightTheme()

    // Views
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(GroupedTabContainerCell.self, forCellReuseIdentifier: GroupedTabContainerCell.cellIdentifier)
        tableView.allowsMultipleSelectionDuringEditing = false
        tableView.sectionHeaderHeight = 0
        tableView.sectionFooterHeight = 0
        tableView.tableHeaderView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 0, height: CGFloat.leastNormalMagnitude)))
        tableView.isScrollEnabled = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        return tableView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews(tableView)
        setupConstraints()
        applyTheme(theme: theme)
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
        return tabGroups?.count ?? 0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return GroupedTabCellProperties.CellUX.defaultCellHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: GroupedTabContainerCell.cellIdentifier,
                                                 for: indexPath) as! GroupedTabContainerCell
        cell.delegate = self
        cell.theme = theme
        cell.applyTheme(theme: theme)
        cell.tabs = tabGroups?.map { $0.groupedItems }[indexPath.item]
        cell.titleLabel.text = tabGroups?.map { $0.searchTerm }[indexPath.item] ?? ""
        cell.collectionView.reloadData()
        cell.selectedTab = selectedTab
        if let selectedTab = selectedTab { cell.focusTab(tab: selectedTab) }
        cell.backgroundColor = .clear
        cell.accessoryView = nil
        return cell
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    @objc
    func toggleInactiveTabSection() {
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
        guard tab.url != nil else { return tab.sessionData?.urls.last?.domainURL }

        return tab.url?.domainURL
    }

    func scrollToSelectedGroup() {
        if let searchTerm = selectedTab?.metadataManager?.tabGroupData.tabAssociatedSearchTerm {
            if let index = tabGroups?.firstIndex(where: { $0.searchTerm == searchTerm}) {
                tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .bottom, animated: true)
            }
        }
    }

    func applyTheme(theme: Theme) {
        self.backgroundColor = .clear
        self.tableView.backgroundColor = .clear
        tableView.reloadData()
    }

    // MARK: Grouped Tabs Delegate

    func didSelectGroupedTab(tab: Tab?) {
        if let tab = tab {
            tabDisplayManagerDelegate?.selectGroupTab(tab: tab)
        }
    }

    func closeTab(tab: Tab) {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .groupedTab, value: .closeGroupedTab, extras: nil)
        tabDisplayManagerDelegate?.closeGroupTab(tab: tab)
    }

    func performSearchOfGroupInNewTab(searchTerm: String?) {
        guard let searchTerm = searchTerm else { return }
        tabDisplayManagerDelegate?.newSearchFromGroup(searchTerm: searchTerm)
    }
}

class GroupedTabContainerCell: UITableViewCell,
                               UICollectionViewDelegateFlowLayout,
                               UICollectionViewDataSource,
                               TabCellDelegate,
                               ReusableCell,
                               ThemeApplicable {
    // Delegate
    weak var delegate: GroupedTabsDelegate?

    // Views
    var selectedView = UIView()

    lazy var searchButton: UIButton = .build { button in
        button.setImage(UIImage(named: "search")?.withTintColor(.label), for: [.normal])
        button.addTarget(self, action: #selector(self.handleSearchButtonTapped), for: .touchUpInside)
        button.isAccessibilityElement = true
        button.accessibilityIdentifier = GroupedTabCellProperties.CellStrings.searchButtonAccessibilityId
    }

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = .label
        titleLabel.font = UIFont.systemFont(ofSize: GroupedTabCellProperties.CellUX.titleFontSize, weight: .semibold)
        titleLabel.minimumScaleFactor = 0.6
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        return titleLabel
    }()

    let containerView = UIView()
    let midView = UIView()
    var tabs: [Tab]?
    var selectedTab: Tab?
    var searchGroupName: String = ""
    var theme: Theme = LightTheme()

    lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        collectionView.register(TabCell.self, forCellWithReuseIdentifier: TabCell.cellIdentifier)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.bounces = false
        collectionView.clipsToBounds = false
        collectionView.accessibilityIdentifier = "Top Tabs View"
        collectionView.semanticContentAttribute = .forceLeftToRight
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.layer.cornerRadius = 6.0
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

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let flowlayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        flowlayout.invalidateLayout()
    }

    func initialViewSetup() {
        self.selectionStyle = .default
        containerView.addSubviews(collectionView, searchButton, titleLabel)
        addSubview(containerView)
        contentView.addSubview(containerView)
        bringSubviewToFront(containerView)

        containerView.snp.makeConstraints { make in
            make.height.equalTo(233)
            make.edges.equalToSuperview()
        }

        searchButton.snp.makeConstraints { make in
            make.height.equalTo(23)
            make.width.equalTo(40)
            make.top.equalToSuperview().offset(30)
            make.leading.equalTo(self.safeArea.leading).inset(8)
        }

        titleLabel.snp.makeConstraints { make in
            make.height.equalTo(23)
            make.top.equalToSuperview().offset(30)
            make.leading.equalTo(searchButton.snp.trailing)
            make.centerX.equalToSuperview()
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview()
        }
    }

    func focusTab(tab: Tab) {
        if let tabs = tabs, let index = tabs.firstIndex(of: tab) {
            let indexPath = IndexPath(item: index, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: [.centeredHorizontally, .centeredVertically], animated: true)
        }
    }

    func applyTheme(theme: Theme) {
        selectedView.backgroundColor = theme.colors.layer3
        collectionView.backgroundColor = theme.colors.layer5
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.selectionStyle = .none
        self.titleLabel.text = searchGroupName
        applyTheme(theme: theme)
    }

    // UICollectionViewDelegateFlowLayout

    fileprivate var numberOfColumns: Int {
        // iPhone 4-6+ portrait
        if traitCollection.horizontalSizeClass == .compact && traitCollection.verticalSizeClass == .regular {
            return GridTabViewController.UX.compactNumberOfColumnsThin
        } else {
            return GridTabViewController.UX.numberOfColumnsWide
        }
    }

    @objc
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return GridTabViewController.UX.margin
    }

    @objc
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = floor((collectionView.bounds.width - GridTabViewController.UX.margin * CGFloat(numberOfColumns + 1)) / CGFloat(numberOfColumns))
        let isIpad = UIDevice.current.userInterfaceIdiom == .pad
        let padding = isIpad && !UIWindow.isLandscape ? 75 : (isIpad && UIWindow.isLandscape) ? 105 : 10
        let width = (Int(cellWidth) - padding) >= 0 ? Int(cellWidth) - padding : 0
        return CGSize(width: width, height: 188)
    }

    @objc
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(equalInset: GridTabViewController.UX.margin)
    }

    @objc
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return GridTabViewController.UX.margin
    }

    @objc
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let tab = tabs?[indexPath.item] {
            delegate?.didSelectGroupedTab(tab: tab)
        }
    }

    @objc
    func handleSearchButtonTapped() {
        delegate?.performSearchOfGroupInNewTab(searchTerm: titleLabel.text)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tabs?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TabCell.cellIdentifier, for: indexPath)
        guard let tabCell = cell as? TabCell,
              let tab = tabs?[indexPath.item]
        else { return cell }

        tabCell.delegate = self
        tabCell.configureWith(tab: tab,
                              isSelected: selectedTab == tab,
                              theme: theme)
        tabCell.animator = nil
        return tabCell
    }

    func tabCellDidClose(_ cell: TabCell) {
        if let indexPath = collectionView.indexPath(for: cell), let tab = tabs?[indexPath.item] {
            delegate?.closeTab(tab: tab)
        }
    }
}
