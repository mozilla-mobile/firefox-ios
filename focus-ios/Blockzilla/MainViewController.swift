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
    func mainViewControllerDidToggleList(_ mainViewController: MainViewController)
}

class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AboutViewControllerDelegate {
    weak var delegate: MainViewControllerDelegate?

    fileprivate let detector = BlockerEnabledDetector.makeInstance()

    fileprivate let tableView = UITableView()
    fileprivate let headerView = MainHeaderView()
    fileprivate let errorFooterView = ErrorFooterView()
    fileprivate var shouldUpdateEnabledWhenVisible = true

    fileprivate let toggles = [
        BlockerToggle(label: LabelBlockAds, key: Settings.KeyBlockAds),
        BlockerToggle(label: LabelBlockAnalytics, key: Settings.KeyBlockAnalytics),
        BlockerToggle(label: LabelBlockSocial, key: Settings.KeyBlockSocial),
        BlockerToggle(label: LabelBlockOther, key: Settings.KeyBlockOther, subtitle: SubtitleBlockOther),
        BlockerToggle(label: LabelBlockFonts, key: Settings.KeyBlockFonts),
    ]

    /// Used to calculate cell heights.
    fileprivate lazy var dummyToggleCell: UITableViewCell = {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "dummyCell")
        cell.accessoryView = PaddedSwitch(switchView: UISwitch())
        return cell
    }()

    override func viewDidLoad() {
        view.backgroundColor = UIConstants.Colors.Background

        let titleView = TitleView()
        view.addSubview(titleView)

        view.addSubview(tableView)
        view.addSubview(errorFooterView)

        let aboutButton = UIButton()
        aboutButton.setTitle(NSLocalizedString("About", comment: "Button at top of app that goes to the About screen"), for: UIControlState())
        aboutButton.setTitleColor(UIConstants.Colors.NavigationTitle, for: UIControlState())
        aboutButton.setTitleColor(UIConstants.Colors.ButtonHighlightedColor, for: UIControlState.highlighted)
        aboutButton.addTarget(self, action: #selector(MainViewController.aboutClicked(_:)), for: UIControlEvents.touchUpInside)
        aboutButton.titleLabel?.font = UIConstants.Fonts.DefaultFontSemibold
        view.addSubview(aboutButton)

        titleView.snp.makeConstraints { make in
            make.top.equalTo(self.view).offset(20)
            make.centerX.equalTo(self.view)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleView.snp.bottom)
            make.leading.trailing.bottom.equalTo(self.view)
        }

        aboutButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleView)
            make.leading.equalTo(self.view).offset(10)
        }

        errorFooterView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self.view)
            make.top.equalTo(self.view.snp.bottom)
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIConstants.Colors.Background
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.separatorColor = UIColor(rgb: 0x333333)
        tableView.allowsSelection = false
        tableView.estimatedRowHeight = 44

        // Don't show trailing rows.
        tableView.tableFooterView = TableFooterView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 144))

        toggles.forEach { blockerToggle in
            let toggle = blockerToggle.toggle
            toggle.onTintColor = UIConstants.Colors.FocusBlue
            toggle.tintColor = UIColor(rgb: 0x585E64)
            toggle.addTarget(self, action: #selector(MainViewController.toggleSwitched(_:)), for: UIControlEvents.valueChanged)
            toggle.isOn = Settings.getBool(blockerToggle.key) ?? false
        }

        NotificationCenter.default.addObserver(self, selector: #selector(UIApplicationDelegate.applicationDidBecomeActive(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        guard shouldUpdateEnabledWhenVisible else { return }

        shouldUpdateEnabledWhenVisible = false
        updateEnabledState()
    }

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    fileprivate func toggleForIndexPath(_ indexPath: IndexPath) -> BlockerToggle {
        var index = (indexPath as NSIndexPath).row
        for i in 1..<(indexPath as NSIndexPath).section {
            index += tableView.numberOfRows(inSection: i)
        }
        return toggles[index]
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "toggleCell")
        switch (indexPath as NSIndexPath).section {
        case 0:
            cell.contentView.addSubview(headerView)
            headerView.snp.makeConstraints { make in
                make.edges.equalTo(cell)
            }
        case 1: fallthrough
        case 2:
            let toggle = toggleForIndexPath(indexPath)
            cell.textLabel?.text = toggle.label
            cell.textLabel?.numberOfLines = 0
            cell.accessoryView = PaddedSwitch(switchView: toggle.toggle)
            cell.detailTextLabel?.text = toggle.subtitle
            cell.detailTextLabel?.numberOfLines = 0
        default:
            break
        }

        cell.backgroundColor = UIConstants.Colors.Background
        cell.textLabel?.textColor = UIConstants.Colors.DefaultFont
        cell.layoutMargins = UIEdgeInsets.zero
        cell.detailTextLabel?.textColor = UIConstants.Colors.NavigationTitle

        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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

    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath as NSIndexPath).section == 0 {
            return heightForCustomCellWithView(headerView)
        }

        // We have to manually calculate the cell height since UITableViewCell don't correctly
        // layout multiline detailTextLabels.
        let toggle = toggleForIndexPath(indexPath)
        let tableWidth = tableView.frame.width
        let accessoryWidth = dummyToggleCell.accessoryView!.frame.width
        let insetsWidth = 2 * tableView.separatorInset.left
        let width = tableWidth - accessoryWidth - insetsWidth

        var height = heightForLabel(dummyToggleCell.textLabel!, width: width, text: toggle.label)
        if let subtitle = toggle.subtitle {
            height += heightForLabel(dummyToggleCell.detailTextLabel!, width: width, text: subtitle)
        }

        return height + 22
    }

    fileprivate func heightForLabel(_ label: UILabel, width: CGFloat, text: String) -> CGFloat {
        let size = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let attrs: [String: Any] = [NSFontAttributeName: label.font]
        let boundingRect = NSString(string: text).boundingRect(with: size, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: attrs, context: nil)
        return boundingRect.height
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
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

        label.snp.makeConstraints { make in
            make.leading.trailing.equalTo(cell.textLabel!)
            make.centerY.equalTo(cell.textLabel!).offset(10)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 1:
            fallthrough
        case 2:
            return 30
        default:
            return 0
        }
    }

    func aboutViewControllerDidPressIntro(_ aboutViewController: AboutViewController) {
        dismiss(animated: true, completion: nil)
        let introViewController = IntroViewController()
        present(introViewController, animated: true, completion: nil)
    }

    fileprivate func updateEnabledState() {
        toggles.forEach { $0.toggle.isEnabled = false }

        detector.detectEnabled(view) { blocked in
            let onToggles = self.toggles.filter { blockerToggle in
                blockerToggle.toggle.isEnabled = blocked
                return blockerToggle.toggle.isOn
            }
            self.headerView.waveView.active = blocked && !onToggles.isEmpty

            UIView.setAnimationBeginsFromCurrentState(true)
            UIView.transition(with: self.errorFooterView, duration: 0.3, options: UIViewAnimationOptions.curveEaseOut, animations: {
                self.errorFooterView.snp.remakeConstraints { make in
                    let constraintPosition = blocked ? make.top : make.bottom
                    make.leading.trailing.equalTo(self.view)
                    constraintPosition.equalTo(self.view.snp.bottom)
                }
                self.errorFooterView.layoutIfNeeded()
            }, completion: nil)
        }
    }

    fileprivate func heightForCustomCellWithView(_ view: UIView) -> CGFloat {
        // We ask for the height before we do a layout pass, so manually trigger a layout here
        // so we can calculate the view's height.
        view.layoutIfNeeded()

        return view.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
    }

    @objc func aboutClicked(_ sender: UIButton) {
        let aboutViewController = AboutViewController()
        aboutViewController.delegate = self
        let navController = AboutNavigationController(rootViewController: aboutViewController)
        navController.modalPresentationStyle = UIModalPresentationStyle.formSheet
        present(navController, animated: true, completion: nil)
    }

    @objc func applicationDidBecomeActive(_ sender: UIApplication) {
        if isViewLoaded && view.window != nil {
            updateEnabledState()
        } else {
            shouldUpdateEnabledWhenVisible = true
        }
    }

    @objc func toggleSwitched(_ sender: UISwitch) {
        let toggle = toggles.filter { $0.toggle == sender }.first!

        func updateSetting() {
            Settings.set(sender.isOn, forKey: toggle.key)
            delegate?.mainViewControllerDidToggleList(self)
            headerView.waveView.active = !toggles.filter { $0.toggle.isOn }.isEmpty
        }

        if toggle.key == Settings.KeyBlockOther && sender.isOn {
            let message = NSLocalizedString("Blocking other content trackers may break some videos and Web pages.", comment: "Alert message shown when toggling the Content blocker")
            let yes = NSLocalizedString("I Understand", comment: "Button label for accepting Content blocker alert")
            let no = NSLocalizedString("No, Thanks", comment: "Button label for declining Content blocker alert")
            let alertController = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.actionSheet)
            alertController.addAction(UIAlertAction(title: yes, style: UIAlertActionStyle.destructive) { _ in
                updateSetting()
            })
            alertController.addAction(UIAlertAction(title: no, style: UIAlertActionStyle.default) { _ in
                sender.isOn = false
                updateSetting()
            })
            alertController.popoverPresentationController?.sourceView = sender
            alertController.popoverPresentationController?.sourceRect = sender.bounds
            present(alertController, animated: true, completion: nil)
        } else {
            updateSetting()
        }
    }
}

private class PaddedSwitch: UIView {
    fileprivate static let Padding: CGFloat = 8

    init(switchView: UISwitch) {
        super.init(frame: CGRect.zero)

        addSubview(switchView)

        frame.size = CGSize(width: switchView.frame.width + PaddedSwitch.Padding, height: switchView.frame.height)
        switchView.frame.origin = CGPoint(x: PaddedSwitch.Padding, y: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class TableFooterView: UIView {
    lazy var logo: UIImageView = {
        var image =  UIImageView(image: UIImage(named: "FooterLogo"))
        image.contentMode = UIViewContentMode.center
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
