// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Storage
import Shared
import SiteImageView

/// This ViewController is meant to show a tableView of STG items in a flat list with NO section headers.
/// When we have coordinators, where the coordinator provides the VM to the VC, we can generalize this.
final class SearchGroupedItemsViewController: UIViewController, UITableViewDelegate, Themeable {
    // MARK: - Properties

    typealias a11y = AccessibilityIdentifiers.LibraryPanels.GroupedList

    enum Sections: CaseIterable {
        case main
    }

    let profile: Profile
    let viewModel: SearchGroupedItemsViewModel
    weak var libraryPanelDelegate: LibraryPanelDelegate?
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol
    private var logger: Logger

    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

    private lazy var tableView: UITableView = .build { [weak self] tableView in
        guard let self = self else { return }
        tableView.dataSource = self.diffableDatasource
        tableView.accessibilityIdentifier = a11y.tableView
        tableView.delegate = self
        tableView.register(
            OneLineTableViewCell.self,
            forCellReuseIdentifier: OneLineTableViewCell.cellIdentifier
        )
        tableView.register(
            TwoLineImageOverlayCell.self,
            forCellReuseIdentifier: TwoLineImageOverlayCell.cellIdentifier
        )

        tableView.sectionHeaderTopPadding = 0
    }

    private lazy var doneButton: UIBarButtonItem =  {
        let button = UIBarButtonItem(
            title: String.AppSettingsDone,
            style: .done,
            target: self,
            action: #selector(doneButtonAction)
        )
        button.accessibilityIdentifier = "ShowGroupDoneButton"
        return button
    }()

    private var diffableDatasource: UITableViewDiffableDataSource<Sections, Site>?

    // MARK: - Inits

    init(viewModel: SearchGroupedItemsViewModel,
         profile: Profile,
         windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         logger: Logger = DefaultLogger.shared) {
        self.viewModel = viewModel
        self.profile = profile
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.logger = logger

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycles

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
        configureDatasource()

        listenForThemeChange(view)
        applyTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        applySnapshot()
    }

    // MARK: - Misc. helpers

    private func setupLayout() {
        // This View needs to be configured a certain way based on who's presenting it.
        switch viewModel.presenter {
        case .recentlyVisited:
            title = viewModel.asGroup.displayTitle
            navigationItem.rightBarButtonItem = doneButton
        default: break
        }

        // Adding subviews and constraints
        view.addSubviews(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }

    // MARK: - TableView datasource helpers

    private func configureDatasource() {
        // swiftlint:disable line_length
        diffableDatasource = UITableViewDiffableDataSource<Sections, Site>(tableView: tableView) { [weak self] (tableView, indexPath, item) -> UITableViewCell? in
        // swiftlint:enable line_length
            guard let self = self else { return nil }

            let site = item
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TwoLineImageOverlayCell.cellIdentifier,
                                                           for: indexPath) as? TwoLineImageOverlayCell
            else {
                self.logger.log("GeneralizedHistoryItems - Could not dequeue a TwoLineImageOverlayCell",
                                level: .debug,
                                category: .library)
                return nil
            }
            let totalRows = tableView.numberOfRows(inSection: indexPath.section)
            cell.addCustomSeparator(
                atTop: indexPath.row == 0,
                atBottom: indexPath.row == totalRows - 1
            )
            cell.titleLabel.text = site.title
            cell.titleLabel.isHidden = site.title.isEmpty
            cell.descriptionLabel.text = site.url
            cell.descriptionLabel.isHidden = false
            cell.leftImageView.layer.borderWidth = 0.5
            cell.leftImageView.setFavicon(FaviconImageViewModel(siteURLString: site.url))
            cell.applyTheme(theme: self.themeManager.getCurrentTheme(for: windowUUID))

            return cell
        }
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Sections, Site>()

        snapshot.appendSections(Sections.allCases)

        snapshot.appendItems(viewModel.asGroup.groupedItems, toSection: .main)

        diffableDatasource?.apply(snapshot, animatingDifferences: true)
    }

    // MARK: - Misc. helpers

    @objc
    private func doneButtonAction() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = diffableDatasource?.itemIdentifier(for: indexPath) else { return }

        handleSiteItemTapped(site: item)
    }

    private func handleSiteItemTapped(site: Site) {
        guard let url = URL(string: site.url, invalidCharacters: false) else {
            logger.log("Couldn't navigate to site",
                       level: .warning,
                       category: .library)
            return
        }

        libraryPanelDelegate?.libraryPanel(didSelectURL: url, visitType: .typed)

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .selectedHistoryItem,
                                     value: .historyPanelGroupedItem,
                                     extras: nil)

        if viewModel.presenter == .recentlyVisited {
            dismiss(animated: true, completion: nil)
        }
    }

    // MARK: - Themeable

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        tableView.backgroundColor = theme.colors.layer1
        view.backgroundColor = theme.colors.layer1
        tableView.separatorColor = theme.colors.borderPrimary
    }
}
