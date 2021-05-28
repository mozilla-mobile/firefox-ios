//
//  CredentialListViewController.swift
//  CredentialProvider
//
//  Created by raluca.iordan on 5/12/21.
//  Copyright © 2021 Mozilla. All rights reserved.
//

import UIKit
import AuthenticationServices

class CredentialListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var dataSource = [(ASPasswordCredentialIdentity, ASPasswordCredential)]() {
        didSet {
            tableView?.reloadData()
        }
    }
    
    private var filteredCredentials = [(ASPasswordCredentialIdentity, ASPasswordCredential)]()
    private var searchController: UISearchController?
    
    private var cancelButton: UIButton {
        let button = UIButton()
        button.setTitle("Cancel", for: .normal)
        button.titleLabel?.font = .navigationButtonFont
        button.accessibilityIdentifier = "cancel.button"
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addConstraint(NSLayoutConstraint(
                                item: button,
                                attribute: .width,
                                relatedBy: .equal,
                                toItem: nil,
                                attribute: .notAnAttribute,
                                multiplier: 1.0,
                                constant: 90))
        button.addTarget(self, action: #selector(self.cancelAction), for: .touchUpInside)
        return button
    }
    
    private var searchIsActive: Bool {
        guard let searchCtr = searchController, searchCtr.isActive && searchCtr.searchBar.text != ""  else {
            return false
        }
        return true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.viewBackground
        setNeedsStatusBarAppearanceUpdate()
        setupTableView()
        styleNavigationBar()
    }
    
    private func shouldHideNavigationBarDuringPresentation() -> Bool {
        return UIDevice.current.userInterfaceIdiom != UIUserInterfaceIdiom.pad
    }
    
    private func setupTableView() {
        let backgroundView = UIView(frame: self.view.bounds)
        backgroundView.backgroundColor = UIColor.viewBackground
        tableView.backgroundView = backgroundView
        tableView.keyboardDismissMode = .onDrag
    }
    
    private func styleNavigationBar() {
        navigationItem.title = "Firefox"
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.accessibilityIdentifier = "firefoxLockwise.navigationBar"
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.navigationTitleFont
        ]
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: cancelButton)
        searchController = self.getStyledSearchController()
        searchController?.delegate = self
        extendedLayoutIncludesOpaqueBars = true // Fixes tapping the status bar from showing partial pull-to-refresh
        navigationController?.iosThirteenNavBarAppearance()
    }
    
    private func getStyledSearchController() -> UISearchController {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = self.shouldHideNavigationBarDuringPresentation()
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.isActive = true
        searchController.searchBar.backgroundColor = UIColor.navBackgroundColor
        searchController.searchBar.tintColor = UIColor.white // Cancel button
        searchController.searchBar.barStyle = .black // White text color
        searchController.searchBar.sizeToFit()
        searchController.searchBar.searchBarStyle = UISearchBar.Style.minimal
        searchController.searchBar.barTintColor = UIColor.clear
        self.navigationItem.searchController = searchController
        self.navigationItem.hidesSearchBarWhenScrolling = false
        self.definesPresentationContext = true
        
        let searchIcon = UIImage(named: "search-icon")?.withRenderingMode(.alwaysTemplate).tinted(UIColor.navSearchPlaceholderTextColor)
        searchController.searchBar.setImage(searchIcon, for: UISearchBar.Icon.search, state: .normal)
        searchController.searchBar.setImage(UIImage(named: "clear-icon"), for: UISearchBar.Icon.clear, state: .normal)
        
        searchController.searchBar.setSearchFieldBackgroundImage(UIImage.color(UIColor.clear, size:  CGSize(width: 50, height: 38)), for: .normal) // Clear the background image
        searchController.searchBar.searchTextPositionAdjustment = UIOffset(horizontal: 5.0, vertical: 0) // calling setSearchFieldBackgroundImage removes the spacing between the search icon and text
        if let searchField = searchController.searchBar.value(forKey: "searchField") as? UITextField {
            if let backgroundview = searchField.subviews.first {
                backgroundview.backgroundColor = UIColor.inactiveNavSearchBackgroundColor
                backgroundview.layer.cornerRadius = 10
                backgroundview.clipsToBounds = true
            }
        }
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = UIColor.white // Set cursor color
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).attributedPlaceholder = NSAttributedString(string: "Search logins", attributes: [NSAttributedString.Key.foregroundColor: UIColor.navSearchPlaceholderTextColor]) // Set the placeholder text and color
        return searchController
    }
    
    private func filterCredentials(for searchText: String) {
        filteredCredentials = dataSource.filter { item in
            item.0.serviceIdentifier.identifier.lowercased().contains(searchText.lowercased())
        }
        tableView.reloadData()
    }
    
    @objc func cancelAction() {
        (navigationController?.parent as? CredentialProviderViewController)?.extensionContext.cancelRequest(withError: NSError(domain: ASExtensionErrorDomain, code: ASExtensionError.userCanceled.rawValue))
    }
}

extension CredentialListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if dataSource.isEmpty || (searchIsActive && filteredCredentials.isEmpty)  {
            return 1
        } else {
            return 2
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if dataSource.isEmpty || (searchIsActive && filteredCredentials.isEmpty) {
            return 1
        } else {
            switch section {
            case 0:
                return 1
            case 1:
                if searchIsActive {
                    return filteredCredentials.count
                } else {
                    return dataSource.count
                }
            default:
                return 1
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if dataSource.isEmpty {
            let cell = tableView.dequeueReusableCell(withIdentifier: "emptylistplaceholder", for: indexPath) as? EmptyPlaceholderCell
            return cell ?? UITableViewCell()
        } else if searchIsActive && filteredCredentials.isEmpty {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "noresultsplaceholder") else {
                return UITableViewCell()
            }
            return cell
        } else {
            switch indexPath.section {
            case 0:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "selectapasswordhelptext") else {
                    return UITableViewCell()
                }
                
                let borderView = UIView()
                borderView.frame = CGRect(x: 0, y: cell.frame.height-1, width: cell.frame.width, height: 1)
                borderView.backgroundColor = UIColor.helpTextBorderColor
                cell.addSubview(borderView)
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "itemlistcell", for: indexPath) as? ItemListCell
                var credential: ASPasswordCredentialIdentity
                if let searchCtr = searchController, searchCtr.isActive && searchCtr.searchBar.text != "" {
                    credential = filteredCredentials[indexPath.row].0
                } else {
                    credential = dataSource[indexPath.row].0
                }
                cell?.titleLabel.text = credential.serviceIdentifier.identifier
                cell?.detailLabel.text = credential.user
                return cell ?? UITableViewCell()
            default:
                return UITableViewCell()
            }
        }
    }
}

extension CredentialListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 1:
            var passwordCredential: ASPasswordCredential
            if searchIsActive {
                passwordCredential = filteredCredentials[indexPath.row].1
            } else {
                passwordCredential = dataSource[indexPath.row].1
            }
            (navigationController?.parent as? CredentialProviderViewController)?.extensionContext.completeRequest(withSelectedCredential: passwordCredential, completionHandler: nil)
        default:
            break
        }
    }
}

extension CredentialListViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        if let searchField = searchController.searchBar.value(forKey: "searchField") as? UITextField {
            if let backgroundview = searchField.subviews.first {
                backgroundview.backgroundColor = UIColor.activeNavSearchBackgroundColor
            }
        }
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        if let searchField = searchController.searchBar.value(forKey: "searchField") as? UITextField {
            
            if let backgroundview = searchField.subviews.first {
                backgroundview.backgroundColor = UIColor.inactiveNavSearchBackgroundColor
            }
        }
    }
}

extension CredentialListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterCredentials(for: searchController.searchBar.text ?? "")
    }
}
