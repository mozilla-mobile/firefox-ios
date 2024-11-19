// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit
import Shared
import SwiftUI

enum InactiveTabSection: Int, CaseIterable {
    case inactive
    case closeAllTabsButton
}

protocol LegacyInactiveTabsDelegate: AnyObject {
    func toggleInactiveTabSection(hasExpanded: Bool)
    func didSelectInactiveTab(tab: Tab?)
    func didTapCloseInactiveTabs(tabsCount: Int)
    func closeInactiveTab(_ tab: Tab, index: Int)
    func setupCFR(with view: UILabel)
    func presentCFR()
}

class LegacyInactiveTabCell: UICollectionViewCell, ReusableCell, ThemeApplicable {
    struct UX {
        static let HeaderAndRowHeight: CGFloat = 48
        static let CloseAllTabRowHeight: CGFloat = 88
        static let RoundedContainerPaddingClosed: CGFloat = 30
        static let RoundedContainerAdditionalPaddingOpened: CGFloat  = 40
        static let InactiveTabTrayWidthPadding: CGFloat = 30
    }

    // MARK: - Properties
    var inactiveTabsViewModel: LegacyInactiveTabViewModel?
    var hasExpanded = false
    weak var delegate: LegacyInactiveTabsDelegate?

    // Views
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(LegacyInactiveTabButton.self,
                           forCellReuseIdentifier: LegacyInactiveTabButton.cellIdentifier)
        tableView.register(LegacyInactiveTabHeader.self,
                           forHeaderFooterViewReuseIdentifier: LegacyInactiveTabHeader.cellIdentifier)
        tableView.allowsMultipleSelectionDuringEditing = false
        tableView.sectionHeaderHeight = 0
        tableView.sectionFooterHeight = 0
        tableView.tableHeaderView = UIView(
            frame: CGRect(
                origin: .zero,
                size: CGSize(width: 0, height: CGFloat.leastNormalMagnitude)
            )
        )
        tableView.separatorStyle = .none
        tableView.separatorColor = .clear
        tableView.isScrollEnabled = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private var containerView: UIView = .build { view in
        view.layer.cornerRadius = 13
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.clear.cgColor
    }

    // MARK: - Initializers
    convenience init(viewModel: LegacyInactiveTabViewModel) {
        self.init()
        inactiveTabsViewModel = viewModel
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        containerView.addSubviews(tableView)
        addSubviews(containerView)
        setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),

            tableView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        self.bringSubviewToFront(tableView)
    }

    // MARK: ThemeApplicable

    func applyTheme(theme: Theme) {
        inactiveTabsViewModel?.theme = theme
        backgroundColor = .clear
        tableView.backgroundColor = .clear
        containerView.backgroundColor = theme.colors.layer2
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension LegacyInactiveTabCell: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return InactiveTabSection.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let viewModel = inactiveTabsViewModel,
              hasExpanded,
              !viewModel.shouldHideInactiveTabs else { return 0 }

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
            return LegacyInactiveTabCell.UX.HeaderAndRowHeight
        case .closeAllTabsButton:
            return UITableView.automaticDimension
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch InactiveTabSection(rawValue: indexPath.section) {
        case .inactive:
            return UITableViewCell()

        case .closeAllTabsButton:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: LegacyInactiveTabButton.cellIdentifier,
                                                           for: indexPath) as? LegacyInactiveTabButton
            else {
                return UITableViewCell()
            }

            cell.buttonClosure = { [weak self] in
                let inactiveTabsCount = self?.inactiveTabsViewModel?.inactiveTabs.count
                self?.delegate?.didTapCloseInactiveTabs(tabsCount: inactiveTabsCount ?? 0)
            }
            if let theme = inactiveTabsViewModel?.theme {
                cell.applyTheme(theme: theme)
            }

            return cell
        case .none:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: OneLineTableViewCell.cellIdentifier,
                                                           for: indexPath) as? OneLineTableViewCell
            else {
                return UITableViewCell()
            }
            if let theme = inactiveTabsViewModel?.theme {
                cell.applyTheme(theme: theme)
            }
            return cell
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
            break
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch InactiveTabSection(rawValue: section) {
        case .inactive, .none:
            guard let headerView = tableView.dequeueReusableHeaderFooterView(
                withIdentifier: LegacyInactiveTabHeader.cellIdentifier
            ) as? LegacyInactiveTabHeader else { return nil }
            headerView.state = hasExpanded ? .down : .trailing
            headerView.title = String.TabsTrayInactiveTabsSectionTitle
            headerView.accessibilityLabel = hasExpanded ?
                .TabsTray.InactiveTabs.TabsTrayInactiveTabsSectionOpenedAccessibilityTitle :
                .TabsTray.InactiveTabs.TabsTrayInactiveTabsSectionClosedAccessibilityTitle
            headerView.moreButton.isHidden = false
            headerView.moreButton.addTarget(self,
                                            action: #selector(toggleInactiveTabSection),
                                            for: .touchUpInside)
            headerView.contentView.backgroundColor = .clear

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleInactiveTabSection))
            headerView.addGestureRecognizer(tapGesture)

            delegate?.setupCFR(with: headerView.titleLabel)

            return headerView

        case .closeAllTabsButton:
            return nil
        }
    }

    func tableView(
        _ tableView: UITableView,
        editingStyleForRowAt indexPath: IndexPath
    ) -> UITableViewCell.EditingStyle {
        let section = indexPath.section
        switch InactiveTabSection(rawValue: section) {
        case .inactive:
            return .delete
        case .closeAllTabsButton, .none:
            return .none
        }
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let configuration: UISwipeActionsConfiguration?
        let section = indexPath.section

        switch InactiveTabSection(rawValue: section) {
        case .inactive:
            let closeAction = UIContextualAction(
                style: .destructive,
                title: .TabsTray.InactiveTabs.CloseInactiveTabSwipeActionTitle
            ) { [weak self] _, _, completion in
                if let tab = self?.inactiveTabsViewModel?.inactiveTabs[indexPath.item] {
                    self?.removeInactiveTab(at: indexPath)
                    self?.delegate?.closeInactiveTab(tab, index: indexPath.item)
                    completion(true)
                }
            }
            configuration = UISwipeActionsConfiguration(actions: [closeAction])
        case .closeAllTabsButton, .none: return nil
        }
        return configuration
    }

    private func removeInactiveTab(at indexPath: IndexPath) {
        inactiveTabsViewModel?.inactiveTabs.remove(at: indexPath.item)
        tableView.deleteRows(at: [indexPath], with: .fade)
    }

    @objc
    func toggleInactiveTabSection() {
        hasExpanded = !hasExpanded
        tableView.reloadData()
        delegate?.toggleInactiveTabSection(hasExpanded: hasExpanded)

        // Post accessibility notification when the section was opened/closed
        UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: nil)

        if hasExpanded { delegate?.presentCFR() }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        switch InactiveTabSection(rawValue: section) {
        case .inactive, .none:
            return LegacyInactiveTabCell.UX.HeaderAndRowHeight
        case .closeAllTabsButton:
            return CGFloat.leastNormalMagnitude
        }
    }

    func getTabDomainUrl(tab: Tab) -> URL? {
        return tab.url?.domainURL
    }
}
