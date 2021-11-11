// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Shared
import WebKit

class WebsiteDataManagementViewModel {
    enum State {
        case loading
        case displayInitial
        case displayAll
    }
    
    private(set) var state: State = .loading
    private(set) var siteRecords: [WKWebsiteDataRecord] = []
    private(set) var selectedRecords: Set<WKWebsiteDataRecord> = []
    var onViewModelChanged: () -> Void = {}
    
    var clearButtonTitle: String {
        switch selectedRecords.count {
        case 0: return .SettingsClearAllWebsiteDataButton
        default: return String(format: .SettingsClearSelectedWebsiteDataButton, "\(selectedRecords.count)")
        }
    }
    
    func loadAllWebsiteData() {
        state = .loading

        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: types) { [weak self] records in
            self?.siteRecords = records.sorted { $0.displayName < $1.displayName }
            self?.state = .displayInitial
            self?.onViewModelChanged()
        }
        
        self.onViewModelChanged()
    }
    
    func selectItem(_ item: WKWebsiteDataRecord) {
        selectedRecords.insert(item)
        onViewModelChanged()
    }
    
    func deselectItem(_ item: WKWebsiteDataRecord) {
        selectedRecords.remove(item)
        onViewModelChanged()
    }
    
    func createAlertToRemove() -> UIAlertController {
        if selectedRecords.isEmpty {
            return UIAlertController.clearAllWebsiteDataAlert { _ in self.removeAllRecords() }
        } else {
            return UIAlertController.clearSelectedWebsiteDataAlert { _ in self.removeSelectedRecords() }
        }
    }
    
    private func removeSelectedRecords() {
        let previousState = state
        state = .loading
        onViewModelChanged()
    
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        WKWebsiteDataStore.default().removeData(ofTypes: types, for: Array(selectedRecords)) { [weak self] in
            self?.state = previousState
            self?.siteRecords.removeAll { self?.selectedRecords.contains($0) ?? false }
            self?.selectedRecords = []
            self?.onViewModelChanged()
        }
    }
    
    private func removeAllRecords() {
        let previousState = state
        state = .loading
        onViewModelChanged()
        
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        WKWebsiteDataStore.default().removeData(ofTypes: types, modifiedSince: .distantPast) { [weak self] in
            self?.siteRecords = []
            self?.selectedRecords = []
            self?.state = previousState
            self?.onViewModelChanged()
        }
    }
}

class WebsiteDataManagementViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    private enum Section: Int {
        case sites = 0
        case showMore = 1
        case clearButton = 2
        
        static let count = 3
    }

    private let SectionHeaderFooterIdentifier = "SectionHeaderFooterIdentifier"
    
    fileprivate let loadingView = SettingsLoadingView()

    fileprivate var showMoreButton: ThemedTableViewCell?
    
    private let viewModel = WebsiteDataManagementViewModel()

    var tableView: UITableView!
    var searchController: UISearchController?
    var showMoreButtonEnabled = true
    let theme = BuiltinThemeName(rawValue: LegacyThemeManager.instance.current.name) ?? .normal

    private lazy var searchResultsViewController = WebsiteDataSearchResultsViewController(viewModel: viewModel)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = .SettingsWebsiteDataTitle
        navigationController?.setToolbarHidden(true, animated: false)

        tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorColor = UIColor.theme.tableView.separator
        tableView.backgroundColor = UIColor.theme.tableView.headerBackground
        tableView.isEditing = true
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.allowsSelectionDuringEditing = true
        tableView.register(ThemedTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderFooterIdentifier)

        let footer = ThemedTableSectionHeaderFooterView(frame: CGRect(width: tableView.bounds.width, height: SettingsUX.TableViewHeaderFooterHeight))
        footer.showBorder(for: .top, true)
        tableView.tableFooterView = footer

        view.addSubview(tableView)
        view.addSubview(loadingView)

        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }

        loadingView.snp.makeConstraints { make in
            make.edges.equalTo(tableView)
        }
        
        viewModel.onViewModelChanged = { [weak self] in
            guard let self = self else { return }
            self.loadingView.isHidden = self.viewModel.state != .loading

            // Show either 10, 8 or 6 records initially depending on the screen size.
            let height = max(self.view.frame.width, self.view.frame.height)
            let numberOfInitialRecords = height > 667 ? 10 : height > 568 ? 8 : 6
            self.showMoreButtonEnabled = self.viewModel.siteRecords.count > numberOfInitialRecords

            self.searchResultsViewController.reloadData()
            self.tableView.reloadData()
        }

        viewModel.loadAllWebsiteData()

        let searchController = UISearchController(searchResultsController: searchResultsViewController)

        // No need to hide the navigation bar on iPad, on iPhone the additional height is useful.
        searchController.hidesNavigationBarDuringPresentation = UIDevice.current.userInterfaceIdiom != .pad

        searchController.searchResultsUpdater = searchResultsViewController
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = .SettingsFilterSitesSearchLabel
        searchController.searchBar.delegate = self

        if theme == .dark {
            searchController.searchBar.barStyle = .black
        }
        navigationItem.searchController = searchController
        self.searchController = searchController

        definesPresentationContext = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        unfoldSearchbar()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ThemedTableViewCell(style: .default, reuseIdentifier: nil)
        let section = Section(rawValue: indexPath.section)!
        switch section {
        case .sites:
            if let record = viewModel.siteRecords[safe: indexPath.row] {
                cell.textLabel?.text = record.displayName
                if viewModel.selectedRecords.contains(record) {
                    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                } else {
                    tableView.deselectRow(at: indexPath, animated: false)
                }
            }
        case .showMore:
            cell.textLabel?.text = .SettingsWebsiteDataShowMoreButton
            cell.textLabel?.textColor = showMoreButtonEnabled ? UIColor.theme.general.highlightBlue : UIColor.gray
            cell.accessibilityTraits = UIAccessibilityTraits.button
            cell.accessibilityIdentifier = "ShowMoreWebsiteData"
            showMoreButton = cell 
        case .clearButton:
            cell.textLabel?.text = viewModel.clearButtonTitle
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.textColor = UIColor.theme.general.destructiveRed
            cell.accessibilityTraits = UIAccessibilityTraits.button
            cell.accessibilityIdentifier = "ClearAllWebsiteData"
        }
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = Section(rawValue: section)!
        switch section {
        case .sites:
            let numberOfRecords = viewModel.siteRecords.count

            // Show either 10, 8 or 6 records initially depending on the screen size.
            let height = max(self.view.frame.width, self.view.frame.height)
            let numberOfInitialRecords = height > 667 ? 10 : height > 568 ? 8 : 6
            return showMoreButtonEnabled ? min(numberOfRecords, numberOfInitialRecords) : numberOfRecords
        case .showMore:
            return showMoreButtonEnabled ? 1 : 0
        case .clearButton:
            return 1
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = Section(rawValue: indexPath.section)!
        switch section {
        case .sites:
            guard let item = viewModel.siteRecords[safe: indexPath.row] else { return }
            viewModel.selectItem(item)
            break
        case .showMore:
            showMoreButtonEnabled = false
            tableView.reloadData()
        case .clearButton:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
            let alert = viewModel.createAlertToRemove()
            present(alert, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let section = Section(rawValue: indexPath.section)!
        switch section {
        case .sites:
            guard let item = viewModel.siteRecords[safe: indexPath.row] else { return }
            viewModel.deselectItem(item)
            break
        default: break;
        }
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let section = Section(rawValue: indexPath.section)!
        switch section {
        case .sites:
            return true
        case .showMore, .clearButton:
            return false
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderFooterIdentifier) as? ThemedTableSectionHeaderFooterView
        headerView?.titleLabel.text = section == Section.sites.rawValue ? .SettingsWebsiteDataTitle : nil

        headerView?.showBorder(for: .top, true)
        headerView?.showBorder(for: .bottom, true)

        // top section: no top border (this is a plain table)
        guard let section = Section(rawValue: section) else { return headerView }
        if section == .sites {
            headerView?.showBorder(for: .top, false)

            // no records: no bottom border (would make 2 with the one from the clear button)
            let emptyRecords = viewModel.siteRecords.isEmpty
            if emptyRecords {
                headerView?.showBorder(for: .bottom, false)
            }
        }
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let section = Section(rawValue: section)!
        switch section {
        case .clearButton:
            return 10 // Controls the space between the site list and the button
        case .sites:
            return SettingsUX.TableViewHeaderFooterHeight
        case .showMore:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderFooterIdentifier) as? ThemedTableSectionHeaderFooterView
        footerView?.showBorder(for: .top, true)
        footerView?.showBorder(for: .bottom, true)
        return footerView
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    
    
    private func unfoldSearchbar() {
        guard let searchBarHeight = navigationItem.searchController?.searchBar.intrinsicContentSize.height else { return }
        tableView.setContentOffset(CGPoint(x: 0, y: -searchBarHeight + tableView.contentOffset.y), animated: true)
    }
}
