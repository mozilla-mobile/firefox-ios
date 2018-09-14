
//
//  CredentialProviderViewController.swift
//  firefoxAutoFillExtension
//
//  Created by Meera Rachamallu on 8/27/18.
//  Copyright © 2018 Mozilla. All rights reserved.
//
import UIKit
import Shared
import Storage
import SnapKit
import Deferred
import AuthenticationServices

private let SectionHeaderFooterIdentifier = "SectionHeaderFooterIdentifier"

private struct CredentialProviderViewControllerUX {
    static let TableHeaderRowHeight = CGFloat(50)
    static let TableHeaderTextFont = UIFont.systemFont(ofSize: 16)
    static let TableHeaderTextColor = UIColor.purple
    static let TableHeaderTextPaddingLeft = CGFloat(20)

    static let DeviceRowTintColor = UIColor.purple
    static let DeviceRowHeight = CGFloat(50)
    static let DeviceRowTextFont = UIFont.systemFont(ofSize: 16)
    static let DeviceRowTextPaddingLeft = CGFloat(72)
    static let DeviceRowTextPaddingRight = CGFloat(50)
}

class CredentialProviderViewController: ASCredentialProviderViewController, UITableViewDelegate, UITableViewDataSource {

    public enum CredentialError: MaybeErrorType {
        case noProfile

        public var description: String {
            switch self {
            case .noProfile: return "Did not have a profile"
            }
        }
    }

    let tableView = UITableView()
    var profile: Profile?
    var webAuthSession: ASWebAuthenticationSession?
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        title = ""

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: Strings.SendToCancelButton,
            style: .plain,
            target: self,
            action: #selector(didPressCancel)
        )

        updateConstraints()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(CredentialProviderTableViewHeaderCell.self, forCellReuseIdentifier: CredentialProviderTableViewHeaderCell.CellIdentifier)
        tableView.register(CredentialProviderTableViewCell.self, forCellReuseIdentifier: CredentialProviderTableViewCell.CellIdentifier)
        tableView.tableFooterView = UIView(frame: .zero)

        let profile = BrowserProfile(localName: "profile")
        self.profile = profile
        queryLogins("").upon { (logins) in
            NSLog("done") // cant get breakpoints to work with this extension. Only way is to use NSlog and check the simulator console :/
        }
    }

    fileprivate func queryLogins(_ query: String) -> Deferred<Maybe<[Login]>> {
        let deferred = Deferred<Maybe<[Login]>>()
        guard let profile = self.profile else {
            deferred.fillIfUnfilled(Maybe(failure: CredentialError.noProfile))
            return deferred
        }
        profile.logins.searchLoginsWithQuery(query) >>== { logins in
            deferred.fillIfUnfilled(Maybe(success: logins.asArray()))
            NSLog("%@", logins.asArray())
            succeed()
        }
        return deferred
    }

    func numberOfSections(in tableView: UITableView) -> Int {
            return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return 3
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if indexPath.section == 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: CredentialProviderTableViewHeaderCell.CellIdentifier, for: indexPath) as! CredentialProviderTableViewHeaderCell
        } else {
            let credentialCell = tableView.dequeueReusableCell(withIdentifier: CredentialProviderTableViewCell.CellIdentifier, for: indexPath) as! CredentialProviderTableViewCell
            credentialCell.nameLabel.text = "username"
            credentialCell.checked = false
            cell = credentialCell
        }
        return cell
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section != 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            let passwordCredential = ASPasswordCredential(user: "j_appleseed", password: "apple1234")
            self.extensionContext.completeRequest(withSelectedCredential: passwordCredential, completionHandler: nil)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
                return CredentialProviderViewControllerUX.TableHeaderRowHeight
    }


    /*
     Prepare your UI to list available credentials for the user to choose from. The items in
     'serviceIdentifiers' describe the service the user is logging in to, so your extension can
     prioritize the most relevant credentials in the list.
     */
    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        NSLog("the idtentifers %@", serviceIdentifiers.count)
        NSLog("the idtentifer %@", serviceIdentifiers.first?.identifier ?? "")
        queryLogins(serviceIdentifiers.first?.identifier ?? "").upon { (logins) in
            NSLog("done!")
            NSLog("%@", logins.successValue?.first?.description ?? "")
        }
    }

    /*
     Implement this method if your extension supports showing credentials in the QuickType bar.
     When the user selects a credential from your app, this method will be called with the
     ASPasswordCredentialIdentity your app has previously saved to the ASCredentialIdentityStore.
     Provide the password by completing the extension request with the associated ASPasswordCredential.
     If using the credential would require showing custom UI for authenticating the user, cancel
     the request with error code ASExtensionError.userInteractionRequired.
     */
    override func provideCredentialWithoutUserInteraction(for credentialIdentity: ASPasswordCredentialIdentity) {
        let databaseIsUnlocked = true
        if (databaseIsUnlocked) {
            let passwordCredential = ASPasswordCredential(user: "j_appleseed", password: "apple1234")
            self.extensionContext.completeRequest(withSelectedCredential: passwordCredential, completionHandler: nil)
        } else {
            self.extensionContext.cancelRequest(withError: NSError(domain: ASExtensionErrorDomain, code:ASExtensionError.userInteractionRequired.rawValue))
        }
    }


    /*
     Implement this method if provideCredentialWithoutUserInteraction(for:) can fail with
     ASExtensionError.userInteractionRequired. In this case, the system may present your extension's
     UI and call this method. Show appropriate UI for authenticating the user then provide the password
     by completing the extension request with the associated ASPasswordCredential.
     */
    override func prepareInterfaceToProvideCredential(for credentialIdentity: ASPasswordCredentialIdentity) {

    }

    private func updateConstraints() {
        tableView.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(view)
            make.right.equalTo(view)
            make.bottom.equalTo(view)
            make.top.equalTo(80)
        }
    }

    @objc func didPressCancel() {
        self.extensionContext.cancelRequest(withError: NSError(domain: ASExtensionErrorDomain, code: ASExtensionError.userCanceled.rawValue))
    }
}

class CredentialProviderTableViewHeaderCell: UITableViewCell {
    static let CellIdentifier = "CredentialProviderTableViewSectionHeader"
    let nameLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(nameLabel)
        nameLabel.font = CredentialProviderViewControllerUX.TableHeaderTextFont
        nameLabel.text = NSLocalizedString("Available devices:", tableName: "SendTo", comment: "Header for the list of devices table")
        nameLabel.textColor = CredentialProviderViewControllerUX.TableHeaderTextColor

        nameLabel.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(CredentialProviderViewControllerUX.TableHeaderTextPaddingLeft)
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
    case Mobile = "deviceTypeMobile"
    case Desktop = "deviceTypeDesktop"
}

class CredentialProviderTableViewCell: UITableViewCell {
    static let CellIdentifier = "CredentialProviderTableViewCell"

    var nameLabel: UILabel
    var checked: Bool = false {
        didSet {
            self.accessoryType = checked ? .checkmark : .none
        }
    }

    var clientType: ClientType = ClientType.Mobile {
        didSet {
            self.imageView?.image = UIImage(named: clientType.rawValue)
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        nameLabel = UILabel()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(nameLabel)
        nameLabel.font = CredentialProviderViewControllerUX.DeviceRowTextFont
        nameLabel.numberOfLines = 2
        nameLabel.lineBreakMode = .byWordWrapping
        self.tintColor = CredentialProviderViewControllerUX.DeviceRowTintColor
        self.preservesSuperviewLayoutMargins = false
        self.selectionStyle = .none
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        nameLabel.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(CredentialProviderViewControllerUX.DeviceRowTextPaddingLeft)
            make.centerY.equalTo(self.snp.centerY)
            make.right.equalTo(self.snp.right).offset(-CredentialProviderViewControllerUX.DeviceRowTextPaddingRight)
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
