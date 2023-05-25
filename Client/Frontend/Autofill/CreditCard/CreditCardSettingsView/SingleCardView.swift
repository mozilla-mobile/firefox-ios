// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import Storage
import Common

import Foundation
import UIKit

class SingleCreditCardViewController: UIViewController, BottomSheetChild {
    // MARK: UX
    struct SingleCardViewControllerUX {
        static let tableMargin: CGFloat = 0
        static let distanceBetweenHeaderAndTop: CGFloat = -10
        static let distanceBetweenButtonAndTable: CGFloat = 77
        static let distanceBetweenHeaderAndCells: CGFloat = 24
        static let yesButtonCornerRadius: CGFloat = 13
        static let yesButtonFontSize: CGFloat = 16.0
        static let yesButtonHeight: CGFloat = 45.0
        static let bottomSpacing: CGFloat = 32.0
        static let buttonsSpacing: CGFloat = 8.0
        static let contentViewWidth: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 545 : 339
        static let headerPrefferredHeight: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 64 + 24 : 84 + 24
        static let estimatedRowHeight: CGFloat = 86
    }
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var creditCard: CreditCard

    // MARK: Views
    // a content view to hold everything
    private lazy var contentView: UIView = .build { _ in }
    private lazy var cardTableView: UITableView = {
        let cardTableView = UITableView(frame: .zero, style: .plain)
        cardTableView.translatesAutoresizingMaskIntoConstraints = false
        cardTableView.showsHorizontalScrollIndicator = false
        cardTableView.backgroundColor = .clear
        cardTableView.dataSource = self
        cardTableView.delegate = self
        cardTableView.allowsSelection = false
        cardTableView.separatorColor = .clear
        cardTableView.separatorStyle = .none
        cardTableView.isScrollEnabled = false
        cardTableView.rowHeight = UITableView.automaticDimension
        cardTableView.estimatedRowHeight = SingleCardViewControllerUX.estimatedRowHeight
        cardTableView.estimatedSectionHeaderHeight = SingleCardViewControllerUX.headerPrefferredHeight
        cardTableView.register(HostingTableViewCell<CreditCardItemRow>.self,
                               forCellReuseIdentifier: HostingTableViewCell<CreditCardItemRow>.cellIdentifier)
        cardTableView.register(SaveCardTableHeaderView.self, forHeaderFooterViewReuseIdentifier: SaveCardTableHeaderView.cellIdentifier)
        return cardTableView
    }()

    let buttonsContainerStackView: UIStackView = .build { stack in
//        stack.backgroundColor = .blue
        stack.distribution = .fillEqually
        stack.alignment = .fill
        stack.axis = .vertical
        stack.spacing = SingleCardViewControllerUX.buttonsSpacing
    }

    private lazy var yesButton: ResizableButton = .build { button in
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .callout,
                                                                                size: SingleCardViewControllerUX.yesButtonFontSize)
        button.addTarget(self, action: #selector(self.didTapYes), for: .touchUpInside)
        button.backgroundColor = self.themeManager.currentTheme.colors.actionPrimary
        button.setTitle(.CreditCard.RememberCard.MainButtonTitle, for: .normal)
        button.layer.cornerRadius = SingleCardViewControllerUX.yesButtonCornerRadius
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.accessibilityIdentifier = AccessibilityIdentifiers.RememberCard.yesButton
    }

    private lazy var notNowButton: ResizableButton = .build { button in
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .callout,
                                                                                size: SingleCardViewControllerUX.yesButtonFontSize)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.accessibilityIdentifier = AccessibilityIdentifiers.RememberCard.notNowButton
        button.addTarget(self, action: #selector(SingleCreditCardViewController.didTapNotNow), for: .touchUpInside)
        button.backgroundColor = self.themeManager.currentTheme.colors.actionSecondary
        button.setTitle(.CreditCard.RememberCard.SecondaryButtonTitle, for: .normal)
        button.layer.cornerRadius = SingleCardViewControllerUX.yesButtonCornerRadius
    }

    private var tableViewHeightConstraint: NSLayoutConstraint!
    // MARK: - Initializers
    init(creditCard: CreditCard,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.creditCard = creditCard
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        listenForThemeChange(view)
        setupView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
        setupView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    // MARK: View Setup
    func setupView() {
        let isIPAD = UIDevice.current.userInterfaceIdiom == .pad

        view.backgroundColor = themeManager.currentTheme.colors.layer1
        buttonsContainerStackView.addArrangedSubview(yesButton)
        if isIPAD { buttonsContainerStackView.addArrangedSubview(notNowButton) }
        contentView.addSubviews(cardTableView, buttonsContainerStackView)
        view.addSubview(contentView)

        let headerHeight = SingleCardViewControllerUX.headerPrefferredHeight
        let estimatedCellHeight = cardTableView.estimatedRowHeight
        let estimatedTableHeight = headerHeight + estimatedCellHeight + SingleCardViewControllerUX.distanceBetweenHeaderAndCells + SingleCardViewControllerUX.distanceBetweenButtonAndTable

        print("estimatedTableHeight = \(estimatedTableHeight)")
        tableViewHeightConstraint = cardTableView.heightAnchor.constraint(equalToConstant: estimatedTableHeight)
        tableViewHeightConstraint.priority = UILayoutPriority(999)

        var contentViewHeight = SingleCardViewControllerUX.distanceBetweenHeaderAndTop + estimatedTableHeight + SingleCardViewControllerUX.yesButtonHeight + SingleCardViewControllerUX.bottomSpacing
        if isIPAD { contentViewHeight += SingleCardViewControllerUX.yesButtonHeight } // one more button on iPad
        print("contentViewHeight = \(contentViewHeight)")
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.widthAnchor.constraint(equalToConstant: SingleCardViewControllerUX.contentViewWidth),
            contentView.heightAnchor.constraint(equalToConstant: contentViewHeight),
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            cardTableView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: SingleCardViewControllerUX.distanceBetweenHeaderAndTop),
            cardTableView.bottomAnchor.constraint(equalTo: buttonsContainerStackView.topAnchor, constant: 0),
            cardTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: SingleCardViewControllerUX.tableMargin),
            cardTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -SingleCardViewControllerUX.tableMargin),

            buttonsContainerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -SingleCardViewControllerUX.bottomSpacing),
            buttonsContainerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: SingleCardViewControllerUX.tableMargin),
            buttonsContainerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -SingleCardViewControllerUX.tableMargin),

            yesButton.heightAnchor.constraint(equalToConstant: SingleCardViewControllerUX.yesButtonHeight),
            notNowButton.heightAnchor.constraint(equalToConstant: SingleCardViewControllerUX.yesButtonHeight),
            tableViewHeightConstraint
        ])
    }

    @objc
    func didTapYes() {
        print("didTapYes")
    }

    @objc
    func didTapNotNow() {
        print("didTapNotNow")
    }

    func willDismiss() {
    }
}

// MARK: UITableViewDelegate
extension SingleCreditCardViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return creditCardCell(indexPath: indexPath)
    }

    private func creditCardCell(indexPath: IndexPath) -> UITableViewCell {
        guard let hostingCell = cardTableView.dequeueReusableCell(
            withIdentifier: HostingTableViewCell<CreditCardItemRow>.cellIdentifier) as? HostingTableViewCell<CreditCardItemRow> else {
            return UITableViewCell(style: .default, reuseIdentifier: "ClientCell")
        }

        let creditCard = creditCard
        let creditCardRow = CreditCardItemRow(
            item: creditCard,
            isAccessibilityCategory: UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory)
//        creditCardRow.applyTheme(theme: themeManager.currentTheme)
        hostingCell.host(creditCardRow, parentController: self)
//        hostingCell.accessibilityAttributedLabel = viewModel.a11yLabel(for: indexPath)
        hostingCell.isAccessibilityElement = true
        return hostingCell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SaveCardTableHeaderView.cellIdentifier) as? SaveCardTableHeaderView else { return nil }
        headerView.applyTheme(theme: themeManager.currentTheme)
        return headerView
    }

    // easier to handle the bottom table spacing as a footer
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let emptyView = UIView()
        return emptyView
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return SingleCardViewControllerUX.distanceBetweenButtonAndTable
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: Themable
extension SingleCreditCardViewController: Themeable {
    func applyTheme() {
        let currentTheme = themeManager.currentTheme
        let labelsBackgroundColor = currentTheme.type == .dark ? currentTheme.colors.textInverted : currentTheme.colors.textPrimary
        contentView.backgroundColor = currentTheme.colors.layer1
        yesButton.backgroundColor = currentTheme.colors.actionPrimary
        yesButton.titleLabel?.textColor = labelsBackgroundColor

        notNowButton.backgroundColor = currentTheme.colors.actionSecondary
        notNowButton.titleLabel?.textColor = labelsBackgroundColor

        cardTableView.reloadData()
    }
}
