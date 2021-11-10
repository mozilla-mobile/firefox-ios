// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import SnapKit
import UIKit

protocol ChronologicalTabsDelegate: AnyObject {
    func closeTab(forIndex index: IndexPath)
    func closeTabTray()
}

struct ChronologicalTabsControllerUX {
    static let cornerRadius = CGFloat(4.0)
    static let screenshotMarginLeftRight = CGFloat(20.0)
    static let screenshotMarginTopBottom = CGFloat(6.0)
    static let textMarginTopBottom = CGFloat(18.0)
    static let navigationMenuHeight = CGFloat(32.0)
    static let backgroundColor = UIColor.Photon.Grey10
}

class ChronologicalTabsViewController: UIViewController, NotificationThemeable, TabTrayViewDelegate {
    weak var delegate: TabTrayDelegate?
    // View Model
    lazy var viewModel = TabTrayV2ViewModel(viewController: self)
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
        // Add Subviews
        view.addSubview(tableView)
        view.addSubview(emptyPrivateTabsView)
        viewModel.updateTabs()
        // Constraints
        tableView.snp.makeConstraints { make in
            make.left.equalTo(view.safeArea.left)
            make.right.equalTo(view.safeArea.right)
            make.bottom.equalTo(view)
            make.top.equalTo(view)
        }
        emptyPrivateTabsView.snp.makeConstraints { make in
            make.bottom.left.right.equalTo(view)
            make.top.equalTo(view)
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
        tableView.backgroundColor = UIColor.systemGroupedBackground
        emptyPrivateTabsView.titleLabel.textColor = UIColor.label
        emptyPrivateTabsView.descriptionLabel.textColor = UIColor.secondaryLabel

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

        if LegacyThemeManager.instance.systemThemeIsOn {
            tableView.reloadData()
        }
    }
}

// MARK: - Toolbar Actions
extension ChronologicalTabsViewController {
    func performToolbarAction(_ action: TabTrayViewAction, sender: UIBarButtonItem) {
        switch action {
        case .addTab:
            didTapToolbarAddTab()
        case .deleteTab:
            didTapToolbarDelete(sender)
        }
    }

    func didTapToolbarAddTab() {
        viewModel.addTab()
        dismissTabTray()
        TelemetryWrapper.recordEvent(category: .action, method: .add, object: .tab, value: viewModel.isInPrivateMode ? .privateTab : .normalTab)
    }

    func didTapToolbarDelete(_ sender: UIBarButtonItem) {
        let controller = AlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        controller.addAction(UIAlertAction(title: .AppMenuCloseAllTabsTitleString,
                                           style: .default,
                                           handler: { _ in self.viewModel.closeTabsForCurrentTray() }),
                             accessibilityIdentifier: AccessibilityIdentifiers.TabTray.deleteCloseAllButton)
        controller.addAction(UIAlertAction(title: .CancelString,
                                           style: .cancel,
                                           handler: nil),
                             accessibilityIdentifier: AccessibilityIdentifiers.TabTray.deleteCancelButton)
        controller.popoverPresentationController?.barButtonItem = sender
        present(controller, animated: true, completion: nil)
        TelemetryWrapper.recordEvent(category: .action, method: .deleteAll, object: .tab, value: viewModel.isInPrivateMode ? .privateTab : .normalTab)
    }
}

// MARK: Datastore
extension ChronologicalTabsViewController: UITableViewDataSource {

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
}

extension ChronologicalTabsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.didSelectRowAt(index: indexPath)
        dismissTabTray()
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: sectionHeaderIdentifier) as? TabTableViewHeader, viewModel.numberOfRowsInSection(section: section) != 0 else {
            return nil
        }
        headerView.titleLabel.text = viewModel.getSectionDateHeader(section)
        headerView.applyTheme()
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == TabSection(rawValue: section)?.rawValue && viewModel.numberOfRowsInSection(section: section) != 0 ? UITableView.automaticDimension : 0
    }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let share = UIContextualAction(style: .normal, title: .ShareContextMenuTitle, handler: { (action, view, completionHandler) in
            guard let tab = self.viewModel.getTab(forIndex: indexPath), let url = tab.url else { return }
            self.presentActivityViewController(url, tab: tab)
        })
        let more = UIContextualAction(style: .normal, title: .PocketMoreStoriesText, handler: { (action, view, completionHandler) in
            // Bottom toolbar
            self.navigationController?.isToolbarHidden = true

            let moreViewController = TabMoreMenuViewController(tabTrayDelegate: self.delegate, tab: self.viewModel.getTab(forIndex: indexPath), index: indexPath, profile: self.profile)
            moreViewController.chronTabsTrayDelegate = self
            moreViewController.bottomSheetDelegate = self
            self.bottomSheetVC?.containerViewController = moreViewController
            self.bottomSheetVC?.showView()

        })
        let delete = UIContextualAction(style: .destructive, title: .CloseButtonTitle, handler: { (action, view, completionHandler) in
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

extension ChronologicalTabsViewController: UIPopoverPresentationControllerDelegate {
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

extension ChronologicalTabsViewController: UIToolbarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}

extension ChronologicalTabsViewController: ChronologicalTabsDelegate {
    func closeTab(forIndex index: IndexPath) {
        viewModel.removeTab(forIndex: index)
    }
    func closeTabTray() {
        dismissTabTray()
    }
}

extension ChronologicalTabsViewController: BottomSheetDelegate {
    func showBottomToolbar() {
        // Show bottom toolbar when we hide bottom sheet
        navigationController?.isToolbarHidden = false
    }
    func closeBottomSheet() {
        showBottomToolbar()
        self.bottomSheetVC?.hideView(shouldAnimate: true)
    }
}

extension ChronologicalTabsViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        TelemetryWrapper.recordEvent(category: .action, method: .close, object: .tabTray)
    }
}
