// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import SnapKit
import UIKit

class TabMoreMenuViewController: UIViewController, NotificationThemeable {
    weak var delegate: TabTrayDelegate?
    var chronTabsTrayDelegate: ChronologicalTabsDelegate?
    var bottomSheetDelegate: BottomSheetDelegate?
    weak var tab: Tab?
    lazy var viewModel = TabMoreMenuViewModel(viewController: self, profile: profile)
    let profile: Profile
    let tabIndex: IndexPath

    let titles: [Int: [String]] = [ 1: [.ShareAddToReadingList,
                                        .BookmarkContextMenuTitle,
                                        .AddToShortcutsActionTitle],
                                    2: [.KeyboardShortcuts.CloseCurrentTab],
                                    0: [.CopyAddressTitle,
                                        .ShareContextMenuTitle,
                                        .SendToDeviceTitle]
    ]
    let imageViews: [Int: [UIImageView]] = [ 1: [UIImageView(image: UIImage.templateImageNamed("library-readinglist")),
                                                 UIImageView(image: UIImage.templateImageNamed("bookmark")),
                                                 UIImageView(image: UIImage.templateImageNamed("action_pin"))],
                                             2: [UIImageView(image: UIImage.templateImageNamed("menu-CloseTabs"))],
                                             0: [UIImageView(image: UIImage.templateImageNamed("menu-Copy-Link")),
                                                 UIImageView(image: UIImage.templateImageNamed("menu-Send")),
                                                 UIImageView(image: UIImage.templateImageNamed("menu-Send-to-Device"))]
    ]
    lazy var tableView: UITableView = {
        var tableView = UITableView(frame: CGRect(), style: .insetGrouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "moreMenuCell")
        tableView.register(ThemedTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "moreMenuHeader")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = UIDevice.current.orientation.isLandscape ? true : false
        return tableView
    }()
    
    lazy var tabMoreMenuHeader: TabMoreMenuHeader = {
        let header = TabMoreMenuHeader()
        return header
    }()
    
    lazy var handleView: UIView = {
        let handleView = UIView()
        handleView.backgroundColor = .black
        handleView.alpha = DrawerViewControllerUX.HandleAlpha
        handleView.layer.cornerRadius = DrawerViewControllerUX.HandleHeight / 2
        return handleView
    }()

    lazy var divider: UIView = {
        let divider = UIView()
        divider.backgroundColor = UIColor.Photon.Grey30
        return divider
    }()
    
    func applyTheme() {
        if LegacyThemeManager.instance.currentName == .normal {
            tabMoreMenuHeader.backgroundColor = UIColor.Photon.Grey10
        } else {
            tabMoreMenuHeader.backgroundColor = UIColor.Photon.Grey90
        }
    }
    
    @objc func displayThemeChanged() {
        applyTheme()
        tableView.reloadData()
    }
    
    init(tabTrayDelegate: TabTrayDelegate? = nil, tab: Tab? = nil, index: IndexPath, profile: Profile) {
        self.delegate = tabTrayDelegate
        self.tab = tab
        self.profile = profile
        self.tabIndex = index
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(handleView)
        view.addSubview(tableView)
        view.addSubview(tabMoreMenuHeader)
        view.addSubview(divider)
        view.layer.cornerRadius = 8
        navigationController?.navigationBar.isHidden = true
        
        configure(headerView: tabMoreMenuHeader, tab: tab)
        setupConstraints()
        applyTheme()
        NotificationCenter.default.addObserver(self, selector: #selector(displayThemeChanged), name: .DisplayThemeChanged, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.reloadData()
        tableView.isScrollEnabled = UIDevice.current.orientation.isLandscape ? true : false
    }
    
    func setupConstraints() {
        handleView.snp.makeConstraints{ make in
            make.width.equalTo(DrawerViewControllerUX.HandleWidth)
            make.height.equalTo(DrawerViewControllerUX.HandleHeight)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset((DrawerViewControllerUX.HandleMargin - DrawerViewControllerUX.HandleHeight) / 2)
        }
        tabMoreMenuHeader.snp.makeConstraints { make in
            make.top.equalTo(handleView.snp.bottom)
            make.bottom.equalTo(divider.snp.top)
            make.left.right.equalToSuperview()
        }
        divider.snp.makeConstraints { make in
            make.top.equalTo(tabMoreMenuHeader.snp.bottom)
            make.bottom.equalTo(tableView.snp.top).inset(-20)
            make.height.equalTo(1)
            make.width.equalToSuperview()
        }
        tableView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.centerX.equalToSuperview()
            make.bottom.equalTo(self.view.safeArea.bottom).inset(40)
        }
    }
    
    func configure(headerView: TabMoreMenuHeader, tab: Tab? = nil) {
        guard  let tab = tab else { return }
        let baseDomain = tab.url?.baseDomain
        headerView.descriptionLabel.text = baseDomain != nil ? baseDomain!.contains("local") ? " " : baseDomain : " "
        headerView.titleLabel.text = tab.displayTitle
        headerView.imageView.image = tab.screenshot ?? UIImage()
        headerView.backgroundColor = UIColor.Photon.Grey10
    }
    
    func dismissMenu() {
        bottomSheetDelegate?.closeBottomSheet()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension TabMoreMenuViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return 3 }
        else if section == 1 { return 3 }
        else { return 1 }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "moreMenuCell", for: indexPath)
        let lightColor = UIColor.theme.tableView.rowBackground
        let darkColor = UIColor.Photon.Grey80
        cell.backgroundColor = LegacyThemeManager.instance.currentName == .normal ? lightColor : darkColor
        cell.textLabel?.text = titles[indexPath.section]?[indexPath.row]
        cell.accessoryView = imageViews[indexPath.section]?[indexPath.row]
        cell.accessoryView?.tintColor = UIColor.theme.textField.textAndTint
        
        return cell
    }
}

extension TabMoreMenuViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "moreMenuHeader") as? ThemedTableSectionHeaderFooterView else {
            return nil
        }
        headerView.applyTheme()
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let tab = tab, let url = self.tab?.sessionData?.urls.last ?? self.tab?.url else { return }
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                UIPasteboard.general.url = url
                SimpleToast().showAlertWithText(.AppMenuCopyURLConfirmMessage, bottomContainer: self.view)
                dismissMenu()
            case 1:
                dismissMenu()
                self.presentActivityViewController(url, tab: tab)
            case 2:
                dismissMenu()
                chronTabsTrayDelegate?.closeTabTray()
                viewModel.sendToDevice()
            default:
                return
            }
        case 1:
            switch indexPath.row {
            case 0:
                _ = delegate?.tabTrayDidAddToReadingList(tab)
                dismissMenu()
            case 1:
                delegate?.tabTrayDidAddBookmark(tab)
                dismissMenu()
            case 2:
                viewModel.pin(tab)
                dismissMenu()
            default:
                return
            }
        case 2:
            chronTabsTrayDelegate?.closeTab(forIndex: tabIndex)
            dismissMenu()
        default:
            return
        }
    }
}

extension TabMoreMenuViewController: UIPopoverPresentationControllerDelegate {
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

class TransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return PresentationController(presentedViewController: presented, presenting: presenting)
    }
}

class PresentationController: UIPresentationController {
    override var frameOfPresentedViewInContainerView: CGRect {
        let bounds = presentingViewController.view.bounds
        return CGRect(x: 0, y: bounds.height/2 - 80, width: bounds.width, height: bounds.height/2 + 160)
    }

    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)

        presentedView?.autoresizingMask = [
            .flexibleTopMargin,
            .flexibleBottomMargin,
            .flexibleLeftMargin,
            .flexibleRightMargin
        ]

        presentedView?.translatesAutoresizingMaskIntoConstraints = true
    }
}
