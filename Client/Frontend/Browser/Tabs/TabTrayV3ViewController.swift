/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SnapKit
import UIKit

protocol TabTrayV3Delegate: AnyObject {
    func closeTab(forIndex index: IndexPath)
    func closeTabTray()
}

struct TabTrayV3ControllerUX {
    static let cornerRadius = CGFloat(4.0)
    static let screenshotMarginLeftRight = CGFloat(20.0)
    static let screenshotMarginTopBottom = CGFloat(6.0)
    static let textMarginTopBottom = CGFloat(18.0)
    static let navigationMenuHeight = CGFloat(32.0)
    static let backgroundColor = UIColor.Photon.Grey10
}

class TabTrayV3ViewController: UIViewController, Themeable {
    weak var delegate: TabTrayDelegate?
    // View Model
    lazy var viewModel = TabTrayV3ViewModel(viewController: self)
    let profile: Profile
    private var bottomSheetVC: BottomSheetViewController?
    // Views
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.tableFooterView = UIView()
        tableView.register(TabTableViewCell.self, forCellReuseIdentifier: TabTableViewCell.identifier)
        tableView.register(TabTableViewHeader.self, forHeaderFooterViewReuseIdentifier: sectionHeaderIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsMultipleSelectionDuringEditing = true
        return tableView
    }()
    lazy var emptyPrivateTabsView: EmptyPrivateTabsView = {
        let emptyView = EmptyPrivateTabsView()
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
        let navigationMenu = UISegmentedControl(items: [UIImage(named: "nav-tabcounter")!.overlayWith(image: countLabel), UIImage(named: "smallPrivateMask")!])
        navigationMenu.accessibilityIdentifier = "navBarTabTray"
        navigationMenu.selectedSegmentIndex = viewModel.isInPrivateMode ? 1 : 0
        navigationMenu.addTarget(self, action: #selector(panelChanged), for: .valueChanged)
        return navigationMenu
    }()
    lazy var navigationToolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.delegate = self
        toolbar.setItems([UIBarButtonItem(customView: navigationMenu)], animated: false)
        return toolbar
    }()
    lazy var deleteAllButton: UIBarButtonItem = {
        let deleteAllButton = UIBarButtonItem(image: UIImage.templateImageNamed("action_delete"), style: .plain, target: self, action: #selector(didTapToolbarDelete))
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
    
    init(tabTrayDelegate: TabTrayDelegate? = nil, profile: Profile) {
        self.delegate = tabTrayDelegate
        self.profile = profile
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
            window.backgroundColor = .black
        }
        
        // Navigation bar
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationItem.title = "Open Tabs"
        if #available(iOS 13.0, *) { } else {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: Strings.CloseButtonTitle, style: .done, target: self, action: #selector(dismissTabTray))
            TelemetryWrapper.recordEvent(category: .action, method: .close, object: .tabTray)
        }
        
        // Bottom toolbar
        navigationController?.isToolbarHidden = false
        setToolbarItems(bottomToolbar, animated: false)
        
        // Add Subviews
        view.addSubview(navigationToolbar)
        view.addSubview(tableView)
        view.addSubview(emptyPrivateTabsView)
        viewModel.updateTabs()
        // Constraints
        tableView.snp.makeConstraints { make in
            make.left.equalTo(view.safeArea.left)
            make.right.equalTo(view.safeArea.right)
            make.bottom.equalTo(view)
            make.top.equalTo(navigationToolbar.snp.bottom)
        }
        navigationToolbar.snp.makeConstraints { make in
            make.left.right.equalTo(view)
            make.top.equalTo(view.safeArea.top)
        }
        navigationMenu.snp.makeConstraints { make in
            make.height.equalTo(TabTrayV3ControllerUX.navigationMenuHeight)
        }
        emptyPrivateTabsView.snp.makeConstraints { make in
            make.bottom.left.right.equalTo(view)
            make.top.equalTo(navigationToolbar.snp.bottom)
        }
        
        emptyPrivateTabsView.isHidden = true
        
        bottomSheetVC = BottomSheetViewController()
        bottomSheetVC?.delegate = self
        self.addChild(bottomSheetVC!)
        self.view.addSubview(bottomSheetVC!.view)
    }
    
    func shouldShowPrivateTabsView() {
        emptyPrivateTabsView.isHidden = !viewModel.shouldShowPrivateView
    }

    func applyTheme() {
        if #available(iOS 13.0, *) {
            tableView.backgroundColor = UIColor.systemGroupedBackground
            view.backgroundColor = UIColor.systemGroupedBackground
            navigationController?.navigationBar.tintColor = UIColor.label
            navigationController?.toolbar.tintColor = UIColor.label
            navigationItem.rightBarButtonItem?.tintColor = UIColor.label
            emptyPrivateTabsView.titleLabel.textColor = UIColor.label
            emptyPrivateTabsView.descriptionLabel.textColor = UIColor.secondaryLabel
        } else {
            tableView.backgroundColor = UIColor.theme.tableView.headerBackground
            view.backgroundColor = UIColor.theme.tableView.headerBackground
            tableView.separatorColor = UIColor.theme.tableView.separator
            navigationController?.navigationBar.barTintColor = UIColor.theme.tabTray.toolbar
            navigationController?.navigationBar.tintColor = UIColor.theme.tabTray.toolbarButtonTint
            navigationController?.toolbar.barTintColor = UIColor.theme.tabTray.toolbar
            navigationController?.toolbar.tintColor = UIColor.theme.tabTray.toolbarButtonTint
            navigationToolbar.barTintColor = UIColor.theme.tabTray.toolbar
            navigationToolbar.tintColor = UIColor.theme.tabTray.toolbarButtonTint
            emptyPrivateTabsView.titleLabel.textColor = UIColor.theme.tableView.rowText
            emptyPrivateTabsView.descriptionLabel.textColor = UIColor.theme.tableView.rowDetailText
        }
        setNeedsStatusBarAppearanceUpdate()
        bottomSheetVC?.applyTheme()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        tableView.reloadData()
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
extension TabTrayV3ViewController: UITableViewDataSource {
    
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
        tabCell.remakeTitleConstraint()
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
        default:
            return
        }
    }
}

extension TabTrayV3ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.didSelectRowAt(index: indexPath)
        dismissTabTray()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: sectionHeaderIdentifier) as? TabTableViewHeader, viewModel.numberOfRowsInSection(section: section) != 0 else {
            return nil
        }
        headerView.titleLabel.text = "Section Title"
        headerView.applyTheme()
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == TabSection(rawValue: section)?.rawValue && viewModel.numberOfRowsInSection(section: section) != 0 ? UITableView.automaticDimension : 0
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let share = UIContextualAction(style: .normal, title: Strings.ShareContextMenuTitle, handler: { (action, view, completionHandler) in
            guard let tab = self.viewModel.getTab(forIndex: indexPath), let url = tab.url else { return }
            self.presentActivityViewController(url, tab: tab)
        })
        let more = UIContextualAction(style: .normal, title: Strings.PocketMoreStoriesText, handler: { (action, view, completionHandler) in
            // Bottom toolbar
            self.navigationController?.isToolbarHidden = true

            let moreViewController = TabMoreMenuViewController(tabTrayDelegate: self.delegate, tab: self.viewModel.getTab(forIndex: indexPath), index: indexPath, profile: self.profile)
            moreViewController.tabTrayV3Delegate = self
            moreViewController.bottomSheetDelegate = self
            self.bottomSheetVC?.containerViewController = moreViewController
            self.bottomSheetVC?.showView()

        })
        let delete = UIContextualAction(style: .destructive, title: Strings.CloseButtonTitle, handler: { (action, view, completionHandler) in
            self.viewModel.removeTab(forIndex: indexPath)
        })
        
        share.backgroundColor = UIColor.systemOrange
        share.image = UIImage.templateImageNamed("menu-Send")?.tinted(withColor: .white)
        more.image = UIImage.templateImageNamed("menu-More-Options")?.tinted(withColor: .white)
        delete.image = UIImage.templateImageNamed("menu-CloseTabs")?.tinted(withColor: .white)
        
        let configuration = UISwipeActionsConfiguration(actions: [delete, share, more])
        return configuration
    }
}

extension TabTrayV3ViewController: UIPopoverPresentationControllerDelegate {
    func presentActivityViewController(_ url: URL, tab: Tab? = nil) {
        let helper = ShareExtensionHelper(url: url, tab: tab)

        let controller = helper.createActivityViewController({ _,_ in })

        if let popoverPresentationController = controller.popoverPresentationController {
            popoverPresentationController.sourceView = view
            popoverPresentationController.sourceRect = view.bounds
            popoverPresentationController.permittedArrowDirections = .up
            popoverPresentationController.delegate = self
        }

        present(controller, animated: true, completion: nil)
    }
}

extension TabTrayV3ViewController: UIToolbarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}

extension TabTrayV3ViewController: TabTrayV3Delegate {
    func closeTab(forIndex index: IndexPath) {
        viewModel.removeTab(forIndex: index)
    }
    func closeTabTray() {
        dismissTabTray()
    }
}

extension TabTrayV3ViewController: BottomSheetDelegate {
    func showBottomToolbar() {
        // Show bottom toolbar when we hide bottom sheet
        navigationController?.isToolbarHidden = false
    }
    func closeBottomSheet() {
        showBottomToolbar()
        self.bottomSheetVC?.hideView(shouldAnimate: true)
    }
}

extension TabTrayV3ViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        TelemetryWrapper.recordEvent(category: .action, method: .close, object: .tabTray)
    }
}
