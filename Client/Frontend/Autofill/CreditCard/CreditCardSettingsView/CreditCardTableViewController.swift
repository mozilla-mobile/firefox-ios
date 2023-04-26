// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import Storage
import SwiftUI
import UIKit

class CreditCardTableViewController: UIViewController, Themeable {
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

    var viewModel: CreditCardTableViewModel
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol
    var didSelectCardAtIndex: ((_ creditCard: CreditCard) -> Void)?

    // MARK: View
    var toastView: UIHostingController<ToastView>

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

    init(viewModel: CreditCardTableViewModel,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.viewModel = viewModel
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter

        let toastView = ToastView(messageType: .removedCard,
                                  isShowing: true)
        self.toastView = UIHostingController(rootView: toastView)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewSetup()
        listenForThemeChange(view)
        applyTheme()
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

    private func setupToastView() {
        guard let toast = toastView.view else { return }
        toast.translatesAutoresizingMaskIntoConstraints = false

        addChild(toastView)
        view.addSubview(toast)

        NSLayoutConstraint.activate([
            toast.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toast.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            toast.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toast.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        ])
        toastView.view.backgroundColor = .clear
    }

    func applyTheme() {
        let theme = themeManager.currentTheme
        view.backgroundColor = theme.colors.layer1
        tableView.backgroundColor = theme.colors.layer1
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

        let headerView = CreditCardSectionHeader(textColor: themeManager.currentTheme.colors.textSecondary.color)
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
        didSelectCardAtIndex?(viewModel.creditCards[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - Private
    private func toggleCell() -> UITableViewCell {
        guard let hostingCell = tableView.dequeueReusableCell(
            withIdentifier: HostingTableViewCell<CreditCardAutofillToggle>.cellIdentifier) as? HostingTableViewCell<CreditCardAutofillToggle>,
              let model = viewModel.toggleModel else {
            return UITableViewCell(style: .default, reuseIdentifier: "ClientCell")
        }

        let row = CreditCardAutofillToggle(textColor: themeManager.currentTheme.colors.textPrimary.color,
                                           model: model)
        hostingCell.host(row, parentController: self)
        return hostingCell
    }

    private func creditCardCell(indexPath: IndexPath) -> UITableViewCell {
        guard let hostingCell = tableView.dequeueReusableCell(
            withIdentifier: HostingTableViewCell<CreditCardItemRow>.cellIdentifier) as? HostingTableViewCell<CreditCardItemRow> else {
            return UITableViewCell(style: .default, reuseIdentifier: "ClientCell")
        }

        let creditCard = viewModel.creditCards[indexPath.row]
        let creditCardRow = CreditCardItemRow(
            item: creditCard,
            isAccessibilityCategory: UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory)
        hostingCell.host(creditCardRow, parentController: self)
        hostingCell.accessibilityAttributedLabel = viewModel.a11yLabel(for: indexPath)
        hostingCell.isAccessibilityElement = true
        return hostingCell
    }
}
