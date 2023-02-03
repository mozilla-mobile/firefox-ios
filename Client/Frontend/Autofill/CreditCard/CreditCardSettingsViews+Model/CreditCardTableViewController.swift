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

    // MARK: View
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(HostingTableViewCell<CreditCardItemRow>.self,
                           forCellReuseIdentifier: HostingTableViewCell<CreditCardItemRow>.cellIdentifier)
        tableView.sectionHeaderHeight = 0
        tableView.sectionFooterHeight = 0
        tableView.tableHeaderView = UIView(frame: CGRect(
            origin: .zero,
            size: CGSize(width: 0, height: CGFloat.leastNormalMagnitude)))
        tableView.separatorStyle = .none
        tableView.separatorColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private var toggleSwitchContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var toggleSwitchContainerLine: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var toggleSwitchLabel: UILabel = {
        var toggleSwitchLabel = UILabel()
        toggleSwitchLabel.font = UIFont.systemFont(ofSize: 17.0,
                                                   weight: UIFont.Weight.regular)
        toggleSwitchLabel.numberOfLines = 1
        toggleSwitchLabel.text = String.CreditCard.EditCard.ToggleToAllowAutofillTitle
        toggleSwitchLabel.translatesAutoresizingMaskIntoConstraints = false
        return toggleSwitchLabel
    }()

    private var toggleSwitch: UISwitch = .build { toggleSwitch in
        toggleSwitch.addTarget(self,
                               action: #selector(autofillToggleTapped),
                               for: .valueChanged)
        toggleSwitch.translatesAutoresizingMaskIntoConstraints = false
    }

    private var savedCardsTitleLabel: UILabel = {
        var savedCardsTitleLabel = UILabel()
        savedCardsTitleLabel.font = UIFont.systemFont(ofSize: 12.0,
                                                      weight: UIFont.Weight.regular)
        savedCardsTitleLabel.numberOfLines = 1
        savedCardsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        savedCardsTitleLabel.text = String.CreditCard.EditCard.SavedCardListTitle
        return savedCardsTitleLabel
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
        view.addSubview(toggleSwitchContainer)
        toggleSwitchContainer.addSubview(toggleSwitchLabel)
        toggleSwitchContainer.addSubview(toggleSwitch)
        toggleSwitchContainer.addSubview(toggleSwitchContainerLine)
        view.addSubview(savedCardsTitleLabel)
        view.addSubview(tableView)

        toggleSwitch.setOn(viewModel.autofillCreditCardStatus, animated: true)

        viewModel.didUpdadteCreditCards = { [weak self] in
            self?.reloadData()
        }

        NSLayoutConstraint.activate([
            toggleSwitchContainer.topAnchor.constraint(equalTo: view.topAnchor),
            toggleSwitchContainer.heightAnchor.constraint(equalToConstant: 40),
            toggleSwitchContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toggleSwitchContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            toggleSwitch.centerYAnchor.constraint(
                equalTo: toggleSwitchContainer.centerYAnchor),
            toggleSwitch.trailingAnchor.constraint(equalTo: toggleSwitchContainer.trailingAnchor, constant: -16),

            toggleSwitchLabel.centerYAnchor.constraint(
                equalTo: toggleSwitchContainer.centerYAnchor),
            toggleSwitchLabel.leadingAnchor.constraint(equalTo: toggleSwitchContainer.leadingAnchor, constant: 16),
            toggleSwitchLabel.heightAnchor.constraint(equalToConstant: 18),

            toggleSwitchContainerLine.heightAnchor.constraint(equalToConstant: 0.7),
            toggleSwitchContainerLine.leadingAnchor.constraint(
                equalTo: toggleSwitchContainer.leadingAnchor, constant: 10),
            toggleSwitchContainerLine.trailingAnchor.constraint(
                equalTo: toggleSwitchContainer.trailingAnchor, constant: 10),
            toggleSwitchContainerLine.bottomAnchor.constraint(
                equalTo: toggleSwitchContainer.bottomAnchor),

            savedCardsTitleLabel.topAnchor.constraint(equalTo: toggleSwitchContainer.bottomAnchor, constant: 25),
            savedCardsTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            savedCardsTitleLabel.heightAnchor.constraint(equalToConstant: 13),
            savedCardsTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: savedCardsTitleLabel.bottomAnchor, constant: 8),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        view.bringSubviewToFront(tableView)
    }

    func applyTheme(theme: Theme) {
        toggleSwitchContainerLine.backgroundColor = theme.colors.borderPrimary
        toggleSwitchContainer.backgroundColor = theme.colors.layer2
        tableView.backgroundColor = .clear// theme.colors.layer2
        toggleSwitch.onTintColor = theme.colors.actionPrimary
        view.backgroundColor = theme.colors.layer1
    }

    @objc private func autofillToggleTapped() {
        viewModel.updateToggle()
        updateToggleValue(value: viewModel.autofillCreditCardStatus)
    }

    func reloadData() {
        tableView.reloadData()
    }

    func updateToggleValue(value: Bool) {
        toggleSwitch.setOn(value, animated: true)
    }
}

extension CreditCardTableViewController: UITableViewDelegate,
                                         UITableViewDataSource {
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return viewModel.creditCards.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let hostingCell = tableView.dequeueReusableCell(
            withIdentifier: HostingTableViewCell<CreditCardItemRow>.cellIdentifier) as? HostingTableViewCell<CreditCardItemRow> else {
            return UITableViewCell(style: .default, reuseIdentifier: "ClientCell")
        }

        let titleTextColor = Color(theme.colors.textPrimary)
        let subTextColor = Color(theme.colors.textSecondary)
        let separatorColor = Color(theme.colors.borderPrimary)
        let ux = CreditCardItemRowUX(
            titleTextColor: titleTextColor,
            subTextColor: subTextColor,
            separatorColor: separatorColor)

        let creditCard = viewModel.creditCards[indexPath.row]

        let creditCardRow = CreditCardItemRow(item: creditCard, ux: ux)
        hostingCell.host(creditCardRow, parentController: self)

        return hostingCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
