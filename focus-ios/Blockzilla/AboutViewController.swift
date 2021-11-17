/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

class AboutViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AboutHeaderViewDelegate {
    
    enum AboutSection: CaseIterable {
        case aboutHeader
        case aboutCategories
        
        var numberOfRows: Int {
            switch self {
            case .aboutHeader:
                return 1
            case .aboutCategories:
                return 3
            }
        }
        
        func configureCell(cell: UITableViewCell, with headerView: UIView, for row: Int) {
            switch self {
            case .aboutHeader:
                cell.contentView.addSubview(headerView)
                cell.contentView.backgroundColor = .systemGroupedBackground
                headerView.snp.makeConstraints { make in
                    make.edges.equalTo(cell)
                }
            case .aboutCategories:
                switch row {
                case 0: cell.textLabel?.text = UIConstants.strings.aboutRowHelp
                case 1: cell.textLabel?.text = UIConstants.strings.aboutRowRights
                case 2: cell.textLabel?.text = UIConstants.strings.aboutRowPrivacy
                default: break
                }
            }
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.selectionStyle = .gray
            cell.textLabel?.textColor = .primaryText
            cell.layoutMargins = UIEdgeInsets.zero
            
        }
        
        func categoryUrl(for row: Int) -> URL? {
            switch self {
            case .aboutHeader:
                return nil
            case .aboutCategories:
                switch row {
                case 0:
                    return URL(string: "https://support.mozilla.org/\(AppInfo.config.supportPath)")
                case 1:
                    return Bundle.main.url(forResource: AppInfo.config.rightsFile, withExtension: nil)
                case 2:
                    return URL(string: "https://www.mozilla.org/privacy/firefox-focus")
                default:
                    return nil
                }
            }
        }
    }

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .systemGroupedBackground
        tableView.estimatedRowHeight = 44
        tableView.separatorStyle = .singleLine
        // Don't show trailing rows.
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        return tableView
    }()

    private var sections = AboutSection.allCases
    private let headerView = AboutHeaderView()

    override func viewDidLoad() {
        headerView.delegate = self
        navigationController?.navigationBar.tintColor = .accent

        title = String(format: UIConstants.strings.aboutTitle, AppInfo.productName)

        configureTableView()
    }

    private func configureTableView() {
        view.addSubview(tableView)
        view.backgroundColor = .systemGroupedBackground

        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].numberOfRows
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellID")
        return cell ?? UITableViewCell()
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        sections[indexPath.section].configureCell(cell: cell, with: headerView, for: indexPath.row)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch sections[section] {
        case .aboutHeader:
            let cell = UITableViewCell()
            cell.backgroundColor = .systemGroupedBackground
            // Hack to cover header separator line
            let footer = UIView()
            footer.backgroundColor = .systemGroupedBackground
            cell.addSubview(footer)
            cell.sendSubviewToBack(footer)
            footer.snp.makeConstraints { make in
                make.height.equalTo(1)
                make.bottom.equalToSuperview().offset(1)
                make.leading.trailing.equalToSuperview()
            }
            return cell
        case .aboutCategories:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch sections[indexPath.section] {
        case .aboutHeader:
            headerView.layoutIfNeeded()
            return headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        case .aboutCategories:
            return 44
        }
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return sections[indexPath.section] == .aboutCategories
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard sections[indexPath.section] == .aboutCategories else { return }
        let url: URL? = sections[indexPath.section].categoryUrl(for: indexPath.row)
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

private protocol AboutHeaderViewDelegate: AnyObject {
    func aboutHeaderViewDidPressLearnMore(_ aboutHeaderView: AboutHeaderView)
}

private class AboutHeaderView: UIView {
    weak var delegate: AboutHeaderViewDelegate?

    private lazy var logo: UIImageView = {
        let logo = UIImageView(image: AppInfo.config.wordmark)
        return logo
    }()

    private lazy var aboutParagraph: UILabel = {
        let bulletStyle = NSMutableParagraphStyle()
        bulletStyle.firstLineHeadIndent = 15
        bulletStyle.headIndent = 29.5
        let bulletAttributes: [NSAttributedString.Key: Any] = [.paragraphStyle: bulletStyle]
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
            NSAttributedString(string: String(format: UIConstants.strings.aboutMissionLabel, AppInfo.productName))
            ]

        let attributed = NSMutableAttributedString()
        paragraph.forEach { attributed.append($0) }

        let aboutParagraph = SmartLabel()
        aboutParagraph.attributedText = attributed
        aboutParagraph.textColor = .secondaryLabel
        aboutParagraph.font = UIConstants.fonts.aboutText
        aboutParagraph.numberOfLines = 0
        return aboutParagraph
    }()

    private lazy var versionNumber: UILabel = {
        let label = SmartLabel()
        label.text = "\(AppInfo.shortVersion) (\(AppInfo.buildNumber)) / \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        label.font = UIConstants.fonts.aboutText
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var learnMoreButton: UIButton = {
        let learnMoreButton = UIButton()
        learnMoreButton.setTitle(UIConstants.strings.aboutLearnMoreButton, for: .normal)
        learnMoreButton.setTitleColor(.accent, for: .normal)
        learnMoreButton.setTitleColor(.accent, for: .highlighted)
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
