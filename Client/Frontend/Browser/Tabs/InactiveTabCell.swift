// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import SnapKit
import UIKit
import Shared
import SwiftUI

enum InactiveTabSection: Int, CaseIterable {
    case inactive
    case closeAllTabsButton
}

protocol InactiveTabsDelegate {
    func toggleInactiveTabSection(hasExpanded: Bool)
    func didSelectInactiveTab(tab: Tab?)
    func didTapCloseAllTabs()
    func shouldCloseInactiveTab(tab: Tab)
}

struct InactiveTabCellUX {
    static let HeaderAndRowHeight: CGFloat = 48
    static let CloseAllTabRowHeight: CGFloat = 100
    static let RoundedContainerPaddingClosed: CGFloat = 30
    static let RoundedContainerAdditionalPaddingOpened: CGFloat  = 40
    static let InactiveTabTrayWidthPadding: CGFloat = 30
}

class InactiveTabCell: UICollectionViewCell, NotificationThemeable, UITableViewDataSource, UITableViewDelegate {
    var inactiveTabsViewModel: InactiveTabViewModel?
    static let Identifier = "InactiveTabCellIdentifier"
    let InactiveTabsTableIdentifier = "InactiveTabsTableIdentifier"
    let InactiveTabsCloseAllButtonIdentifier = "InactiveTabsCloseAllButtonIdentifier"
    let InactiveTabsHeaderIdentifier = "InactiveTabsHeaderIdentifier"
    var hasExpanded = false
    var delegate: InactiveTabsDelegate?
    
    // Views
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(OneLineTableViewCell.self, forCellReuseIdentifier: InactiveTabsTableIdentifier)
        tableView.register(CellWithRoundedButton.self, forCellReuseIdentifier: InactiveTabsCloseAllButtonIdentifier)
        tableView.register(InactiveTabHeader.self, forHeaderFooterViewReuseIdentifier: InactiveTabsHeaderIdentifier)
        tableView.allowsMultipleSelectionDuringEditing = false
        tableView.sectionHeaderHeight = 0
        tableView.sectionFooterHeight = 0
        tableView.tableHeaderView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 0, height: CGFloat.leastNormalMagnitude)))
        tableView.separatorStyle = .none
        tableView.separatorColor = .clear
        tableView.isScrollEnabled = false
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
    
    lazy private var containerView: UIView = .build { view in
        view.layer.cornerRadius = 13
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.clear.cgColor
    }

    convenience init(viewModel: InactiveTabViewModel) {
        self.init()
        inactiveTabsViewModel = viewModel
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        containerView.addSubviews(tableView)
        addSubviews(containerView)
        setupConstraints()
        applyTheme()
        setupNotifcation()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupNotifcation() {
        NotificationCenter.default.addObserver(self, selector: #selector(applyTheme), name: .DisplayThemeChanged, object: nil)
    }
    
    private func setupConstraints() {
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(5)
            make.bottom.equalToSuperview().offset(-5)
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(containerView).offset(10)
            make.bottom.equalTo(containerView).offset(-10)
            make.leading.equalTo(containerView)
            make.trailing.equalTo(containerView)
        }
        
        self.bringSubviewToFront(tableView)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return InactiveTabSection.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !hasExpanded { return 0 }
        switch InactiveTabSection(rawValue: section) {
        case .inactive:
            return inactiveTabsViewModel?.inactiveTabs.count ?? 0
        case .closeAllTabsButton:
            return 1
        case .none:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch InactiveTabSection(rawValue: indexPath.section) {
        case .inactive, .none:
            return InactiveTabCellUX.HeaderAndRowHeight
        case .closeAllTabsButton:
            return InactiveTabCellUX.CloseAllTabRowHeight
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch InactiveTabSection(rawValue: indexPath.section) {
        case .inactive:
            let cell = tableView.dequeueReusableCell(withIdentifier: InactiveTabsTableIdentifier, for: indexPath) as! OneLineTableViewCell
            cell.customization = .inactiveCell
            cell.backgroundColor = .clear
            cell.accessoryView = nil
            guard let tab = inactiveTabsViewModel?.inactiveTabs[indexPath.item] else { return cell }
            cell.titleLabel.text = tab.displayTitle
            cell.leftImageView.setImageAndBackground(forIcon: tab.displayFavicon, website: getTabDomainUrl(tab: tab)) {}
            cell.shouldLeftAlignTitle = false
            cell.updateMidConstraint()
            cell.accessoryType = .none
            return cell
        case .closeAllTabsButton:
            if let closeAllButtonCell = tableView.dequeueReusableCell(withIdentifier: InactiveTabsCloseAllButtonIdentifier, for: indexPath) as? CellWithRoundedButton {
                closeAllButtonCell.buttonClosure = {
                    self.delegate?.didTapCloseAllTabs()
                }
                return closeAllButtonCell
            }
            return tableView.dequeueReusableCell(withIdentifier: InactiveTabsTableIdentifier, for: indexPath) as! OneLineTableViewCell
        case .none:
            return tableView.dequeueReusableCell(withIdentifier: InactiveTabsTableIdentifier, for: indexPath) as! OneLineTableViewCell
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if !hasExpanded { return nil }
        switch InactiveTabSection(rawValue: section) {
        case .inactive, .none, .closeAllTabsButton:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if !hasExpanded { return CGFloat.leastNormalMagnitude }
        switch InactiveTabSection(rawValue: section) {
        case .inactive, .none, .closeAllTabsButton:
            return CGFloat.leastNormalMagnitude
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let section = indexPath.section
        switch InactiveTabSection(rawValue: section) {
        case .inactive:
            if let tab = inactiveTabsViewModel?.inactiveTabs[indexPath.item] {
                delegate?.didSelectInactiveTab(tab: tab)
            }
        case .closeAllTabsButton, .none:
            print("nothing")
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch InactiveTabSection(rawValue: section) {
        case .inactive, .none:
            guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: InactiveTabsHeaderIdentifier) as? InactiveTabHeader else { return nil }
            headerView.state = hasExpanded ? .down : .right
            headerView.title = String.TabsTrayInactiveTabsSectionTitle
            headerView.moreButton.isHidden = false
            headerView.moreButton.addTarget(self, action: #selector(toggleInactiveTabSection), for: .touchUpInside)
            headerView.contentView.backgroundColor = .clear
            return headerView
        case .closeAllTabsButton:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        let section = indexPath.section
        switch InactiveTabSection(rawValue: section) {
        case .inactive:
            return .delete
        case .closeAllTabsButton, .none:
            return .none
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let section = indexPath.section
        guard editingStyle == .delete else { return }
        switch InactiveTabSection(rawValue: section) {
        case .inactive:
            if let tab = inactiveTabsViewModel?.inactiveTabs[indexPath.item] {
                delegate?.shouldCloseInactiveTab(tab: tab)
            }
        case .closeAllTabsButton, .none: return
        }
    }
    
    @objc func toggleInactiveTabSection() {
        hasExpanded = !hasExpanded
        tableView.reloadData()
        delegate?.toggleInactiveTabSection(hasExpanded: hasExpanded)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch InactiveTabSection(rawValue: section) {
        case .inactive, .none:
            return InactiveTabCellUX.HeaderAndRowHeight
        case .closeAllTabsButton:
            return CGFloat.leastNormalMagnitude
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        switch InactiveTabSection(rawValue: section) {
        case .inactive, .none:
            return InactiveTabCellUX.HeaderAndRowHeight
        case .closeAllTabsButton:
            return CGFloat.leastNormalMagnitude
        }
    }
    
    func getTabDomainUrl(tab: Tab) -> URL? {
        guard tab.url != nil else {
            return tab.sessionData?.urls.last?.domainURL
        }
        return tab.url?.domainURL
    }

    @objc func applyTheme() {
        self.backgroundColor = .clear
        self.tableView.backgroundColor = .clear
        tableView.reloadData()
        let theme = BuiltinThemeName(rawValue: LegacyThemeManager.instance.current.name) ?? .normal
        containerView.backgroundColor = theme == .normal ? .white : .Photon.DarkGrey50
    }
}

enum ExpandButtonState {
    case right
    case down
    
    var image: UIImage {
        switch self {
        case .right:
            return UIImage(named: "menu-Disclosure")!
        case .down:
            return UIImage(named: "find_next")!
        }
    }
}

class InactiveTabHeader: UITableViewHeaderFooterView, NotificationThemeable {
    var state: ExpandButtonState? {
        willSet(state) {
            moreButton.setImage(state?.image, for: .normal)
        }
    }
    
    lazy var containerView: UIView = {
        let containerView = UIView()
        return titleLabel
    }()
    
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = self.title
        titleLabel.textColor = UIColor.theme.homePanel.activityStreamHeaderText
        titleLabel.font = UIFont.systemFont(ofSize: GroupedTabCellProperties.CellUX.titleFontSize, weight: .semibold)
        titleLabel.minimumScaleFactor = 0.6
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        return titleLabel
    }()
    
    lazy var moreButton: UIButton = {
        let button = UIButton()
        button.isHidden = true
        button.setImage(state?.image, for: .normal)
        button.contentHorizontalAlignment = .right
        return button
    }()

    var title: String? {
        willSet(newTitle) {
            titleLabel.text = newTitle
        }
    }

    var titleInsets: CGFloat {
        get {
            return UIScreen.main.bounds.size.width == self.frame.size.width && UIDevice.current.userInterfaceIdiom == .pad ? FirefoxHomeHeaderViewUX.insets : FirefoxHomeUX.minimumInsets
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
        moreButton.setTitle(nil, for: .normal)
        moreButton.accessibilityIdentifier = nil;
        titleLabel.text = nil
        moreButton.removeTarget(nil, action: nil, for: .allEvents)
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.addSubview(titleLabel)
        contentView.addSubview(moreButton)
        
        moreButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.equalTo(titleLabel.snp.trailing)
            make.top.equalToSuperview().offset(12.5)
            make.trailing.equalTo(self.safeArea.trailing).inset(28)
        }
        
        moreButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12.5)
            make.leading.equalTo(self.safeArea.leading).offset(16)
            make.centerX.equalToSuperview()
        }
        
        applyTheme()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme() {
        let theme = BuiltinThemeName(rawValue: LegacyThemeManager.instance.current.name) ?? .normal
        self.titleLabel.textColor = theme == .dark ? .white : .black
    }
}
