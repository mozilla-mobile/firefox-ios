/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

protocol AboutViewControllerDelegate: class {
    func aboutViewControllerDidPressIntro(_ aboutViewController: AboutViewController)
}

class AboutViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AboutHeaderViewDelegate {
    weak var delegate: AboutViewControllerDelegate?

    fileprivate let tableView = UITableView()
    fileprivate let headerView = AboutHeaderView()
    fileprivate let supportPath = (AppInfo.ProductName == "Focus") ? "en-US/kb/focus" : "products/klar"

    override func viewDidLoad() {
        view.backgroundColor = UIConstants.colors.background

        headerView.delegate = self

        let aboutLabel = UILabel()
        aboutLabel.text = NSLocalizedString("About", comment: "Title for the About screen")
        aboutLabel.textColor = UIConstants.colors.navigationTitle
        aboutLabel.font = UIConstants.fonts.defaultFontMedium
        view.addSubview(aboutLabel)

        let doneButton = UIButton()
        doneButton.setTitle(NSLocalizedString("Done", comment: "Button at top of app that goes to the About screen"), for: UIControlState())
        doneButton.setTitleColor(UIConstants.colors.focusBlue, for: UIControlState())
        doneButton.setTitleColor(UIConstants.colors.buttonHighlight, for: UIControlState.highlighted)
        doneButton.addTarget(self, action: #selector(AboutViewController.doneClicked(_:)), for: UIControlEvents.touchUpInside)
        doneButton.titleLabel?.font = UIConstants.fonts.defaultFontSemibold
        view.addSubview(doneButton)

        view.addSubview(tableView)

        aboutLabel.snp.makeConstraints { make in
            make.top.equalTo(self.view).offset(30)
            make.centerX.equalTo(self.view)
        }

        doneButton.snp.makeConstraints { make in
            make.centerY.equalTo(aboutLabel)
            make.trailing.equalTo(self.view).offset(UIConstants.layout.navigationDoneOffset)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(aboutLabel.snp.bottom)
            make.leading.trailing.bottom.equalTo(self.view)
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIConstants.colors.background
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.separatorColor = UIColor(rgb: 0x333333)
        tableView.estimatedRowHeight = 44

        // Don't show trailing rows.
        tableView.tableFooterView = UIView(frame: CGRect.zero)
    }

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: true)
        super.viewWillAppear(animated)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        switch (indexPath as NSIndexPath).row {
        case 0:
            cell.contentView.addSubview(headerView)
            headerView.snp.makeConstraints { make in
                make.edges.equalTo(cell)
            }
        case 1:
            cell.textLabel?.text = NSLocalizedString("Setup Instructions", comment: "Label in About screen")
            cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
        case 2:
            cell.textLabel?.text = NSLocalizedString("Help", comment: "Label in About screen")
        case 3:
            cell.textLabel?.text = NSLocalizedString("Your Rights", comment: "Label in About screen")
        default:
            break
        }

        cell.backgroundColor = UIConstants.colors.background

        let cellBG = UIView()
        cellBG.backgroundColor = UIConstants.colors.cellSelected
        cell.selectedBackgroundView = cellBG
        
        cell.textLabel?.textColor = UIConstants.colors.defaultFont
        cell.layoutMargins = UIEdgeInsets.zero
        cell.separatorInset = UIEdgeInsets.zero

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch (indexPath as NSIndexPath).row {
        case 0:
            // We ask for the height before we do a layout pass, so manually trigger a layout here
            // so we can calculate the view's height.
            headerView.layoutIfNeeded()

            return headerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
        default:
            break
        }

        return 44
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return (indexPath as NSIndexPath).row != 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        switch (indexPath as NSIndexPath).row {
        case 1:
            delegate?.aboutViewControllerDidPressIntro(self)
        case 2:
            let contentViewController = AboutContentViewController()
            contentViewController.url = URL(string: "https://support.mozilla.org/\(supportPath)")
            navigationController?.pushViewController(contentViewController, animated: true)
        case 3:
            let contentViewController = AboutContentViewController()
            contentViewController.url = LocalWebServer.sharedInstance.URLForPath("/rights-\(AppInfo.ProductName).html")
            navigationController?.pushViewController(contentViewController, animated: true)
        default:
            break
        }

        tableView.deselectRow(at: indexPath, animated: false)
    }

    @objc func doneClicked(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    fileprivate func aboutHeaderViewDidPressReadMore(_ aboutHeaderView: AboutHeaderView) {
        let contentViewController = AboutContentViewController()
        contentViewController.url = URL(string: "https://www.mozilla.org/\(AppInfo.LanguageCode)/about/manifesto/")
        navigationController?.pushViewController(contentViewController, animated: true)
    }
}

class AboutNavigationController: UINavigationController {
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    override func viewDidLoad() {
        navigationBar.barTintColor = UIConstants.colors.background
        navigationBar.isTranslucent = false
        navigationBar.tintColor = UIConstants.colors.focusBlue
    }
}

private protocol AboutHeaderViewDelegate: class {
    func aboutHeaderViewDidPressReadMore(_ aboutHeaderView: AboutHeaderView)
}

private class AboutHeaderView: UIView {
    weak var delegate: AboutHeaderViewDelegate?

    init() {
        super.init(frame: CGRect.zero)

        let logo = UIImageView(image: UIImage(named: "\(AppInfo.ProductName)Logo"))
        addSubview(logo)

        let descriptionLabel1 = UILabel()
        let descriptionLabel1Text = NSLocalizedString("%@ puts you in control and brings added privacy and performance to your mobile browsing experience.", comment: "About copy on the about page")
        descriptionLabel1.text = String(format: descriptionLabel1Text, AppInfo.ProductName)
        descriptionLabel1.textColor = UIConstants.colors.defaultFont
        descriptionLabel1.font = descriptionLabel1.font.withSize(14)
        descriptionLabel1.numberOfLines = 0
        descriptionLabel1.textAlignment = NSTextAlignment.center
        addSubview(descriptionLabel1)

        let descriptionLabel2 = UILabel()
        let descriptionLabel2Text = NSLocalizedString("%@ is produced by Mozilla, the people behind the Firefox Web browser.", comment: "About copy on the about page")
        descriptionLabel2.text = String(format: descriptionLabel2Text, AppInfo.ProductName)
        descriptionLabel2.textColor = UIConstants.colors.defaultFont
        descriptionLabel2.font = descriptionLabel2.font.withSize(14)
        descriptionLabel2.numberOfLines = 0
        descriptionLabel2.textAlignment = NSTextAlignment.center
        addSubview(descriptionLabel2)

        let descriptionLabel3 = UILabel()
        descriptionLabel3.text = NSLocalizedString("Our mission is to foster a healthy, open Internet.", comment: "About copy on the about page")
        descriptionLabel3.textColor = UIConstants.colors.defaultFont
        descriptionLabel3.font = descriptionLabel3.font.withSize(14)
        descriptionLabel3.numberOfLines = 0
        descriptionLabel3.textAlignment = NSTextAlignment.center
        addSubview(descriptionLabel3)

        let readMoreButton = UIButton()
        readMoreButton.setTitle(NSLocalizedString("Read more.", comment: "Button on the about page"), for: UIControlState())
        readMoreButton.setTitleColor(UIConstants.colors.focusBlue, for: UIControlState())
        readMoreButton.setTitleColor(UIConstants.colors.buttonHighlight, for: UIControlState.highlighted)
        readMoreButton.titleLabel?.font = readMoreButton.titleLabel!.font.withSize(14)
        readMoreButton.addTarget(self, action: #selector(AboutHeaderView.clickedReadMore(_:)), for: UIControlEvents.touchUpInside)
        addSubview(readMoreButton)

        descriptionLabel3.font = descriptionLabel3.font.withSize(14)
        descriptionLabel3.numberOfLines = 0
        descriptionLabel3.textAlignment = NSTextAlignment.center
        addSubview(descriptionLabel3)

        translatesAutoresizingMaskIntoConstraints = false

        logo.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.top.equalTo(self).offset(50)
            make.width.equalTo(275)
            make.height.equalTo(84)
        }

        descriptionLabel1.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self).inset(30)

            // Priority hack is needed to avoid conflicting constraints with the cell height.
            // See http://stackoverflow.com/a/25795758
            make.top.equalTo(logo.snp.bottom).offset(50).priority(999)
        }

        descriptionLabel2.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self).inset(30)
            make.top.equalTo(descriptionLabel1.snp.bottom).offset(15)
        }

        descriptionLabel3.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self).inset(30)
            make.top.equalTo(descriptionLabel2.snp.bottom).offset(15)
        }

        readMoreButton.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.top.equalTo(descriptionLabel3.snp.bottom).offset(-7)
            make.bottom.equalTo(self).inset(50)
        }
    }

    @objc func clickedReadMore(_ sender: UIButton) {
        delegate?.aboutHeaderViewDidPressReadMore(self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
