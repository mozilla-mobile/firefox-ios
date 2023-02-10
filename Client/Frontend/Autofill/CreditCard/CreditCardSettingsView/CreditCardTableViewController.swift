// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import SwiftUI
import Storage
import Common
import Shared

class CreditCardTableViewController: UIViewController, Themeable {
    var viewModel: CreditCardTableViewModel
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol

    // MARK: UX constants
    struct UX {
        static let toggleSwitchContainerHeight: CGFloat = 40
        static let toggleSwitchAnchor: CGFloat = -16
        static let toggleSwitchLabelHeight: CGFloat = 18
        static let toggleSwitchContainerLineHeight: CGFloat = 0.7
        static let toggleSwitchContainerLineAnchor: CGFloat = 10
        static let savedCardsTitleLabelBottomAnchor: CGFloat = 25
        static let savedCardsTitleLabelLeading: CGFloat = 16
        static let savedCardsTitleLabelHeight: CGFloat = 13
        static let tableViewTopAnchor: CGFloat = 8
    }

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

    private var toggleSwitchContainer: UIView = .build { view in }

    private var toggleSwitchContainerLine: UIView = .build { view in }

    private var toggleSwitchLabel: UILabel = .build { toggleSwitchLabel in
        toggleSwitchLabel.font = UIFont.systemFont(ofSize: 17.0,
                                                   weight: UIFont.Weight.regular)
        toggleSwitchLabel.numberOfLines = 1
        toggleSwitchLabel.text = String.CreditCard.EditCard.ToggleToAllowAutofillTitle
    }

    private var toggleSwitch: UISwitch = .build { toggleSwitch in
        toggleSwitch.addTarget(CreditCardTableViewController.self,
                               action: #selector(autofillToggleTapped),
                               for: .valueChanged)
        toggleSwitch.translatesAutoresizingMaskIntoConstraints = false
    }

    private var savedCardsTitleLabel: UILabel = .build { savedCardsTitleLabel in
        savedCardsTitleLabel.font = UIFont.systemFont(ofSize: 12.0,
                                                      weight: UIFont.Weight.regular)
        savedCardsTitleLabel.numberOfLines = 1
        savedCardsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        savedCardsTitleLabel.text = String.CreditCard.EditCard.SavedCardListTitle
    }

    init(viewModel: CreditCardTableViewModel,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.viewModel = viewModel
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewSetup()
        listenForThemeChange()
        applyTheme()
    }

    private func viewSetup() {
        view.addSubview(toggleSwitchContainer)
        toggleSwitchContainer.addSubview(toggleSwitchLabel)
        toggleSwitchContainer.addSubview(toggleSwitch)
        toggleSwitchContainer.addSubview(toggleSwitchContainerLine)
        view.addSubview(savedCardsTitleLabel)
        view.addSubview(tableView)

        toggleSwitch.setOn(viewModel.isAutofillEnabled, animated: true)

        viewModel.didUpdateCreditCards = { [weak self] in
            self?.reloadData()
        }

        NSLayoutConstraint.activate([
            toggleSwitchContainer.topAnchor.constraint(equalTo: view.topAnchor),
            toggleSwitchContainer.heightAnchor.constraint(equalToConstant: UX.toggleSwitchContainerHeight),
            toggleSwitchContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toggleSwitchContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            toggleSwitch.centerYAnchor.constraint(
                equalTo: toggleSwitchContainer.centerYAnchor),
            toggleSwitch.trailingAnchor.constraint(equalTo: toggleSwitchContainer.trailingAnchor, constant: -UX.toggleSwitchAnchor),

            toggleSwitchLabel.centerYAnchor.constraint(
                equalTo: toggleSwitchContainer.centerYAnchor),
            toggleSwitchLabel.leadingAnchor.constraint(equalTo: toggleSwitchContainer.leadingAnchor, constant: UX.toggleSwitchAnchor),
            toggleSwitchLabel.heightAnchor.constraint(equalToConstant: UX.toggleSwitchLabelHeight),

            toggleSwitchContainerLine.heightAnchor.constraint(equalToConstant: UX.toggleSwitchContainerLineHeight),
            toggleSwitchContainerLine.leadingAnchor.constraint(
                equalTo: toggleSwitchContainer.leadingAnchor, constant: UX.toggleSwitchContainerLineAnchor),
            toggleSwitchContainerLine.trailingAnchor.constraint(
                equalTo: toggleSwitchContainer.trailingAnchor, constant: UX.toggleSwitchContainerLineAnchor),
            toggleSwitchContainerLine.bottomAnchor.constraint(
                equalTo: toggleSwitchContainer.bottomAnchor),

            savedCardsTitleLabel.topAnchor.constraint(equalTo: toggleSwitchContainer.bottomAnchor, constant: UX.savedCardsTitleLabelBottomAnchor),
            savedCardsTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.savedCardsTitleLabelLeading),
            savedCardsTitleLabel.heightAnchor.constraint(equalToConstant: UX.savedCardsTitleLabelHeight),
            savedCardsTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: savedCardsTitleLabel.bottomAnchor, constant: UX.tableViewTopAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        view.bringSubviewToFront(tableView)
    }

    func applyTheme() {
        let theme = themeManager.currentTheme
        toggleSwitchContainerLine.backgroundColor = theme.colors.borderPrimary
        toggleSwitchContainer.backgroundColor = theme.colors.layer2
        tableView.backgroundColor = .clear
        toggleSwitch.onTintColor = theme.colors.actionPrimary
        view.backgroundColor = theme.colors.layer1
    }

    @objc private func autofillToggleTapped() {
        viewModel.updateToggle()
        toggleSwitch.setOn(viewModel.isAutofillEnabled, animated: true)
    }

    func reloadData() {
        tableView.reloadData()
    }

    deinit {
        notificationCenter.removeObserver(self)
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

        let theme = themeManager.currentTheme
        let titleTextColor = Color(theme.colors.textPrimary)
        let subTextColor = Color(theme.colors.textSecondary)
        let separatorColor = Color(theme.colors.borderPrimary)
        let colors = CreditCardItemRow.Colors(
            titleTextColor: titleTextColor,
            subTextColor: subTextColor,
            separatorColor: separatorColor)

        let creditCard = viewModel.creditCards[indexPath.row]

        let creditCardRow = CreditCardItemRow(item: creditCard,
                                              colors: colors)
        hostingCell.host(creditCardRow, parentController: self)

        return hostingCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
