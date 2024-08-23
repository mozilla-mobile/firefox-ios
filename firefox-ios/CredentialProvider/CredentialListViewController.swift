// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import AuthenticationServices
import Common

protocol CredentialListViewProtocol: AnyObject {
    var credentialExtensionContext: ASCredentialProviderExtensionContext? { get }
    var searchIsActive: Bool { get }
}

class CredentialListViewController: UIViewController, CredentialListViewProtocol, UISearchControllerDelegate {
    fileprivate let cellIdentifier = "cellidentifier"
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.CredentialProvider.tableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableFooterView = UIView()
        return tableView
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.system)
        button.setTitle(.LoginsListSearchCancel, for: .normal)
        button.titleLabel?.font = .navigationButtonFont
        button.accessibilityIdentifier = "cancel.button"
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(self.cancelAction), for: .touchUpInside)
        return button
    }()

    var dataSource = [(ASPasswordCredentialIdentity, ASPasswordCredential)]() {
        didSet {
            presenter?.loginsData = dataSource
            tableView.reloadData()
        }
    }

    private var presenter: CredentialListPresenter?
    private var searchController: UISearchController?

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    var searchIsActive: Bool {
        guard let searchCtr = searchController,
              let searchBarText = searchCtr.searchBar.text,
              searchCtr.isActive && !searchBarText.isEmpty
        else { return false }

        return true
    }

    var credentialExtensionContext: ASCredentialProviderExtensionContext? {
        return (navigationController?.parent as? CredentialProviderViewController)?.extensionContext
    }

    init() {
        super.init(nibName: nil, bundle: nil)
        self.presenter = CredentialListPresenter(view: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate()
        styleNavigationBar()
        addViewConstraints()
        registerCells()
    }

    private func styleNavigationBar() {
        navigationItem.title = "Firefox"
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.accessibilityIdentifier = "firefox.navigationBar"
        navigationController?.navigationBar.titleTextAttributes = [
            .font: UIFont.navigationTitleFont
        ]
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: cancelButton)
        searchController = self.getStyledSearchController()
        searchController?.delegate = self
        extendedLayoutIncludesOpaqueBars = true // Fixes tapping the status bar from showing partial pull-to-refresh

        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
    }

    private func getStyledSearchController() -> UISearchController {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.isActive = true
        searchController.searchBar.sizeToFit()
        searchController.searchBar.searchBarStyle = UISearchBar.Style.minimal
        self.navigationItem.searchController = searchController
        self.navigationItem.hidesSearchBarWhenScrolling = false
        self.definesPresentationContext = true

        let searchIcon = UIImage(named: StandardImageIdentifiers.Large.search)?
            .withRenderingMode(.alwaysTemplate)
            .tinted(UIColor.systemBlue)
        let clearIcon = UIImage(named: StandardImageIdentifiers.Large.crossCircleFill)?
            .withRenderingMode(.alwaysTemplate)
            .tinted(UIColor.systemBlue)
        searchController.searchBar.setImage(searchIcon, for: UISearchBar.Icon.search, state: .normal)
        searchController.searchBar.setImage(clearIcon, for: UISearchBar.Icon.clear, state: .normal)

        // calling setSearchFieldBackgroundImage removes the spacing between the search icon and text
        searchController.searchBar.searchTextPositionAdjustment = UIOffset(horizontal: 5.0, vertical: 0)
        if let searchField = searchController.searchBar.value(forKey: "searchField") as? UITextField {
            if let backgroundview = searchField.subviews.first {
                backgroundview.layer.cornerRadius = 10
                backgroundview.clipsToBounds = true
            }
        }
        UITextField
            .appearance(
                whenContainedInInstancesOf: [UISearchBar.self]).attributedPlaceholder = NSAttributedString(
                    string: .LoginsListSearchPlaceholderCredential,
                    attributes: [:]) // Set the placeholder text and color
        return searchController
    }

    private func addViewConstraints() {
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),

            cancelButton.widthAnchor.constraint(equalToConstant: 60)
        ])
    }

    private func registerCells() {
        tableView.register(ItemListCell.self, forCellReuseIdentifier: ItemListCell.identifier)
        tableView.register(SelectPasswordCell.self, forCellReuseIdentifier: SelectPasswordCell.identifier)
        tableView.register(NoSearchResultCell.self, forCellReuseIdentifier: NoSearchResultCell.identifier)
        tableView.register(EmptyPlaceholderCell.self, forCellReuseIdentifier: EmptyPlaceholderCell.identifier)
    }

    @objc
    func cancelAction() {
        presenter?.cancelRequest()
    }
}

extension CredentialListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        guard let presenter = presenter else { return 1 }
        return presenter.numberOfSections()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let presenter = presenter else { return 1 }
        return presenter.numberOfRows(for: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch presenter?.getItemsType(in: indexPath.section, for: indexPath.row) {
        case .emptyCredentialList:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: EmptyPlaceholderCell.identifier,
                for: indexPath
            ) as? EmptyPlaceholderCell
            return cell ?? UITableViewCell()
        case .emptySearchResult:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: NoSearchResultCell.identifier,
                for: indexPath
            ) as? NoSearchResultCell
            return cell ?? UITableViewCell()
        case .selectPassword:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: SelectPasswordCell.identifier,
                for: indexPath
            ) as? SelectPasswordCell else {
                return UITableViewCell()
            }
            return cell
        case .displayItem(let credentialIdentity):
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ItemListCell.identifier,
                for: indexPath
            ) as? ItemListCell
            cell?.titleLabel.text = credentialIdentity.serviceIdentifier.identifier.titleFromHostname
            cell?.detailLabel.text = credentialIdentity.user
            let backgroundView = UIView()
            backgroundView.backgroundColor = UIColor.lightGray
            cell?.selectedBackgroundView = backgroundView
            return cell ?? UITableViewCell()
        case .none:
            return UITableViewCell()
        }
    }
}

extension CredentialListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            presenter?.selectItem(for: indexPath.row)
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch presenter?.getItemsType(in: indexPath.section, for: indexPath.row) {
        case .emptyCredentialList:
            return 200
        case .emptySearchResult:
            return 300
        case .selectPassword, .displayItem:
            return 55
        case .none:
            return 44
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if  let searchBar = searchController?.searchBar, searchBar.isFirstResponder {
            searchBar.resignFirstResponder()
        }
    }
}

extension CredentialListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        presenter?.filterCredentials(for: searchController.searchBar.text ?? "")
        tableView.reloadData()
    }
}
