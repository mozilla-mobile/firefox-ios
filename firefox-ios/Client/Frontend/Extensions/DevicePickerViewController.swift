// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import Storage
import Account
import SwiftUI
import Common

protocol DevicePickerViewControllerDelegate: AnyObject {
    func devicePickerViewControllerDidCancel(_ devicePickerViewController: DevicePickerViewController)
    func devicePickerViewController(
        _ devicePickerViewController: DevicePickerViewController,
        didPickDevices devices: [RemoteDevice]
    )
}

private enum LoadingState {
    case loading
    case loaded
}

public enum ClientType: String {
    case Desktop = "deviceTypeDesktop"
    case Mobile = "deviceTypeMobile"
    case Tablet = "deviceTypeTablet"
    case VR = "deviceTypeVR"
    case TV = "deviceTypeTV"

    static func fromFxAType(_ type: String?) -> ClientType {
        switch type {
        case "desktop":
            return ClientType.Desktop
        case "mobile":
            return ClientType.Mobile
        case "tablet":
            return ClientType.Tablet
        case "vr":
            return ClientType.VR
        case "tv":
            return ClientType.TV
        default:
            return ClientType.Mobile
        }
    }

    var imageName: String {
        switch self {
        case .Desktop:
            return StandardImageIdentifiers.Large.deviceDesktop
        case .Mobile:
            return StandardImageIdentifiers.Large.deviceMobile
        case .Tablet:
            return StandardImageIdentifiers.Large.deviceTablet
        default:
            return StandardImageIdentifiers.Large.deviceMobile
        }
    }
}

class DevicePickerViewController: UITableViewController {
    private struct UX {
        static let tableHeaderRowHeight: CGFloat = 50
        static let deviceRowHeight: CGFloat = 50
        static let tabTitleTextFont = UIFont.boldSystemFont(ofSize: 16)
    }

    private lazy var tabTitleLabel: UILabel = .build { label in
        label.font = UX.tabTitleTextFont
        label.textColor = self.currentTheme().colors.textPrimary
    }

    private var devices = [RemoteDevice]()
    var profile: Profile
    weak var pickerDelegate: DevicePickerViewControllerDelegate?
    private var selectedIdentifiers = Set<String>() // Stores Device.id
    private var notification: Any?
    private var loadingState = LoadingState.loading

    private let themeManager = DefaultThemeManager(sharedContainerIdentifier: AppInfo.sharedContainerIdentifier)

    // ShareItem has been added as we are now using this class outside of the ShareTo extension to
    // provide Share To functionality
    // And in this case we need to be able to store the item we are sharing as we may not have access to the
    // url later. Currently used only when sharing an item from the Tab Tray from a Preview Action.
    var shareItem: ShareItem?

    init(profile: Profile = AppContainer.shared.resolve()) {
        self.profile = profile

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let tabTitle = tabTitleLabel
        tabTitle.text = .SendToTitle
        navigationItem.titleView = tabTitle
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: .SendToCancelButton,
            style: .plain,
            target: self,
            action: #selector(cancel)
        )

        tableView.register(DevicePickerTableViewHeaderCell.self,
                           forCellReuseIdentifier: DevicePickerTableViewHeaderCell.cellIdentifier)
        tableView.register(DevicePickerTableViewCell.self,
                           forCellReuseIdentifier: DevicePickerTableViewCell.cellIdentifier)
        tableView.register(HostingTableViewCell<HelpView>.self,
                           forCellReuseIdentifier: HostingTableViewCell<HelpView>.cellIdentifier)
        tableView.tableFooterView = UIView(frame: .zero)

        tableView.allowsSelection = true
        tableView.backgroundColor = currentTheme().colors.layer2
        tableView.separatorStyle = .none

        notification = NotificationCenter.default.addObserver(forName: Notification.Name.constellationStateUpdate,
                                                              object: nil,
                                                              queue: .main) { [weak self ] _ in
            self?.loadList()
            self?.refreshControl?.endRefreshing()
        }

        RustFirefoxAccounts.shared.accountManager?.deviceConstellation()?.refreshState()
        loadList()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        pickerDelegate?.devicePickerViewControllerDidCancel(self)
    }

    deinit {
        if let obj = notification {
            NotificationCenter.default.removeObserver(obj)
        }
    }

    private func currentTheme() -> Theme {
        return themeManager.windowNonspecificTheme()
    }

    private func loadList() {
        guard let state = RustFirefoxAccounts.shared.accountManager?.deviceConstellation()?.state() else {
            self.loadingState = .loaded
            return
        }

        let currentIds = self.devices.map { $0.id ?? "" }.sorted()
        let newIds = state.remoteDevices.map { $0.id }.sorted()
        if !currentIds.isEmpty, currentIds == newIds {
            return
        }

        self.devices = state.remoteDevices.compactMap { device in
            guard device.capabilities.contains(.sendTab) else { return nil }

            let typeString = "\(device.deviceType)"
            let lastAccessTime = device.lastAccessTime == nil ? nil : UInt64(clamping: device.lastAccessTime!)
            return RemoteDevice(id: device.id,
                                name: device.displayName,
                                type: typeString,
                                isCurrentDevice: device.isCurrentDevice,
                                lastAccessTime: lastAccessTime,
                                availableCommands: nil)
        }

        if self.devices.isEmpty {
            self.navigationItem.rightBarButtonItem = nil
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: .SendToSendButtonTitle,
                                                                     style: .done,
                                                                     target: self,
                                                                     action: #selector(self.send))
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }

        self.loadingState = .loaded
        self.tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        if devices.isEmpty {
            return 1
        } else {
            return 2
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if devices.isEmpty {
            return 1
        } else {
            if section == 0 {
                return 1
            } else {
                return devices.count
            }
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?

        let theme = currentTheme()
        if !devices.isEmpty {
            if indexPath.section == 0 {
                cell = tableView.dequeueReusableCell(withIdentifier: DevicePickerTableViewHeaderCell.cellIdentifier,
                                                     for: indexPath)
                (cell as? DevicePickerTableViewHeaderCell)?.applyTheme(theme: theme)
            } else if let clientCell = tableView.dequeueReusableCell(
                withIdentifier: DevicePickerTableViewCell.cellIdentifier,
                for: indexPath) as? DevicePickerTableViewCell {
                let item = devices[indexPath.row]
                clientCell.configureCell(item.name, ClientType.fromFxAType(item.type))

                if let id = item.id {
                    clientCell.checked = selectedIdentifiers.contains(id)
                }
                clientCell.applyTheme(theme: theme)
                cell = clientCell
            }
        } else {
            if loadingState == .loaded,
                let hostingCell = tableView.dequeueReusableCell(
                withIdentifier: HostingTableViewCell<HelpView>.cellIdentifier) as? HostingTableViewCell<HelpView> {
                let textColor = theme.colors.textPrimary
                let imageColor = theme.colors.iconDisabled

                let emptyView = HelpView(textColor: textColor,
                                         imageColor: imageColor,
                                         topMessage: String.SendToNoDevicesFound,
                                         bottomMessage: nil)
                hostingCell.host(emptyView, parentController: self)

                // Move the separator off screen
                hostingCell.separatorInset = UIEdgeInsets(top: 0, left: 1000, bottom: 0, right: 0)
                cell = hostingCell
            }
        }

        return cell ?? UITableViewCell(style: .default, reuseIdentifier: "ClientCell")
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
         return indexPath.section != 0
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if devices.isEmpty || indexPath.section != 1 {
            return
        }

        tableView.deselectRow(at: indexPath, animated: true)

        guard let id = devices[indexPath.row].id else { return }

        if selectedIdentifiers.contains(id) {
            selectedIdentifiers.remove(id)
        } else {
            selectedIdentifiers.insert(id)
        }

        UIView.performWithoutAnimation {
            // If the selected cell is off-screen when the tableview is first shown, the tableview
            // will re-scroll without disabling animation.
            tableView.reloadRows(at: [indexPath], with: .none)
        }
        navigationItem.rightBarButtonItem?.isEnabled = !selectedIdentifiers.isEmpty
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if !devices.isEmpty {
            if indexPath.section == 0 {
                return UX.tableHeaderRowHeight
            } else {
                return UX.deviceRowHeight
            }
        } else {
            return tableView.frame.height
        }
    }

    @objc
    func refresh() {
        RustFirefoxAccounts.shared.accountManager?.deviceConstellation()?.refreshState()
        if let refreshControl = refreshControl {
            refreshControl.beginRefreshing()
            let height = -(refreshControl.bounds.size.height + (navigationController?.navigationBar.bounds.size.height ?? 0))
            self.tableView.contentOffset = CGPoint(x: 0, y: height)
        }
    }

    @objc
    func cancel() {
        pickerDelegate?.devicePickerViewControllerDidCancel(self)
    }

    @objc
    func send() {
        let theme = currentTheme()
        var pickedItems = [RemoteDevice]()
        for id in selectedIdentifiers {
            if let item = devices.first(where: { $0.id == id }) {
                pickedItems.append(item)
            }
        }

        pickerDelegate?.devicePickerViewController(self, didPickDevices: pickedItems)

        // Replace the Send button with a loading indicator since it takes a while to sync
        // up our changes to the server.
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(width: 25, height: 25))
        loadingIndicator.color = theme.colors.iconSpinner
        loadingIndicator.startAnimating()
        let customBarButton = UIBarButtonItem(customView: loadingIndicator)
        self.navigationItem.rightBarButtonItem = customBarButton
    }
}
