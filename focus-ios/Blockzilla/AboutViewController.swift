/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

class AboutViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AboutHeaderViewDelegate {
    fileprivate let tableView = UITableView()
    fileprivate let headerView = AboutHeaderView()

    override func viewDidLoad() {
        headerView.delegate = self

        title = UIConstants.strings.aboutTitle

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
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
        case 1: cell.textLabel?.text = UIConstants.strings.aboutRowHelp
        case 2: cell.textLabel?.text = UIConstants.strings.aboutRowRights
        case 3: cell.textLabel?.text = UIConstants.strings.aboutRowPrivacy
        default: break
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
        default: break
        }

        return 44
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return (indexPath as NSIndexPath).row != 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath as NSIndexPath).row {
        case 1:
            let url = URL(string: "https://support.mozilla.org/\(AppInfo.config.supportPath)")!
            let contentViewController = AboutContentViewController(url: url)
            navigationController?.pushViewController(contentViewController, animated: true)
        case 2:
            let url = LocalWebServer.sharedInstance.URLForPath("/\(AppInfo.config.rightsFile)")!
            let contentViewController = AboutContentViewController(url: url)
            navigationController?.pushViewController(contentViewController, animated: true)
        case 3:
            let url = URL(string: "https://www.mozilla.org/privacy/firefox-focus")!
            let contentViewController = AboutContentViewController(url: url)
            navigationController?.pushViewController(contentViewController, animated: true)
        default: break
        }

        tableView.deselectRow(at: indexPath, animated: false)
    }

    fileprivate func aboutHeaderViewDidPressLearnMore(_ aboutHeaderView: AboutHeaderView) {
        let url = URL(string: "https://www.mozilla.org/\(AppInfo.languageCode)/about/manifesto/")!
        let contentViewController = AboutContentViewController(url: url)
        navigationController?.pushViewController(contentViewController, animated: true)
    }
}

private protocol AboutHeaderViewDelegate: class {
    func aboutHeaderViewDidPressLearnMore(_ aboutHeaderView: AboutHeaderView)
}

private class AboutHeaderView: UIView {
    weak var delegate: AboutHeaderViewDelegate?

    init() {
        super.init(frame: CGRect.zero)

        translatesAutoresizingMaskIntoConstraints = false

        let logo = UIImageView(image: AppInfo.config.wordmark)
        addSubview(logo)

        let bulletStyle = NSMutableParagraphStyle()
        bulletStyle.firstLineHeadIndent = 15
        bulletStyle.headIndent = 29.5
        let bulletAttributes = [NSAttributedStringKey.paragraphStyle: bulletStyle]
        let bulletFormat = "•  %@\n"

        let paragraph = [
            NSAttributedString(string: String(format: UIConstants.strings.aboutTopLabel, AppInfo.productName) + "\n\n"),
            NSAttributedString(string: UIConstants.strings.aboutPrivateBulletHeader + "\n"),
            NSAttributedString(string: String(format: bulletFormat, UIConstants.strings.aboutPrivateBullet1), attributes: bulletAttributes),
            NSAttributedString(string: String(format: bulletFormat, UIConstants.strings.aboutPrivateBullet2), attributes: bulletAttributes),
            NSAttributedString(string: String(format: bulletFormat, UIConstants.strings.aboutPrivateBullet3 + "\n"), attributes: bulletAttributes),
            NSAttributedString(string: UIConstants.strings.aboutSafariBulletHeader + "\n"),
            NSAttributedString(string: String(format: bulletFormat, UIConstants.strings.aboutSafariBullet1), attributes: bulletAttributes),
            NSAttributedString(string: String(format: bulletFormat, UIConstants.strings.aboutSafariBullet2 + "\n"), attributes: bulletAttributes),
            NSAttributedString(string: String(format: UIConstants.strings.aboutMissionLabel, AppInfo.productName)),
        ]

        let attributed = NSMutableAttributedString()
        for string in paragraph {
            attributed.append(string)
        }

        let versionNumber = UILabel()
        versionNumber.text = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        versionNumber.font = UIConstants.fonts.aboutText
        versionNumber.textColor = UIConstants.colors.defaultFont.withAlphaComponent(0.5)
        addSubview(versionNumber)

        let aboutParagraph = UILabel()
        aboutParagraph.attributedText = attributed
        aboutParagraph.textColor = UIConstants.colors.defaultFont
        aboutParagraph.font = UIConstants.fonts.aboutText
        aboutParagraph.numberOfLines = 0
        addSubview(aboutParagraph)

        let learnMoreButton = UIButton()
        learnMoreButton.setTitle(UIConstants.strings.aboutLearnMoreButton, for: .normal)
        learnMoreButton.setTitleColor(UIConstants.colors.settingsLink, for: .normal)
        learnMoreButton.setTitleColor(UIConstants.colors.buttonHighlight, for: .highlighted)
        learnMoreButton.titleLabel?.font = UIConstants.fonts.aboutText
        learnMoreButton.addTarget(self, action: #selector(didPressLearnMore), for: .touchUpInside)
        addSubview(learnMoreButton)

        logo.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.top.equalTo(self).offset(50)
        }

        versionNumber.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.top.equalTo(logo.snp.bottom).offset(8)
        }

        aboutParagraph.snp.makeConstraints { make in
            // Priority hack is needed to avoid conflicting constraints with the cell height.
            // See http://stackoverflow.com/a/25795758
            make.top.equalTo(logo.snp.bottom).offset(50).priority(999)

            make.centerX.equalTo(self)
            make.width.lessThanOrEqualTo(self).inset(20)
            make.width.lessThanOrEqualTo(315)
        }

        learnMoreButton.snp.makeConstraints { make in
            make.top.equalTo(aboutParagraph.snp.bottom).offset(-7)
            make.leading.equalTo(aboutParagraph)
            make.bottom.equalTo(self).inset(50)
        }
    }

    @objc private func didPressLearnMore() {
        delegate?.aboutHeaderViewDidPressLearnMore(self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
