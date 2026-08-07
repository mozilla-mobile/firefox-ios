// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import Common

final class WebsiteDataManagementViewController: UIViewController,
                                           UITableViewDataSource,
                                           UITableViewDelegate,
                                           UISearchBarDelegate,
                                           Themeable {
    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: NotificationProtocol
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }
    private static let showMoreCellReuseIdentifier = "showMoreCell"
    private struct UX {
        static let sectionTopMargin: CGFloat = 10
        static var tableViewStyleForCurrentOS: UITableView.Style {
            guard #available(iOS 26.0, *) else { return .grouped }
            return .insetGrouped
        }
        static var shouldShowSectionBorders: Bool {
            guard #available(iOS 26.0, *) else { return true }
            return false
        }
        static var sectionTopMarginForCurrentOS: CGFloat {
            guard #available(iOS 26.0, *) else { return 0 }
            return UX.sectionTopMargin
        }
    }
    private enum Section: Int {
        case sites = 0
        case showMore = 1
        case clearButton = 2

        static let count = 3
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.themeManager = themeManager
        self.windowUUID = windowUUID
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
    }

    fileprivate let loadingView = SettingsLoadingView()

    fileprivate var showMoreButton: ThemedTableViewCell?

    private let viewModel = WebsiteDataManagementViewModel()

    var tableView: UITableView?
    var searchController: UISearchController?

    private lazy var searchResultsViewController = WebsiteDataSearchResultsViewController(viewModel: viewModel,
                                                                                          windowUUID: windowUUID)

    private func currentTheme() -> Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }

    /// Number of records shown before the user taps "Show More": either 10, 8 or 6 depending on the screen size.
    private var numberOfInitialRecords: Int {
        let height = max(view.frame.width, view.frame.height)
        return height > 667 ? 10 : height > 568 ? 8 : 6
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()

        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()
    }

    private func setupView() {
        title = .SettingsWebsiteDataTitle

        let tableView = UITableView(
            frame: .zero,
            style: UX.tableViewStyleForCurrentOS
        )
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorColor = currentTheme().colors.borderPrimary
        tableView.backgroundColor = currentTheme().colors.layer1
        tableView.isEditing = true
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.allowsSelectionDuringEditing = true
        tableView.register(ThemedTableViewCell.self, forCellReuseIdentifier: ThemedTableViewCell.cellIdentifier)
        tableView.register(
            ThemedTableViewCell.self,
            forCellReuseIdentifier: WebsiteDataManagementViewController.showMoreCellReuseIdentifier
        )
        tableView.register(cellType: ThemedTableViewCell.self)
        tableView.register(cellType: ThemedCenteredTableViewCell.self)
        tableView.register(
            ThemedTableSectionHeaderFooterView.self,
            forHeaderFooterViewReuseIdentifier: ThemedTableSectionHeaderFooterView.cellIdentifier
        )

        let footer = ThemedTableSectionHeaderFooterView(
            frame: CGRect(width: tableView.bounds.width,
                          height: SettingsUX.TableViewHeaderFooterHeight)
        )
        footer.applyTheme(theme: currentTheme())
        footer.showBorder(for: .top, UX.shouldShowSectionBorders)
        tableView.tableFooterView = footer

        view.addSubview(tableView)
        view.addSubview(loadingView)
        loadingView.applyTheme(theme: currentTheme())

        tableView.translatesAutoresizingMaskIntoConstraints = false
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            loadingView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        viewModel.onViewModelChanged = { [weak self] in
            guard let self else { return }
            loadingView.isHidden = viewModel.state != .loading
            searchResultsViewController.reloadData()
            reloadTableView()
        }

        viewModel.onSelectionChanged = { [weak self] in
            guard let self else { return }
            syncSelectedRows()
            updateClearButtonTitle()
            searchResultsViewController.selectionDidChange()
        }

        viewModel.loadAllWebsiteData()

        let searchController = UISearchController(searchResultsController: searchResultsViewController)

        // No need to hide the navigation bar on iPad, on iPhone the additional height is useful.
        searchController.hidesNavigationBarDuringPresentation = UIDevice.current.userInterfaceIdiom != .pad

        searchController.searchResultsUpdater = searchResultsViewController
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = .SettingsFilterSitesSearchLabel
        searchController.searchBar.delegate = self
        searchController.searchBar.barStyle = currentTheme().type.getBarStyle()

        if #unavailable(iOS 26.0) {
            navigationItem.hidesSearchBarWhenScrolling = false
        }

        navigationItem.searchController = searchController
        self.searchController = searchController
        self.tableView = tableView

        definesPresentationContext = true
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = Section(rawValue: indexPath.section)!
        switch section {
        case .sites:
            let cell = dequeueCellFor(indexPath: indexPath)
            cell.applyTheme(theme: currentTheme())
            if let record = viewModel.siteRecords[safe: indexPath.row] {
                cell.textLabel?.text = record.displayName
            }
            let cellViewModel = ThemedTableViewCellViewModel(
                theme: currentTheme(),
                type: .standard
            )
            cell.configure(viewModel: cellViewModel)
            return cell
        case .showMore:
            let cell = dequeueCellFor(indexPath: indexPath)
            let cellType: ThemedTableViewCellType = viewModel.state != .displayAll ? .actionPrimary : .disabled
            let cellViewModel = ThemedTableViewCellViewModel(
                theme: currentTheme(),
                type: cellType
            )
            cell.textLabel?.text = .SettingsWebsiteDataShowMoreButton
            cell.accessibilityTraits = UIAccessibilityTraits.button
            cell.accessibilityIdentifier = "ShowMoreWebsiteData"
            cell.configure(viewModel: cellViewModel)
            cell.applyTheme(theme: currentTheme())
            showMoreButton = cell
            return cell
        case .clearButton:
            let cell = dequeueCellFor(indexPath: indexPath) as? ThemedCenteredTableViewCell
            cell?.setTitle(to: viewModel.clearButtonTitle)
            cell?.setAccessibilities(
                traits: .button,
                identifier: AccessibilityIdentifiers.Settings.ClearData.clearAllWebsiteData)
            cell?.applyTheme(theme: currentTheme())
            return cell ?? ThemedCenteredTableViewCell()
        }
    }

    private func dequeueCellFor(indexPath: IndexPath) -> ThemedTableViewCell {
        guard let section = Section(rawValue: indexPath.section) else {
            return ThemedTableViewCell()
        }
        switch section {
        case .sites:
            guard let cell = tableView?.dequeueReusableCell(
                withIdentifier: ThemedTableViewCell.cellIdentifier,
                for: indexPath
            ) as? ThemedTableViewCell
            else {
                return ThemedTableViewCell()
            }
            return cell
        case .showMore:
            guard let cell = tableView?.dequeueReusableCell(
                withIdentifier: WebsiteDataManagementViewController.showMoreCellReuseIdentifier,
                for: indexPath
            ) as? ThemedTableViewCell
            else {
                return ThemedTableViewCell()
            }
            return cell
        case .clearButton:
            guard let cell = tableView?.dequeueReusableCell(
                withIdentifier: ThemedCenteredTableViewCell.cellIdentifier,
                for: indexPath
            ) as? ThemedCenteredTableViewCell
            else {
                return ThemedCenteredTableViewCell()
            }
            return cell
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = Section(rawValue: section)!

        switch section {
        case .sites:
            let numberOfRecords = viewModel.siteRecords.count
            return viewModel.state == .displayAll ? numberOfRecords: min(numberOfRecords, numberOfInitialRecords)
        case .showMore:
            return (viewModel.state != .displayAll && viewModel.siteRecords.count > numberOfInitialRecords) ? 1 : 0
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
        case .showMore:
            expandSiteRecords(replacing: indexPath)
        case .clearButton:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
            let alert = viewModel.createAlertToRemove()
            present(alert, animated: true, completion: nil)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let section = Section(rawValue: indexPath.section)!
        switch section {
        case .sites:
            guard let item = viewModel.siteRecords[safe: indexPath.row] else { return }
            viewModel.deselectItem(item)
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

    private func expandSiteRecords(replacing showMoreIndexPath: IndexPath) {
        guard let tableView else { return }
        let sitesSection = Section.sites.rawValue
        let previousRowCount = tableView.numberOfRows(inSection: sitesSection)

        viewModel.showMoreButtonPressed()

        let expandedRowCount = viewModel.siteRecords.count
        guard expandedRowCount > previousRowCount else {
            // Safeguard: not expected to happen, but if the records shrank since the tableView last queried the
            // data source, the range below would trap. Reloading is safe in that case.
            reloadTableView()
            return
        }

        tableView.performBatchUpdates {
            tableView.insertRows(
                at: (previousRowCount..<expandedRowCount).map { IndexPath(row: $0, section: sitesSection) },
                with: .none
            )
            tableView.deleteRows(at: [showMoreIndexPath], with: .none)
        }
        syncSelectedRows()
    }

    private func reloadTableView() {
        tableView?.reloadData()
        syncSelectedRows()
    }

    /// Aligns the tableView's selected rows with the view model.
    private func syncSelectedRows() {
        guard let tableView else { return }
        let section = Section.sites.rawValue
        // Snapshot the selection once, so each row below is a lookup instead of a fresh query on the table view.
        let selectedIndexPaths = Set(tableView.indexPathsForSelectedRows ?? [])

        // Only the rows the tableView currently knows about, which is fewer than `siteRecords` while truncated.
        for row in 0..<tableView.numberOfRows(inSection: section) {
            guard let record = viewModel.siteRecords[safe: row] else { continue }
            let indexPath = IndexPath(row: row, section: section)
            let isSelectedInTableView = selectedIndexPaths.contains(indexPath)

            if viewModel.selectedRecords.contains(record) {
                // Already selected, so leave it alone: reselecting forces a redundant layout pass and a visible blink.
                guard !isSelectedInTableView else { continue }
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            } else if isSelectedInTableView {
                // Stale checkmark left over from a reload or a reused cell.
                tableView.deselectRow(at: indexPath, animated: false)
            }
        }
    }

    private func updateClearButtonTitle() {
        let indexPath = IndexPath(row: 0, section: Section.clearButton.rawValue)
        guard let cell = tableView?.cellForRow(at: indexPath) as? ThemedCenteredTableViewCell else { return }
        cell.setTitle(to: viewModel.clearButtonTitle)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: ThemedTableSectionHeaderFooterView.cellIdentifier
        ) as? ThemedTableSectionHeaderFooterView else { return nil }

        headerView.titleLabel.text = section == Section.sites.rawValue ? .SettingsWebsiteDataTitle : nil

        headerView.showBorder(for: .top, UX.shouldShowSectionBorders)
        headerView.showBorder(for: .bottom, UX.shouldShowSectionBorders)

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
            headerView.showBorder(for: .bottom, UX.shouldShowSectionBorders)
        }

        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let section = Section(rawValue: section)!
        switch section {
        case .clearButton:
            return UX.sectionTopMargin // Controls the space between the site list and the button
        case .sites:
            return UITableView.automaticDimension
        case .showMore:
            return UX.sectionTopMarginForCurrentOS
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footerView = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: ThemedTableSectionHeaderFooterView.cellIdentifier
        ) as? ThemedTableSectionHeaderFooterView else { return nil }

        footerView.showBorder(for: .top, UX.shouldShowSectionBorders)
        footerView.showBorder(for: .bottom, UX.shouldShowSectionBorders)
        return footerView
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    func applyTheme() {
        loadingView.applyTheme(theme: currentTheme())
        tableView?.separatorColor = currentTheme().colors.borderPrimary
        tableView?.backgroundColor = currentTheme().colors.layer1
    }
}
