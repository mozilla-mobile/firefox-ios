
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Storage
import SnapKit
import Account

protocol DevicePickerViewControllerDelegate {
    func devicePickerViewControllerDidCancel(_ devicePickerViewController: DevicePickerViewController)
    func devicePickerViewController(_ devicePickerViewController: DevicePickerViewController, didPickDevices devices: [RemoteDevice])
}

private struct DevicePickerViewControllerUX {
    static let TableHeaderRowHeight = CGFloat(50)
    static let TableHeaderTextFont = UIFont.systemFont(ofSize: 16)
    static let TableHeaderTextColor = UIColor.Photon.Grey50
    static let TableHeaderTextPaddingLeft = CGFloat(20)

    static let DeviceRowHeight = CGFloat(50)
    static let DeviceRowTextFont = UIFont.systemFont(ofSize: 16)
    static let DeviceRowTextPaddingLeft = CGFloat(72)
    static let DeviceRowTextPaddingRight = CGFloat(50)
}

fileprivate enum LoadingState {
    case loading
    case loaded
}

class DevicePickerViewController: UITableViewController {
    private var devices = [RemoteDevice]()
    var profile: Profile?
    var profileNeedsShutdown = true
    var pickerDelegate: DevicePickerViewControllerDelegate?
    private var selectedIdentifiers = Set<String>() // Stores Device.id
    private var notification: Any?
    private var loadingState = LoadingState.loading

    // ShareItem has been added as we are now using this class outside of the ShareTo extension to provide Share To functionality
    // And in this case we need to be able to store the item we are sharing as we may not have access to the
    // url later. Currently used only when sharing an item from the Tab Tray from a Preview Action.
    var shareItem: ShareItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.SendToTitle
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: Strings.SendToCancelButton,
            style: .plain,
            target: self,
            action: #selector(cancel)
        )

        tableView.register(DevicePickerTableViewHeaderCell.self, forCellReuseIdentifier: DevicePickerTableViewHeaderCell.CellIdentifier)
        tableView.register(DevicePickerTableViewCell.self, forCellReuseIdentifier: DevicePickerTableViewCell.CellIdentifier)
        tableView.register(DevicePickerNoClientsTableViewCell.self, forCellReuseIdentifier: DevicePickerNoClientsTableViewCell.CellIdentifier)
        tableView.tableFooterView = UIView(frame: .zero)

        tableView.allowsSelection = true

        notification = NotificationCenter.default.addObserver(forName: Notification.Name.constellationStateUpdate
        , object: nil, queue: .main) { [weak self ] _ in
            self?.loadList()
            self?.refreshControl?.endRefreshing()
        }

        let profile = ensureOpenProfile()
        RustFirefoxAccounts.startup(prefs: profile.prefs).uponQueue(.main) { accountManager in
            accountManager.deviceConstellation()?.refreshState()
        }

        loadList()
    }

    deinit {
        if let obj = notification {
            NotificationCenter.default.removeObserver(obj)
        }
    }

    private func loadList() {
        let profile = ensureOpenProfile()
        RustFirefoxAccounts.startup(prefs: profile.prefs).uponQueue(.main) { [weak self] accountManager in
            guard let state = accountManager.deviceConstellation()?.state() else {
                self?.loadingState = .loaded
                return
            }
            guard let self = self else { return }

            let currentIds = self.devices.map { $0.id ?? "" }.sorted()
            let newIds = state.remoteDevices.map { $0.id }.sorted()
            if currentIds.count > 0, currentIds == newIds {
                return
            }

            self.devices = state.remoteDevices.map { d in
                let t = "\(d.deviceType)"
                return RemoteDevice(id: d.id, name: d.displayName, type: t, isCurrentDevice: d.isCurrentDevice, lastAccessTime: d.lastAccessTime, availableCommands: nil)
            }

            if self.devices.isEmpty {
                self.navigationItem.rightBarButtonItem = nil
            } else {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: Strings.SendToSendButtonTitle, style: .done, target: self, action: #selector(self.send))
                self.navigationItem.rightBarButtonItem?.isEnabled = false
            }

            self.loadingState = .loaded
            self.tableView.reloadData()
        }
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
        let cell: UITableViewCell

        if !devices.isEmpty {
            if indexPath.section == 0 {
                cell = tableView.dequeueReusableCell(withIdentifier: DevicePickerTableViewHeaderCell.CellIdentifier, for: indexPath) as! DevicePickerTableViewHeaderCell
            } else {
                let clientCell = tableView.dequeueReusableCell(withIdentifier: DevicePickerTableViewCell.CellIdentifier, for: indexPath) as! DevicePickerTableViewCell
                let item = devices[indexPath.row]
                clientCell.nameLabel.text = item.name
                clientCell.clientType = ClientType.fromFxAType(item.type)

                if let id = item.id {
                    clientCell.checked = selectedIdentifiers.contains(id)
                }
                cell = clientCell
            }
        } else {
            if loadingState == .loaded {
                cell = tableView.dequeueReusableCell(withIdentifier: DevicePickerNoClientsTableViewCell.CellIdentifier, for: indexPath) as! DevicePickerNoClientsTableViewCell
            } else {
                cell = UITableViewCell(style: .default, reuseIdentifier: "ClientCell")
            }
        }

        return cell
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

        UIView.performWithoutAnimation { // if the selected cell is off-screen when the tableview is first shown, the tableview will re-scroll without disabling animation
            tableView.reloadRows(at: [indexPath], with: .none)
        }
        navigationItem.rightBarButtonItem?.isEnabled = !selectedIdentifiers.isEmpty
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if !devices.isEmpty {
            if indexPath.section == 0 {
                return DevicePickerViewControllerUX.TableHeaderRowHeight
            } else {
                return DevicePickerViewControllerUX.DeviceRowHeight
            }
        } else {
            return tableView.frame.height
        }
    }

    fileprivate func ensureOpenProfile() -> Profile {
        // If we were not given a profile, open the default profile. This happens in case we are called from an app
        // extension. That also means that we need to shut down the profile, otherwise the app extension will be
        // terminated when it goes into the background.
        if let profile = self.profile {
            // Re-open the profile if it was shutdown. This happens when we run from an app extension, where we must
            // make sure that the profile is only open for brief moments of time.
            if profile.isShutdown && Bundle.main.bundleURL.pathExtension == "appex" {
                profile._reopen()
            }
            return profile
        }

        let profile = BrowserProfile(localName: "profile")
        self.profile = profile
        self.profileNeedsShutdown = true
        return profile
    }

    @objc func refresh() {
        RustFirefoxAccounts.shared.accountManager.peek()?.deviceConstellation()?.refreshState()
        if let refreshControl = self.refreshControl {
            refreshControl.beginRefreshing()
            let height = -(refreshControl.bounds.size.height + (self.navigationController?.navigationBar.bounds.size.height ?? 0))
            self.tableView.contentOffset = CGPoint(x: 0, y: height)
        }
    }

    @objc func cancel() {
        pickerDelegate?.devicePickerViewControllerDidCancel(self)
    }

    @objc func send() {
        var pickedItems = [RemoteDevice]()
        for id in selectedIdentifiers {
            if let item = devices.find({ $0.id == id }) {
                pickedItems.append(item)
            }
        }

        self.pickerDelegate?.devicePickerViewController(self, didPickDevices: pickedItems)

        // Replace the Send button with a loading indicator since it takes a while to sync
        // up our changes to the server.
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(width: 25, height: 25))
        loadingIndicator.color = UIColor.Photon.Grey60
        loadingIndicator.startAnimating()
        let customBarButton = UIBarButtonItem(customView: loadingIndicator)
        self.navigationItem.rightBarButtonItem = customBarButton
    }
}

class DevicePickerTableViewHeaderCell: UITableViewCell {
    static let CellIdentifier = "ClientPickerTableViewSectionHeader"
    let nameLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(nameLabel)
        nameLabel.font = DevicePickerViewControllerUX.TableHeaderTextFont
        nameLabel.text = Strings.SendToDevicesListTitle
        nameLabel.textColor = DevicePickerViewControllerUX.TableHeaderTextColor

        nameLabel.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(DevicePickerViewControllerUX.TableHeaderTextPaddingLeft)
            make.centerY.equalTo(self)
            make.right.equalTo(self)
        }

        preservesSuperviewLayoutMargins = false
        layoutMargins = .zero
        separatorInset = .zero
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
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
}

class DevicePickerTableViewCell: UITableViewCell {
    static let CellIdentifier = "ClientPickerTableViewCell"

    var nameLabel: UILabel
    var checked: Bool = false {
        didSet {
            self.accessoryType = checked ? .checkmark : .none
        }
    }

    var clientType = ClientType.Mobile {
        didSet {
            self.imageView?.image = UIImage.templateImageNamed(clientType.rawValue)
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        nameLabel = UILabel()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(nameLabel)
        nameLabel.font = DevicePickerViewControllerUX.DeviceRowTextFont
        nameLabel.numberOfLines = 2
        nameLabel.lineBreakMode = .byWordWrapping
        if #available(iOS 13.0, *) {
            self.tintColor = UIColor.label
        } else {
            self.tintColor = UIColor.gray
        }
        self.preservesSuperviewLayoutMargins = false
        self.selectionStyle = .none
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        nameLabel.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(DevicePickerViewControllerUX.DeviceRowTextPaddingLeft)
            make.centerY.equalTo(self.snp.centerY)
            make.right.equalTo(self.snp.right).offset(-DevicePickerViewControllerUX.DeviceRowTextPaddingRight)
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class DevicePickerNoClientsTableViewCell: UITableViewCell {
    static let CellIdentifier = "ClientPickerNoClientsTableViewCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupHelpView(contentView,
            introText: Strings.SendToNoDevicesFound,
            showMeText: "") // TODO We used to have a 'show me how to ...' text here. But, we cannot open web pages from the extension. So this is clear for now until we decide otherwise.
        // Move the separator off screen
        separatorInset = UIEdgeInsets(top: 0, left: 1000, bottom: 0, right: 0)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
