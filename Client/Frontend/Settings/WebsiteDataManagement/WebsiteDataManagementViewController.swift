// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import Common

class WebsiteDataManagementViewController: UIViewController, UITableViewDataSource,
                                           UITableViewDelegate, UISearchBarDelegate, Themeable {
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol

    private enum Section: Int {
        case sites = 0
        case showMore = 1
        case clearButton = 2

        static let count = 3
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
    }

    fileprivate let loadingView = SettingsLoadingView()

    fileprivate var showMoreButton: ThemedTableViewCell?

    private let viewModel = WebsiteDataManagementViewModel()

    var tableView: UITableView!
    var searchController: UISearchController?
    var showMoreButtonEnabled = true

    private lazy var searchResultsViewController = WebsiteDataSearchResultsViewController(viewModel: viewModel)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = .SettingsWebsiteDataTitle
        navigationController?.setToolbarHidden(true, animated: false)

        tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorColor = themeManager.currentTheme.colors.borderPrimary
        tableView.backgroundColor = themeManager.currentTheme.colors.layer1
        tableView.isEditing = true
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.allowsSelectionDuringEditing = true
        tableView.register(cellType: ThemedTableViewCell.self)
        tableView.register(ThemedTableSectionHeaderFooterView.self,
                           forHeaderFooterViewReuseIdentifier: ThemedTableSectionHeaderFooterView.cellIdentifier)

        let footer = ThemedTableSectionHeaderFooterView(frame: CGRect(width: tableView.bounds.width,
                                                                      height: SettingsUX.TableViewHeaderFooterHeight))
        footer.applyTheme(theme: themeManager.currentTheme)
        footer.showBorder(for: .top, true)
        tableView.tableFooterView = footer

        view.addSubview(tableView)
        view.addSubview(loadingView)
        loadingView.applyTheme(theme: themeManager.currentTheme)

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
        searchController.searchBar.barStyle = themeManager.currentTheme.type.getBarStyle()

        navigationItem.searchController = searchController
        self.searchController = searchController

        definesPresentationContext = true

        listenForThemeChange(view)
        applyTheme()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        unfoldSearchbar()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = dequeueCellFor(indexPath: indexPath)
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
            let cellViewModel = ThemedTableViewCellViewModel(theme: themeManager.currentTheme, type: .standard)
            cell.configure(viewModel: cellViewModel)
        case .showMore:
            let cellType: ThemedTableViewCellType = showMoreButtonEnabled ? .actionPrimary : .disabled
            let cellViewModel = ThemedTableViewCellViewModel(theme: themeManager.currentTheme, type: cellType)
            cell.textLabel?.text = .SettingsWebsiteDataShowMoreButton
            cell.accessibilityTraits = UIAccessibilityTraits.button
            cell.accessibilityIdentifier = "ShowMoreWebsiteData"
            cell.configure(viewModel: cellViewModel)
            showMoreButton = cell
        case .clearButton:
            let cellViewModel = ThemedTableViewCellViewModel(theme: themeManager.currentTheme, type: .destructive)
            cell.textLabel?.text = viewModel.clearButtonTitle
            cell.textLabel?.textAlignment = .center
            cell.accessibilityTraits = UIAccessibilityTraits.button
            cell.accessibilityIdentifier = "ClearAllWebsiteData"
            cell.configure(viewModel: cellViewModel)
        }

        cell.applyTheme(theme: themeManager.currentTheme)
        return cell
    }

    private func dequeueCellFor(indexPath: IndexPath) -> ThemedTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ThemedTableViewCell.cellIdentifier, for: indexPath) as? ThemedTableViewCell
        else {
            return ThemedTableViewCell()
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
        default: break
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
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: ThemedTableSectionHeaderFooterView.cellIdentifier) as? ThemedTableSectionHeaderFooterView else { return nil }

        headerView.titleLabel.text = section == Section.sites.rawValue ? .SettingsWebsiteDataTitle : nil

        headerView.showBorder(for: .top, true)
        headerView.showBorder(for: .bottom, true)

        // top section: no top border (this is a plain table)
        guard let section = Section(rawValue: section) else { return headerView }

        if section == .sites {
            headerView.showBorder(for: .top, false)

            // no records: no bottom border (would make 2 with the one from the clear button)
            let emptyRecords = viewModel.siteRecords.isEmpty
            if emptyRecords {
                headerView.showBorder(for: .bottom, false)
            }
        } else if section == .clearButton {
            headerView.showBorder(for: .top, false)
            headerView.showBorder(for: .bottom, true)
        }

        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let section = Section(rawValue: section)!
        switch section {
        case .clearButton:
            return 10 // Controls the space between the site list and the button
        case .sites:
            return UITableView.automaticDimension
        case .showMore:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: ThemedTableSectionHeaderFooterView.cellIdentifier) as? ThemedTableSectionHeaderFooterView else { return nil }

        footerView.showBorder(for: .top, true)
        footerView.showBorder(for: .bottom, true)
        return footerView
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    private func unfoldSearchbar() {
        guard let searchBarHeight = navigationItem.searchController?.searchBar.intrinsicContentSize.height else { return }
        tableView.setContentOffset(CGPoint(x: 0, y: -searchBarHeight + tableView.contentOffset.y), animated: true)
    }

    func applyTheme() {
        loadingView.applyTheme(theme: themeManager.currentTheme)
        tableView.separatorColor = themeManager.currentTheme.colors.borderPrimary
        tableView.backgroundColor = themeManager.currentTheme.colors.layer1
    }
}
