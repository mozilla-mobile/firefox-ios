// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import SwiftUI
import Storage
import Shared

class CreditCardTableViewController: UIViewController, ThemeApplicable {
    var viewModel: CreditCardTableViewModel
    var theme: Theme
    var isToggled = true

    // MARK: View
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(HostingTableViewCell<CreditCardItemRow>.self,
                           forCellReuseIdentifier: HostingTableViewCell<CreditCardItemRow>.cellIdentifier)
        tableView.register(HostingTableViewCell<CreditCardAutofillToggle>.self,
                           forCellReuseIdentifier: HostingTableViewCell<CreditCardAutofillToggle>.cellIdentifier)
        tableView.register(
            HostingTableViewSectionHeader<CreditCardSectionHeader>.self,
            forHeaderFooterViewReuseIdentifier: HostingTableViewSectionHeader<CreditCardSectionHeader>.cellIdentifier)
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.sectionFooterHeight = 0
        tableView.tableHeaderView = UIView(frame: CGRect(
            origin: .zero,
            size: CGSize(width: 0, height: CGFloat.leastNormalMagnitude)))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 86
        tableView.separatorStyle = .none
        tableView.separatorColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    init(theme: Theme, viewModel: CreditCardTableViewModel) {
        self.theme = theme
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        applyTheme(theme: theme)
        viewSetup()
    }

    private func viewSetup() {
        view.addSubview(tableView)

        viewModel.didUpdateCreditCards = { [weak self] in
            self?.reloadData()
        }

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        view.bringSubviewToFront(tableView)
    }

    func applyTheme(theme: Theme) {
//        toggleSwitchContainerLine.backgroundColor = theme.colors.borderPrimary
//        toggleSwitchContainer.backgroundColor = theme.colors.layer2
//        tableView.backgroundColor = .clear
//        toggleSwitch.onTintColor = theme.colors.actionPrimary
        view.backgroundColor = theme.colors.layer1
    }

    @objc private func autofillToggleTapped() {
        viewModel.updateToggle()
//        updateToggleValue(value: viewModel.isAutofillEnabled)
    }

    func reloadData() {
        tableView.reloadData()
    }

//    func updateToggleValue(value: Bool) {
//        toggleSwitch.setOn(value, animated: true)
//    }
}

extension CreditCardTableViewController: UITableViewDelegate,
                                         UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : viewModel.creditCards.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section > 0,
                let hostingCell = tableView.dequeueReusableHeaderFooterView(
                    withIdentifier: HostingTableViewSectionHeader<CreditCardSectionHeader>.cellIdentifier) as? HostingTableViewSectionHeader<CreditCardSectionHeader>
        else { return nil }

        let headerView = CreditCardSectionHeader(textColor: Color(theme.colors.textSecondary))
        hostingCell.host(headerView, parentController: self)
        return hostingCell
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return toggleCell()
        } else {
            return creditCardCell(indexPath: indexPath)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - Private
    private func toggleCell() -> UITableViewCell {
        guard let hostingCell = tableView.dequeueReusableCell(
            withIdentifier: HostingTableViewCell<CreditCardAutofillToggle>.cellIdentifier) as? HostingTableViewCell<CreditCardAutofillToggle> else {
            return UITableViewCell(style: .default, reuseIdentifier: "ClientCell")
        }

        let row = CreditCardAutofillToggle(textColor: Color(theme.colors.textPrimary), isToggleOn: isToggled)
        hostingCell.host(row, parentController: self)
        return hostingCell
    }

    private func creditCardCell(indexPath: IndexPath) -> UITableViewCell {
        guard let hostingCell = tableView.dequeueReusableCell(
            withIdentifier: HostingTableViewCell<CreditCardItemRow>.cellIdentifier) as? HostingTableViewCell<CreditCardItemRow> else {
            return UITableViewCell(style: .default, reuseIdentifier: "ClientCell")
        }

        let titleTextColor = Color(theme.colors.textPrimary)
        let subTextColor = Color(theme.colors.textSecondary)
        let separatorColor = Color(theme.colors.borderPrimary)
        let colors = CreditCardItemRow.Colors(
            titleTextColor: titleTextColor,
            subTextColor: subTextColor,
            separatorColor: separatorColor)

        let creditCard = viewModel.creditCards[indexPath.row]

        let creditCardRow = CreditCardItemRow(
            item: creditCard,
            colors: colors,
            isAccessibilityCategory: UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory)
        hostingCell.host(creditCardRow, parentController: self)
        return hostingCell
    }
}
