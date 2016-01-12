/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

protocol AboutViewControllerDelegate: class {
    func aboutViewControllerDidPressIntro(aboutViewController: AboutViewController)
}

class AboutViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AboutHeaderViewDelegate {
    weak var delegate: AboutViewControllerDelegate?

    private let tableView = UITableView()
    private let headerView = AboutHeaderView()

    override func viewDidLoad() {
        view.backgroundColor = UIConstants.Colors.Background

        headerView.delegate = self

        let aboutLabel = UILabel()
        aboutLabel.text = NSLocalizedString("About", comment: "Title for the About screen")
        aboutLabel.textColor = UIConstants.Colors.NavigationTitle
        aboutLabel.font = UIConstants.Fonts.DefaultFontMedium
        view.addSubview(aboutLabel)

        let doneButton = UIButton()
        doneButton.setTitle(NSLocalizedString("Done", comment: "Button at top of app that goes to the About screen"), forState: UIControlState.Normal)
        doneButton.setTitleColor(UIConstants.Colors.FocusBlue, forState: UIControlState.Normal)
        doneButton.setTitleColor(UIConstants.Colors.ButtonHighlightedColor, forState: UIControlState.Highlighted)
        doneButton.addTarget(self, action: "doneClicked:", forControlEvents: UIControlEvents.TouchUpInside)
        doneButton.titleLabel?.font = UIConstants.Fonts.DefaultFontSemibold
        view.addSubview(doneButton)

        view.addSubview(tableView)

        aboutLabel.snp_makeConstraints { make in
            make.top.equalTo(self.view).offset(30)
            make.centerX.equalTo(self.view)
        }

        doneButton.snp_makeConstraints { make in
            make.centerY.equalTo(aboutLabel)
            make.trailing.equalTo(self.view).offset(UIConstants.Layout.NavigationDoneOffset)
        }
        
        tableView.snp_makeConstraints { make in
            make.top.equalTo(aboutLabel.snp_bottom)
            make.leading.trailing.bottom.equalTo(self.view)
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIConstants.Colors.Background
        tableView.layoutMargins = UIEdgeInsetsZero
        tableView.separatorColor = UIColor(rgb: 0x333333)
        tableView.estimatedRowHeight = 44

        // Don't show trailing rows.
        tableView.tableFooterView = UIView(frame: CGRectZero)
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    override func viewWillAppear(animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: true)
        super.viewWillAppear(animated)
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        switch indexPath.row {
        case 0:
            cell.contentView.addSubview(headerView)
            headerView.snp_makeConstraints { make in
                make.edges.equalTo(cell)
            }
        case 1:
            cell.textLabel?.text = NSLocalizedString("Setup Instructions", comment: "Label in About screen")
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        case 2:
            cell.textLabel?.text = NSLocalizedString("Help", comment: "Label in About screen")
        case 3:
            cell.textLabel?.text = NSLocalizedString("Your Rights", comment: "Label in About screen")
        default:
            break
        }

        cell.backgroundColor = UIConstants.Colors.Background

        let cellBG = UIView()
        cellBG.backgroundColor = UIConstants.Colors.CellSelected
        cell.selectedBackgroundView = cellBG
        
        cell.textLabel?.textColor = UIConstants.Colors.DefaultFont
        cell.layoutMargins = UIEdgeInsetsZero
        cell.separatorInset = UIEdgeInsetsZero

        return cell
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            // We ask for the height before we do a layout pass, so manually trigger a layout here
            // so we can calculate the view's height.
            headerView.layoutIfNeeded()

            return headerView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
        default:
            break
        }

        return 44
    }

    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.row != 0
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        switch indexPath.row {
        case 1:
            dismissViewControllerAnimated(true, completion: nil)
            delegate?.aboutViewControllerDidPressIntro(self)
        case 2:
            let contentViewController = AboutContentViewController()
            contentViewController.url = NSURL(string: "https://support.mozilla.org/de/kb/focus")
            navigationController?.pushViewController(contentViewController, animated: true)
        case 3:
            let contentViewController = AboutContentViewController()
            contentViewController.url = LocalWebServer.sharedInstance.URLForPath("/rights.html")
            navigationController?.pushViewController(contentViewController, animated: true)
        default:
            break
        }

        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }

    @objc func doneClicked(sender: UIButton) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    private func aboutHeaderViewDidPressReadMore(aboutHeaderView: AboutHeaderView) {
        let contentViewController = AboutContentViewController()
        contentViewController.url = NSURL(string: "https://www.mozilla.org/de/about/manifesto/")
        navigationController?.pushViewController(contentViewController, animated: true)
    }
}

class AboutNavigationController: UINavigationController {
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    override func viewDidLoad() {
        navigationBar.barTintColor = UIConstants.Colors.Background
        navigationBar.translucent = false
        navigationBar.tintColor = UIConstants.Colors.FocusBlue
    }
}

private protocol AboutHeaderViewDelegate: class {
    func aboutHeaderViewDidPressReadMore(aboutHeaderView: AboutHeaderView)
}

private class AboutHeaderView: UIView {
    weak var delegate: AboutHeaderViewDelegate?

    init() {
        super.init(frame: CGRectZero)

        let logo = UIImageView(image: UIImage(named: "Logo"))
        addSubview(logo)

        let descriptionLabel1 = UILabel()
        descriptionLabel1.text = NSLocalizedString("Focus puts you in control and brings added privacy and performance to your mobile browsing experience.", comment: "About copy on the about page")
        descriptionLabel1.textColor = UIConstants.Colors.DefaultFont
        descriptionLabel1.font = descriptionLabel1.font.fontWithSize(14)
        descriptionLabel1.numberOfLines = 0
        descriptionLabel1.textAlignment = NSTextAlignment.Center
        addSubview(descriptionLabel1)

        let descriptionLabel2 = UILabel()
        descriptionLabel2.text = NSLocalizedString("Focus is produced by Mozilla, the people behind the Firefox Web browser.", comment: "About copy on the about page")
        descriptionLabel2.textColor = UIConstants.Colors.DefaultFont
        descriptionLabel2.font = descriptionLabel2.font.fontWithSize(14)
        descriptionLabel2.numberOfLines = 0
        descriptionLabel2.textAlignment = NSTextAlignment.Center
        addSubview(descriptionLabel2)

        let descriptionLabel3 = UILabel()
        descriptionLabel3.text = NSLocalizedString("Our mission is to foster a healthy, open Internet.", comment: "About copy on the about page")
        descriptionLabel3.textColor = UIConstants.Colors.DefaultFont
        descriptionLabel3.font = descriptionLabel3.font.fontWithSize(14)
        descriptionLabel3.numberOfLines = 0
        descriptionLabel3.textAlignment = NSTextAlignment.Center
        addSubview(descriptionLabel3)

        let readMoreButton = UIButton()
        readMoreButton.setTitle(NSLocalizedString("Read more.", comment: "Button on the about page"), forState: UIControlState.Normal)
        readMoreButton.setTitleColor(UIConstants.Colors.FocusBlue, forState: UIControlState.Normal)
        readMoreButton.setTitleColor(UIConstants.Colors.ButtonHighlightedColor, forState: UIControlState.Highlighted)
        readMoreButton.titleLabel?.font = readMoreButton.titleLabel!.font.fontWithSize(14)
        readMoreButton.addTarget(self, action: "clickedReadMore:", forControlEvents: UIControlEvents.TouchUpInside)
        addSubview(readMoreButton)

        descriptionLabel3.font = descriptionLabel3.font.fontWithSize(14)
        descriptionLabel3.numberOfLines = 0
        descriptionLabel3.textAlignment = NSTextAlignment.Center
        addSubview(descriptionLabel3)

        translatesAutoresizingMaskIntoConstraints = false

        logo.snp_makeConstraints { make in
            make.centerX.equalTo(self)
            make.top.equalTo(self).offset(50)
            make.width.equalTo(275)
            make.height.equalTo(84)
        }

        descriptionLabel1.snp_makeConstraints { make in
            make.leading.trailing.equalTo(self).inset(30)

            // Priority hack is needed to avoid conflicting constraints with the cell height.
            // See http://stackoverflow.com/a/25795758
            make.top.equalTo(logo.snp_bottom).offset(50).priority(999)
        }

        descriptionLabel2.snp_makeConstraints { make in
            make.leading.trailing.equalTo(self).inset(30)
            make.top.equalTo(descriptionLabel1.snp_bottom).offset(15)
        }

        descriptionLabel3.snp_makeConstraints { make in
            make.leading.trailing.equalTo(self).inset(30)
            make.top.equalTo(descriptionLabel2.snp_bottom).offset(15)
        }

        readMoreButton.snp_makeConstraints { make in
            make.centerX.equalTo(self)
            make.top.equalTo(descriptionLabel3.snp_bottom).offset(-7)
            make.bottom.equalTo(self).inset(50)
        }
    }

    @objc func clickedReadMore(sender: UIButton) {
        delegate?.aboutHeaderViewDidPressReadMore(self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
