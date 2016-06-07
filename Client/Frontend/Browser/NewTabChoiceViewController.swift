/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

enum NewTabPage: String {
    case BlankPage = "Blank"
    case HomePage = "HomePage"
    case TopSites = "TopSites"

    var settingTitle: String {
        switch self {
        case .BlankPage:
            return Strings.SettingsNewTabBlankPage
        case .HomePage:
            return Strings.SettingsNewTabHomePage
        case .TopSites:
            return Strings.SettingsNewTabTopSites
        }
    }

    static let allValues = [BlankPage, TopSites, HomePage]
}


/// Screen presented to the user when selecting the page that is displayed when the user goes to a new tab.
class NewTabChoiceViewController: UITableViewController {

    let newTabOptions = NewTabPage.allValues

    let prefs: Prefs
    var currentChoice: NewTabPage!
    var hasHomePage: Bool!

    private let BasicCheckmarkCell = "BasicCheckmarkCell"
    private var authenticationInfo: AuthenticationKeychainInfo?

    init(prefs: Prefs) {
        self.prefs = prefs
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.SettingsNewTabTitle

        tableView.accessibilityIdentifier = "NewTabPage.Setting.Options"

        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: BasicCheckmarkCell)
        tableView.backgroundColor = UIConstants.TableViewHeaderBackgroundColor

        let headerFooterFrame = CGRect(origin: CGPointZero, size: CGSize(width: self.view.frame.width, height: UIConstants.TableViewHeaderFooterHeight))
        let headerView = SettingsTableSectionHeaderFooterView(frame: headerFooterFrame)
        headerView.showTopBorder = false
        headerView.showBottomBorder = true

        let footerView = SettingsTableSectionHeaderFooterView(frame: headerFooterFrame)
        footerView.showTopBorder = true
        footerView.showBottomBorder = false

        tableView.tableHeaderView = headerView
        tableView.tableFooterView = footerView
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.currentChoice = NewTabAccessors.getNewTabPage(prefs)
        self.hasHomePage = HomePageAccessors.getHomePage(prefs) != nil
        tableView.reloadData()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.prefs.setString(currentChoice.rawValue, forKey: NewTabAccessors.PrefKey)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(BasicCheckmarkCell, forIndexPath: indexPath)

        let option = newTabOptions[indexPath.row]
        cell.textLabel?.attributedText = NSAttributedString.tableRowTitle(option.settingTitle)

        cell.accessoryType = (currentChoice == option) ? .Checkmark : .None

        let enabled = (option != .HomePage) || hasHomePage

        cell.textLabel?.textColor = enabled ? UIConstants.TableViewRowTextColor : UIConstants.TableViewDisabledRowTextColor
        cell.userInteractionEnabled = enabled

        return cell
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newTabOptions.count
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        currentChoice = newTabOptions[indexPath.row]
        tableView.reloadData()
    }
}
