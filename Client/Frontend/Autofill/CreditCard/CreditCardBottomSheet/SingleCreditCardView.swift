// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import Storage
import Common

import Foundation
import UIKit

class SingleCreditCardViewController: UIViewController, BottomSheetChild, Themeable {
    // MARK: UX
    struct UX {
        static let containerPadding: CGFloat = 18.0
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
        static let headerPreferredHeight: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 64 + 24 : 84 + 24
        static let estimatedRowHeight: CGFloat = 86
    }

    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    private var viewModel: SingleCreditCardViewModel

    // MARK: Views
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
        cardTableView.isScrollEnabled = true
        cardTableView.showsVerticalScrollIndicator = false
        cardTableView.rowHeight = UITableView.automaticDimension
        cardTableView.estimatedRowHeight = UX.estimatedRowHeight
        cardTableView.estimatedSectionHeaderHeight = UX.headerPreferredHeight
        cardTableView.register(HostingTableViewCell<CreditCardItemRow>.self,
                               forCellReuseIdentifier: HostingTableViewCell<CreditCardItemRow>.cellIdentifier)
        cardTableView.register(SingleCreditCardFooterView.self, forHeaderFooterViewReuseIdentifier: SingleCreditCardFooterView.cellIdentifier)
        cardTableView.register(SingleCreditCardHeaderView.self, forHeaderFooterViewReuseIdentifier: SingleCreditCardHeaderView.cellIdentifier)
        return cardTableView
    }()

    let buttonsContainerStackView: UIStackView = .build { stack in
        stack.distribution = .fillEqually
        stack.alignment = .fill
        stack.axis = .vertical
        stack.spacing = UX.buttonsSpacing
    }

    private lazy var yesButton: ResizableButton = .build { button in
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredFont(
            withTextStyle: .callout,
            size: UX.yesButtonFontSize)
        button.addTarget(self, action: #selector(self.didTapYes), for: .touchUpInside)
        button.setTitle(.CreditCard.RememberCreditCard.MainButtonTitle, for: .normal)
        button.layer.cornerRadius = UX.yesButtonCornerRadius
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.accessibilityIdentifier = AccessibilityIdentifiers.RememberCreditCard.yesButton
    }

    private lazy var notNowButton: ResizableButton = .build { button in
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredFont(
            withTextStyle: .callout,
            size: UX.yesButtonFontSize)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.accessibilityIdentifier = AccessibilityIdentifiers.RememberCreditCard.notNowButton
        button.addTarget(self, action: #selector(SingleCreditCardViewController.didTapNotNow), for: .touchUpInside)
        button.setTitle(.CreditCard.RememberCreditCard.SecondaryButtonTitle, for: .normal)
        button.layer.cornerRadius = UX.yesButtonCornerRadius
    }

    private var tableViewHeightConstraint: NSLayoutConstraint!
    private var contentWidthConstraint: NSLayoutConstraint!

    // MARK: - Initializers
    init(viewModel: SingleCreditCardViewModel,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.viewModel = viewModel
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
        addSubviews()
        setupView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupView()
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    // MARK: View Setup
    func addSubviews() {
        let isIpad = UIDevice.current.userInterfaceIdiom == .pad
        buttonsContainerStackView.addArrangedSubview(yesButton)
        if isIpad {
            buttonsContainerStackView.addArrangedSubview(notNowButton)
        }
        contentView.addSubviews(cardTableView, buttonsContainerStackView)
        view.addSubview(contentView)
    }

    func setupView() {
        let headerHeight = UX.headerPreferredHeight
        let estimatedCellHeight = cardTableView.estimatedRowHeight
        let estimatedTableHeight = headerHeight + estimatedCellHeight + UX.distanceBetweenHeaderAndCells + UX.distanceBetweenButtonAndTable

        tableViewHeightConstraint = cardTableView.heightAnchor.constraint(equalToConstant: estimatedTableHeight * getHeightScaleBasedOnFontSize())
        tableViewHeightConstraint.priority = UILayoutPriority(999)

        let contentViewWidth = UX.contentViewWidth > view.frame.width ? view.frame.width - UX.containerPadding : UX.contentViewWidth
        contentWidthConstraint = contentView.widthAnchor.constraint(equalToConstant: contentViewWidth)
        contentWidthConstraint.priority = UILayoutPriority(999)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            cardTableView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UX.distanceBetweenHeaderAndTop),
            cardTableView.bottomAnchor.constraint(equalTo: buttonsContainerStackView.topAnchor, constant: 0),
            cardTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.tableMargin),
            cardTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.tableMargin),

            buttonsContainerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -UX.bottomSpacing),
            buttonsContainerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.tableMargin),
            buttonsContainerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.tableMargin),

            yesButton.heightAnchor.constraint(equalToConstant: UX.yesButtonHeight),
            notNowButton.heightAnchor.constraint(equalToConstant: UX.yesButtonHeight),
            contentWidthConstraint,
            tableViewHeightConstraint
        ])
    }

    // MARK: View Transitions
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        print("traitCollectionDidChange")
        setupView()
        applyTheme()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        print("viewWillTransition")
        let contentViewWidth = UX.contentViewWidth > size.width ? size.width - UX.containerPadding : UX.contentViewWidth
        contentWidthConstraint.constant = contentViewWidth
    }

    // MARK: Button Actions
    @objc
    private func didTapYes() {
        self.viewModel.didTapMainButton { error in
            // error is logged in the view model, but maybe we want to show an error message
            DispatchQueue.main.async { [weak self] in
                self?.dismissVC()
            }
        }
    }

    @objc
    private func didTapNotNow() {
        dismissVC()
    }

    @objc
    private func didTapManageCards() {
        dismissVC()
    }

    // MARK: BottomSheet Delegate
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

        let creditCard = viewModel.creditCard
        let creditCardRow = CreditCardItemRow(
            item: creditCard,
            isAccessibilityCategory: UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory)
        hostingCell.host(creditCardRow, parentController: self)
        hostingCell.isAccessibilityElement = true
        return hostingCell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SingleCreditCardHeaderView.cellIdentifier) as? SingleCreditCardHeaderView else { return nil }
        headerView.applyTheme(theme: themeManager.currentTheme)
        headerView.viewModel = viewModel
        return headerView
    }

    // easier to handle the bottom table spacing as a footer
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch viewModel.state {
        case .save:
            let emptyView = UIView()
            return emptyView
        case .update:
            guard let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SingleCreditCardFooterView.cellIdentifier) as? SingleCreditCardFooterView else { return nil }
            footerView.applyTheme(theme: themeManager.currentTheme)
            if !footerView.manageCardsButton.responds(to: #selector(SingleCreditCardViewController.didTapManageCards)) {
                footerView.manageCardsButton.addTarget(self, action: #selector(SingleCreditCardViewController.didTapManageCards), for: .touchUpInside)
            }

            return footerView
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UX.distanceBetweenButtonAndTable
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    // MARK: Themable
    func applyTheme() {
        let currentTheme = themeManager.currentTheme
        let labelsBackgroundColor = currentTheme.type == .dark ? currentTheme.colors.textInverted : currentTheme.colors.textPrimary
        view.backgroundColor = currentTheme.colors.layer1
        contentView.backgroundColor = currentTheme.colors.layer1
        yesButton.backgroundColor = currentTheme.colors.actionPrimary
        yesButton.titleLabel?.textColor = labelsBackgroundColor

        notNowButton.backgroundColor = currentTheme.colors.actionSecondary
        notNowButton.titleLabel?.textColor = labelsBackgroundColor

        cardTableView.reloadData()
    }
}

extension UITraitEnvironment {
    func getHeightScaleBasedOnFontSize() -> CGFloat {
        switch traitCollection.preferredContentSizeCategory {
        case .extraSmall, .small, .medium, .large:
            return 1
        case .extraLarge, .extraExtraLarge, .extraExtraExtraLarge:
            return 1.1
        case .accessibilityMedium:
            return 1.2
        case .accessibilityLarge:
            return 1.4
        case .accessibilityExtraLarge:
            return 1.6
        case .accessibilityExtraExtraLarge:
            return 1.8
        case .accessibilityExtraExtraExtraLarge:
            return 2
        default:
            return 1
        }
    }
}
