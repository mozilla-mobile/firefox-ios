/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SnapKit
import UIKit

struct TabTrayV2ControllerUX {
    static let cornerRadius = CGFloat(4.0)
    static let screenshotMarginLeftRight = CGFloat(20.0)
    static let screenshotMarginTopBottom = CGFloat(6.0)
    static let textMarginTopBottom = CGFloat(18.0)
    static let navigationMenuHeight = CGFloat(32.0)
    static let backgroundColor = UIColor.Photon.Grey10
}

class TabTrayV2ViewController: UIViewController, Themeable {
    // View Model
    lazy var viewModel = TabTrayV2ViewModel(viewController: self)
    // Views
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.tableFooterView = UIView()
        tableView.register(TabTableViewCell.self, forCellReuseIdentifier: TabTableViewCell.identifier)
        tableView.register(ThemedTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: sectionHeaderIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
    lazy var emptyPrivateTabsView: EmptyPrivateTabsView = {
        let emptyView = EmptyPrivateTabsView()
        emptyView.titleLabel.textColor = .black
        emptyView.descriptionLabel.textColor = .black
        emptyView.learnMoreButton.addTarget(self, action: #selector(didTapLearnMore), for: .touchUpInside)
        return emptyView
    }()
    lazy var countLabel: UILabel = {
        let label = UILabel(frame: CGRect(width: 24, height: 24))
        label.font = TabsButtonUX.TitleFont
        label.layer.cornerRadius = TabsButtonUX.CornerRadius
        label.textAlignment = .center
        label.text = String(viewModel.countOfNormalTabs())
        return label
    }()
    lazy var navigationMenu: UISegmentedControl = {
        let navigationMenu = UISegmentedControl(items: [UIImage(named: "nav-tabcounter")!.overlayWith(image: countLabel), UIImage(named: "smallPrivateMask")!, UIImage(named:"panelIconSyncedTabs")!])
        navigationMenu.backgroundColor = UIColor.Photon.Grey10
        navigationMenu.selectedSegmentIndex = viewModel.isInPrivateMode ? 1 : 0
        navigationMenu.addTarget(self, action: #selector(panelChanged), for: .valueChanged)
        return navigationMenu
    }()
    lazy var deleteAllButton: UIBarButtonItem = {
        let deleteAllButton = UIBarButtonItem(image: UIImage.templateImageNamed("action_delete"), style: .plain, target: self, action: #selector(didTapToolbarDelete))
        deleteAllButton.tintColor = UIColor.Photon.Grey90A80
        deleteAllButton.accessibilityIdentifier = "closeAllTabsButtonTabTray"
        return deleteAllButton
    }()
    lazy var newTabButton: UIBarButtonItem = {
        let newTabButton = UIBarButtonItem(customView: NewTabButton(target: self, selector: #selector(didTapToolbarAddTab)))
        newTabButton.accessibilityIdentifier = "newTabButtonTabTray"
        return newTabButton
    }()
    lazy var bottomToolbar: [UIBarButtonItem] = {
        let bottomToolbar = [
            deleteAllButton,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            newTabButton
        ]
        return bottomToolbar
    }()
    
    // Constants
    fileprivate let sectionHeaderIdentifier = "SectionHeader"
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        viewSetup()
        applyTheme()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.addPrivateTab()
    }
    
    private func viewSetup() {
        // MARK: TODO - Theme setup setup
        if let window = (UIApplication.shared.delegate?.window)! as UIWindow? {
            window.backgroundColor = UIColor.Photon.Grey90A90
        }
        
        // Navigation bar
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.backgroundColor = TabTrayV2ControllerUX.backgroundColor
        navigationItem.title = Strings.TabTrayV2Title
        if #available(iOS 13.0, *) { } else {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: Strings.CloseButtonTitle, style: .done, target: self, action: #selector(dismissTabTray))
        }
        
        // Bottom toolbar
        navigationController?.isToolbarHidden = false
        setToolbarItems(bottomToolbar, animated: false)
        
        // Add Subviews
        let navMenuContainer = UIView()
        navMenuContainer.backgroundColor = TabTrayV2ControllerUX.backgroundColor
        view.addSubview(navMenuContainer)
        navMenuContainer.addSubview(navigationMenu)
        view.addSubview(tableView)
        view.addSubview(emptyPrivateTabsView)
        viewModel.updateTabs()
        // Constraints
        tableView.snp.makeConstraints { make in
            make.left.equalTo(view.safeArea.left)
            make.right.equalTo(view.safeArea.right)
            make.bottom.equalTo(view)
            make.top.equalTo(navMenuContainer.snp.bottom)
        }
        navMenuContainer.snp.makeConstraints { make in
            make.left.right.equalTo(view)
            make.top.equalTo(view.safeArea.top)
            make.height.equalTo(TabTrayV2ControllerUX.navigationMenuHeight)
        }
        navigationMenu.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
        emptyPrivateTabsView.snp.makeConstraints { make in
            make.bottom.left.right.equalTo(view)
            make.top.equalTo(navMenuContainer.snp.bottom)
        }
        
        emptyPrivateTabsView.isHidden = true
    }
    
    func shouldShowPrivateTabsView() {
        emptyPrivateTabsView.isHidden = !viewModel.shouldShowPrivateView
    }

    func applyTheme() {
        tableView.backgroundColor = UIColor.theme.tableView.headerBackground
        setNeedsStatusBarAppearanceUpdate()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if ThemeManager.instance.systemThemeIsOn {
                tableView.reloadData()
            }
        }
    }
}

// MARK: Datastore
extension TabTrayV2ViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        shouldShowPrivateTabsView()
        return viewModel.numberOfSections()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRowsInSection(section: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TabTableViewCell.identifier, for: indexPath)
        guard let tabCell = cell as? TabTableViewCell else { return cell }
        tabCell.closeButton.addTarget(self, action: #selector(onCloseButton(_ :)), for: .touchUpInside)
        tabCell.separatorInset = UIEdgeInsets.zero
        
        viewModel.configure(cell: tabCell, for: indexPath)
        
        return tabCell
    }
    
    @objc func onCloseButton(_ sender: UIButton) {
        let buttonPosition = sender.convert(CGPoint(), to: tableView)
        if let indexPath = tableView.indexPathForRow(at: buttonPosition) {
            viewModel.removeTab(forIndex: indexPath)
        }
    }
    
    @objc func didTapToolbarAddTab(_ sender: UIBarButtonItem) {
        viewModel.addTab()
        dismissTabTray()
        TelemetryWrapper.recordEvent(category: .action, method: .add, object: .tab, value: viewModel.isInPrivateMode ? .privateTab : .normalTab)
    }
    
    @objc func didTapToolbarDelete(_ sender: UIButton) {
        let controller = AlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        controller.addAction(UIAlertAction(title: Strings.AppMenuCloseAllTabsTitleString, style: .default, handler: { _ in self.viewModel.closeTabsForCurrentTray() }), accessibilityIdentifier: "TabTrayController.deleteButton.closeAll")
        controller.addAction(UIAlertAction(title: Strings.CancelString, style: .cancel, handler: nil), accessibilityIdentifier: "TabTrayController.deleteButton.cancel")
        controller.popoverPresentationController?.sourceView = sender
        controller.popoverPresentationController?.sourceRect = sender.bounds
        present(controller, animated: true, completion: nil)
        TelemetryWrapper.recordEvent(category: .action, method: .deleteAll, object: .tab, value: viewModel.isInPrivateMode ? .privateTab : .normalTab)
    }
    
    func didTogglePrivateMode(_ togglePrivateModeOn: Bool) {
        // Toggle private mode
        viewModel.togglePrivateMode(togglePrivateModeOn)
        
        // Reload data
        viewModel.updateTabs()
    }
    
    func hideDisplayedTabs( completion: @escaping () -> Void) {
           let cells = tableView.visibleCells

           UIView.animate(withDuration: 0.2,
                          animations: {
                               cells.forEach {
                                   $0.alpha = 0
                               }
                           }, completion: { _ in
                               cells.forEach {
                                   $0.alpha = 1
                                   $0.isHidden = true
                               }
                               completion()
                           })
       }

    @objc func dismissTabTray() {
        // We check if there is private tab then add one if user dismisses
        viewModel.addPrivateTab()
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapLearnMore() {
        if let privateBrowsingUrl = SupportUtils.URLForTopic("private-browsing-ios") {
            let learnMoreRequest = URLRequest(url: privateBrowsingUrl)
            viewModel.addTab(learnMoreRequest)
        }
        self.dismissTabTray()
    }
    
    @objc func panelChanged() {
        switch navigationMenu.selectedSegmentIndex {
        case 0:
            didTogglePrivateMode(false)
        case 1:
            didTogglePrivateMode(true)
        case 2:
            return
        default:
            return
        }
    }
}

extension TabTrayV2ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.didSelectRowAt(index: indexPath)
        dismissTabTray()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: sectionHeaderIdentifier) as? ThemedTableSectionHeaderFooterView, viewModel.numberOfRowsInSection(section: section) != 0 else {
            return nil
        }
        headerView.titleLabel.text = viewModel.getSectionDateHeader(section)
        headerView.applyTheme()
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == TabSection(rawValue: section)?.rawValue && viewModel.numberOfRowsInSection(section: section) != 0 ? UITableView.automaticDimension : 0
    }
}
