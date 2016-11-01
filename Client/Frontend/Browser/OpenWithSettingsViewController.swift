/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

class OpenWithSettingsViewController: UITableViewController {
    typealias MailtoProviderEntry = (name: String, scheme: String, enabled: Bool)
    var mailProviderSource = [MailtoProviderEntry]()

    private let prefs: Prefs
    private var currentChoice: String = "mailto"

    private let BasicCheckmarkCell = "BasicCheckmarkCell"

    init(prefs: Prefs) {
        self.prefs = prefs
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.SettingsOpenWithSectionName

        tableView.accessibilityIdentifier = "OpenWithPage.Setting.Options"

        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: BasicCheckmarkCell)
        tableView.backgroundColor = UIConstants.TableViewHeaderBackgroundColor

        let headerFooterFrame = CGRect(origin: CGPointZero, size: CGSize(width: self.view.frame.width, height: UIConstants.TableViewHeaderFooterHeight))
        let headerView = SettingsTableSectionHeaderFooterView(frame: headerFooterFrame)
        headerView.titleLabel.text = Strings.SettingsOpenWithPageTitle
        headerView.showTopBorder = false
        headerView.showBottomBorder = true

        let footerView = SettingsTableSectionHeaderFooterView(frame: headerFooterFrame)
        footerView.showTopBorder = true
        footerView.showBottomBorder = false

        tableView.tableHeaderView = headerView
        tableView.tableFooterView = footerView

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(OpenWithSettingsViewController.appDidBecomeActive), name: UIApplicationDidBecomeActiveNotification, object: nil)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        appDidBecomeActive()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.prefs.setString(currentChoice, forKey: "MailToOption")
    }

    func appDidBecomeActive() {
        reloadMailProviderSource()
        updateCurrentChoice()
        tableView.reloadData()
    }

    func updateCurrentChoice() {
        var previousChoiceAvailable: Bool = false
        if let prefMailtoScheme = self.prefs.stringForKey("MailToOption") {
            mailProviderSource.forEach({ (name, scheme, enabled) in
                if scheme == prefMailtoScheme {
                    previousChoiceAvailable = enabled
                }
            })
        }
        if !previousChoiceAvailable {
            self.prefs.setString(mailProviderSource[0].scheme, forKey: "MailToOption")
        }
        self.currentChoice = self.prefs.stringForKey("MailToOption")!
    }

    func reloadMailProviderSource() {
        if let path = NSBundle.mainBundle().pathForResource("MailSchemes", ofType: "plist"), let dictRoot = NSArray(contentsOfFile: path) {
            mailProviderSource = dictRoot.map {  dict in (name: dict["name"] as! String, scheme: dict["scheme"] as! String, enabled: canOpenMailScheme(dict["scheme"] as! String)) }
        }
    }

    func canOpenMailScheme(scheme: String) -> Bool {
        if let url = NSURL(string: scheme) {
            return UIApplication.sharedApplication().canOpenURL(url)
        }
        return false
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(BasicCheckmarkCell, forIndexPath: indexPath)

        let option = mailProviderSource[indexPath.row]

        cell.textLabel?.attributedText = NSAttributedString.tableRowTitle(option.name)
        cell.accessoryType = (currentChoice == option.scheme && option.enabled) ? .Checkmark : .None

        cell.textLabel?.textColor = option.enabled ? UIConstants.TableViewRowTextColor : UIConstants.TableViewDisabledRowTextColor
        cell.userInteractionEnabled = option.enabled

        return cell
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mailProviderSource.count
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.currentChoice = mailProviderSource[indexPath.row].scheme
        tableView.reloadData()
    }
}
