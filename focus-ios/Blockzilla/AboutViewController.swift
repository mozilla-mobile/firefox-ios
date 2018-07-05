/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

class AboutViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AboutHeaderViewDelegate {

    fileprivate lazy var tableView : UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIConstants.colors.background
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.separatorColor = UIColor(rgb: 0x333333)
        tableView.estimatedRowHeight = 44

        // Don't show trailing rows.
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        return tableView
    }()

    fileprivate let headerView = AboutHeaderView()

    override func viewDidLoad() {
        headerView.delegate = self

        title = String(format: UIConstants.strings.aboutTitle, AppInfo.productName)

        configureTableView()
    }

    private func configureTableView() {
        view.addSubview(tableView)

        tableView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
    }

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellID")
        return cell ?? UITableViewCell()
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        configureCell(cell, forRowAt: indexPath)
    }

    private func configureCell(_ cell: UITableViewCell, forRowAt indexPath: IndexPath) {
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
        var url: URL? = nil
        switch (indexPath as NSIndexPath).row {
        case 1:
            url = URL(string: "https://support.mozilla.org/\(AppInfo.config.supportPath)")
        case 2:
            url = LocalWebServer.sharedInstance.URLForPath("/\(AppInfo.config.rightsFile)")
        case 3:
            url = URL(string: "https://www.mozilla.org/privacy/firefox-focus")
        default: break
        }

        pushSettingsContentViewControllerWithURL(url)

        tableView.deselectRow(at: indexPath, animated: false)
    }

    private func pushSettingsContentViewControllerWithURL(_ url: URL?) {
        guard let url = url else { return }
        let contentViewController = SettingsContentViewController(url: url)
        navigationController?.pushViewController(contentViewController, animated: true)
    }

    fileprivate func aboutHeaderViewDidPressLearnMore(_ aboutHeaderView: AboutHeaderView) {
        let url = URL(string: "https://www.mozilla.org/\(AppInfo.languageCode)/about/manifesto/")
        pushSettingsContentViewControllerWithURL(url)
    }
}

private protocol AboutHeaderViewDelegate: class {
    func aboutHeaderViewDidPressLearnMore(_ aboutHeaderView: AboutHeaderView)
}

private class AboutHeaderView: UIView {
    weak var delegate: AboutHeaderViewDelegate?

    private lazy var logo : UIImageView = {
        let logo = UIImageView(image: AppInfo.config.wordmark)
        return logo
    }()

    private lazy var aboutParagraph : UILabel = {
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
        paragraph.forEach { attributed.append($0) }



        let aboutParagraph = SmartLabel()
        aboutParagraph.attributedText = attributed
        aboutParagraph.textColor = UIConstants.colors.defaultFont
        aboutParagraph.font = UIConstants.fonts.aboutText
        aboutParagraph.numberOfLines = 0
        return aboutParagraph
    }()

    private lazy var versionNumber: UILabel = {
        let label = SmartLabel()
        label.text = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        label.font = UIConstants.fonts.aboutText
        label.textColor = UIConstants.colors.defaultFont.withAlphaComponent(0.5)
        return label
    }()

    private lazy var learnMoreButton : UIButton = {
        let learnMoreButton = UIButton()
        learnMoreButton.setTitle(UIConstants.strings.aboutLearnMoreButton, for: .normal)
        learnMoreButton.setTitleColor(UIConstants.colors.settingsLink, for: .normal)
        learnMoreButton.setTitleColor(UIConstants.colors.buttonHighlight, for: .highlighted)
        learnMoreButton.titleLabel?.font = UIConstants.fonts.aboutText
        learnMoreButton.addTarget(self, action: #selector(didPressLearnMore), for: .touchUpInside)
        return learnMoreButton
    }()

    convenience init() {
        self.init(frame: CGRect.zero)
        addSubviews()
        configureConstraints()
    }

    @objc private func didPressLearnMore() {
        delegate?.aboutHeaderViewDidPressLearnMore(self)
    }

    private func addSubviews() {
        addSubview(logo)
        addSubview(aboutParagraph)
        addSubview(versionNumber)
        addSubview(learnMoreButton)
    }

    private func configureConstraints() {

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
            make.top.greaterThanOrEqualTo(aboutParagraph.snp.bottom).priority(.required)
            make.leading.equalTo(aboutParagraph)
            make.bottom.equalTo(self).inset(50).priority(.low)
        }
    }

}
