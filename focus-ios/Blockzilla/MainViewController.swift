/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import UIKit

private let LabelBlockAds = NSLocalizedString("Block ad trackers", comment: "Label for toggle on main screen")
private let LabelBlockAnalytics = NSLocalizedString("Block analytics trackers", comment: "Label for toggle on main screen")
private let LabelBlockSocial = NSLocalizedString("Block social trackers", comment: "Label for toggle on main screen")
private let LabelBlockOther = NSLocalizedString("Block other content trackers", comment: "Label for toggle on main screen")
private let LabelBlockFonts = NSLocalizedString("Block Web fonts", comment: "Label for toggle on main screen")

private let SubtitleBlockOther = NSLocalizedString("May break some videos and Web pages", comment: "Label for toggle on main screen")

protocol MainViewControllerDelegate: class {
    func mainViewControllerDidToggleList(mainViewController: MainViewController)
}

class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AboutViewControllerDelegate {
    weak var delegate: MainViewControllerDelegate?

    private let tableView = UITableView()
    private let enabledDetector = BlockerEnabledDetector()

    private let headerView = MainHeaderView()
    private let errorFooterView = ErrorFooterView()
    private var shouldUpdateEnabledWhenVisible = true

    private let toggles = [
        BlockerToggle(label: LabelBlockAds, key: Settings.KeyBlockAds),
        BlockerToggle(label: LabelBlockAnalytics, key: Settings.KeyBlockAnalytics),
        BlockerToggle(label: LabelBlockSocial, key: Settings.KeyBlockSocial),
        BlockerToggle(label: LabelBlockOther, key: Settings.KeyBlockOther, subtitle: SubtitleBlockOther),
        BlockerToggle(label: LabelBlockFonts, key: Settings.KeyBlockFonts),
    ]

    override func viewDidLoad() {
        view.backgroundColor = UIConstants.Colors.Background

        let titleView = TitleView()
        view.addSubview(titleView)

        view.addSubview(tableView)
        view.addSubview(errorFooterView)

        let aboutButton = UIButton()
        aboutButton.setTitle(NSLocalizedString("About", comment: "Button at top of app that goes to the About screen"), forState: UIControlState.Normal)
        aboutButton.setTitleColor(UIConstants.Colors.NavigationTitle, forState: UIControlState.Normal)
        aboutButton.setTitleColor(UIConstants.Colors.ButtonHighlightedColor, forState: UIControlState.Highlighted)
        aboutButton.addTarget(self, action: "aboutClicked:", forControlEvents: UIControlEvents.TouchUpInside)
        aboutButton.titleLabel?.font = UIConstants.Fonts.DefaultFontSemibold
        view.addSubview(aboutButton)

        titleView.snp_makeConstraints { make in
            make.top.equalTo(self.view).offset(20)
            make.centerX.equalTo(self.view)
        }

        tableView.snp_makeConstraints { make in
            make.top.equalTo(titleView.snp_bottom)
            make.leading.trailing.bottom.equalTo(self.view)
        }

        aboutButton.snp_makeConstraints { make in
            make.centerY.equalTo(titleView)
            make.leading.equalTo(self.view).offset(10)
        }

        errorFooterView.snp_makeConstraints { make in
            make.leading.trailing.equalTo(self.view)
            make.top.equalTo(self.view.snp_bottom)
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIConstants.Colors.Background
        tableView.layoutMargins = UIEdgeInsetsZero
        tableView.separatorColor = UIColor(rgb: 0x333333)
        tableView.allowsSelection = false
        tableView.estimatedRowHeight = 44

        // Don't show trailing rows.
        tableView.tableFooterView = TableFooterView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 144))

        toggles.forEach { blockerToggle in
            let toggle = blockerToggle.toggle
            toggle.onTintColor = UIConstants.Colors.FocusBlue
            toggle.tintColor = UIColor(rgb: 0x585E64)
            toggle.addTarget(self, action: Selector("toggleSwitched:"), forControlEvents: UIControlEvents.ValueChanged)
            toggle.on = Settings.getBool(blockerToggle.key) ?? false
        }

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationDidBecomeActive:", name: UIApplicationDidBecomeActiveNotification, object: nil)
    }

    override func viewWillAppear(animated: Bool) {
        guard shouldUpdateEnabledWhenVisible else { return }

        shouldUpdateEnabledWhenVisible = false
        updateEnabledState()
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Subtitle, reuseIdentifier: "toggleCell")
        switch indexPath.section {
        case 0:
            cell.contentView.addSubview(headerView)
            headerView.snp_makeConstraints { make in
                make.edges.equalTo(cell)
            }
        case 1:
            let toggle = toggles[indexPath.row]
            cell.textLabel?.text = toggle.label
            cell.accessoryView = toggle.toggle
            cell.detailTextLabel?.text = toggle.subtitle
        case 2:
            let toggle = toggles[indexPath.row + 4]
            cell.textLabel?.text = toggle.label
            cell.accessoryView = toggle.toggle
        default:
            break
        }

        cell.backgroundColor = UIConstants.Colors.Background
        cell.textLabel?.textColor = UIConstants.Colors.DefaultFont
        cell.layoutMargins = UIEdgeInsetsZero
        cell.detailTextLabel?.textColor = UIConstants.Colors.NavigationTitle

        return cell
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 4
        case 2:
            return 1
        default:
            assertionFailure("Invalid section")
            return 0
        }
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return heightForCustomCellWithView(headerView)
        default:
            break
        }

        return 44
    }

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let labelText: String

        switch section {
        case 1:
            labelText = NSLocalizedString("PRIVACY", comment: "Section label for privacy toggles")
        case 2:
            labelText = NSLocalizedString("PERFORMANCE", comment: "Section label for performance toggles")
        default:
            return nil
        }

        // Hack: We want the header view's margin to match the cells, so we create an empty
        // cell with a blank space as text to layout the text label. From there, we can define
        // constraints for our custom label based on the cell's label.
        let cell = UITableViewCell()
        cell.textLabel?.text = " "
        cell.backgroundColor = UIConstants.Colors.Background

        let label = UILabel()
        label.text = labelText
        label.textColor = UIConstants.Colors.TableSectionHeader
        label.font = UIConstants.Fonts.TableSectionHeader
        cell.contentView.addSubview(label)

        label.snp_makeConstraints { make in
            make.leading.trailing.equalTo(cell.textLabel!)
            make.centerY.equalTo(cell.textLabel!).offset(10)
        }

        return cell
    }

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 1:
            fallthrough
        case 2:
            return 30
        default:
            return 0
        }
    }

    func aboutViewControllerDidPressIntro(aboutViewController: AboutViewController) {
        let introViewController = IntroViewController()
        presentViewController(introViewController, animated: true, completion: nil)
    }

    private func updateEnabledState() {
        toggles.forEach { $0.toggle.enabled = false }

        enabledDetector.detectEnabled(view) { blocked in
            let onToggles = self.toggles.filter { blockerToggle in
                blockerToggle.toggle.enabled = blocked
                return blockerToggle.toggle.on
            }
            self.headerView.waveView.active = blocked && !onToggles.isEmpty

            UIView.setAnimationBeginsFromCurrentState(true)
            UIView.transitionWithView(self.errorFooterView, duration: 0.3, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                self.errorFooterView.snp_remakeConstraints { make in
                    let constraintPosition = blocked ? make.top : make.bottom
                    make.leading.trailing.equalTo(self.view)
                    constraintPosition.equalTo(self.view.snp_bottom)
                }
                self.errorFooterView.layoutIfNeeded()
            }, completion: nil)
        }
    }

    private func heightForCustomCellWithView(view: UIView) -> CGFloat {
        // We ask for the height before we do a layout pass, so manually trigger a layout here
        // so we can calculate the view's height.
        view.layoutIfNeeded()

        return view.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
    }

    @objc func aboutClicked(sender: UIButton) {
        let aboutViewController = AboutViewController()
        aboutViewController.delegate = self
        let navController = AboutNavigationController(rootViewController: aboutViewController)
        navController.modalPresentationStyle = UIModalPresentationStyle.FormSheet
        presentViewController(navController, animated: true, completion: nil)
    }

    @objc func applicationDidBecomeActive(sender: UIApplication) {
        if isViewLoaded() && view.window != nil {
            updateEnabledState()
        } else {
            shouldUpdateEnabledWhenVisible = true
        }
    }

    @objc func toggleSwitched(sender: UISwitch) {
        let toggle = toggles.filter { $0.toggle == sender }.first!

        func updateSetting() {
            Settings.set(sender.on, forKey: toggle.key)
            delegate?.mainViewControllerDidToggleList(self)
            headerView.waveView.active = !toggles.filter { $0.toggle.on }.isEmpty
        }

        if toggle.key == Settings.KeyBlockOther && sender.on {
            let message = NSLocalizedString("Blocking other content trackers may break some videos and Web pages.", comment: "Alert message shown when toggling the Content blocker")
            let yes = NSLocalizedString("I Understand", comment: "Button label for accepting Content blocker alert")
            let no = NSLocalizedString("No, Thanks", comment: "Button label for declining Content blocker alert")
            let alertController = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.ActionSheet)
            alertController.addAction(UIAlertAction(title: yes, style: UIAlertActionStyle.Destructive) { _ in
                updateSetting()
            })
            alertController.addAction(UIAlertAction(title: no, style: UIAlertActionStyle.Default) { _ in
                sender.on = false
                updateSetting()
            })
            alertController.popoverPresentationController?.sourceView = sender
            alertController.popoverPresentationController?.sourceRect = sender.bounds
            presentViewController(alertController, animated: true, completion: nil)
        } else {
            updateSetting()
        }
    }
}


private class TableFooterView: UIView {
    var logo: UIImageView = {
        var image =  UIImageView(image: UIImage(named: "FooterLogo"))
        image.contentMode = UIViewContentMode.Center
        return image
        }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(logo)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        logo.center = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
    }
}

private class BlockerToggle {
    let toggle = UISwitch()
    let label: String
    let key: String
    let subtitle: String?

    init(label: String, key: String, subtitle: String? = nil) {
        self.label = label
        self.key = key
        self.subtitle = subtitle
    }
}
