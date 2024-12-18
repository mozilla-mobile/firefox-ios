// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import Foundation
import Shared
import Storage
import UIKit

class CreditCardBottomSheetViewController: UIViewController,
                                           UITableViewDelegate,
                                           UITableViewDataSource,
                                           BottomSheetChild,
                                           Themeable {
    // MARK: UX
    struct UX {
        static let containerPadding: CGFloat = 18.0
        static let tableMargin: CGFloat = 0
        static let distanceBetweenHeaderAndTop: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 8 : 18
        static let distanceBetweenButtonAndTable: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 18 : 34
        static let distanceBetweenHeaderAndCells: CGFloat = 24
        static let yesButtonCornerRadius: CGFloat = 13
        static let yesButtonFontSize: CGFloat = 16.0
        static let yesButtonHeight: CGFloat = 45.0
        static let bottomSpacing: CGFloat = 32.0
        static let buttonsSpacing: CGFloat = 8.0
        static let contentViewWidth: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 545 : 339
        // 24 is the spacing needed between the header and the table cell, left in this form so it's not overlooked
        static let headerPreferredHeight: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 64 + 24 : 84 + 24
        static let estimatedRowHeight: CGFloat = 86
        static let closeButtonMarginAndWidth: CGFloat = 46.0
    }

    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    private var viewModel: CreditCardBottomSheetViewModel
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

    var didTapYesClosure: ((Error?) -> Void)?
    var didTapManageCardsClosure: (() -> Void)?
    var didSelectCreditCardToFill: ((UnencryptedCreditCardFields) -> Void)?

    private var numberOfCards: Int {
        switch viewModel.state {
        case .save, .update:
            return 1
        case .selectSavedCard:
            return viewModel.creditCards?.count ?? 1
        }
    }

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
        cardTableView.isScrollEnabled = false
        cardTableView.showsVerticalScrollIndicator = false
        cardTableView.rowHeight = UITableView.automaticDimension
        cardTableView.sectionHeaderTopPadding = 0
        cardTableView.estimatedRowHeight = UX.estimatedRowHeight
        cardTableView.estimatedSectionFooterHeight = UX.distanceBetweenButtonAndTable
        cardTableView.estimatedSectionHeaderHeight = UX.headerPreferredHeight
        cardTableView.register(HostingTableViewCell<CreditCardItemRow>.self,
                               forCellReuseIdentifier: HostingTableViewCell<CreditCardItemRow>.cellIdentifier)
        cardTableView.register(CreditCardBottomSheetFooterView.self,
                               forHeaderFooterViewReuseIdentifier: CreditCardBottomSheetFooterView.cellIdentifier)
        cardTableView.register(CreditCardBottomSheetHeaderView.self,
                               forHeaderFooterViewReuseIdentifier: CreditCardBottomSheetHeaderView.cellIdentifier)
        return cardTableView
    }()

    let buttonsContainerStackView: UIStackView = .build { stack in
        stack.distribution = .fillEqually
        stack.alignment = .fill
        stack.axis = .vertical
        stack.spacing = UX.buttonsSpacing
    }

    private lazy var yesButton: PrimaryRoundedButton = .build { button in
        button.addTarget(self, action: #selector(self.didTapYes), for: .touchUpInside)
    }

    private var contentViewHeightConstraint: NSLayoutConstraint!
    private var contentWidthConstraint: NSLayoutConstraint!

    // MARK: - Initializers
    init(viewModel: CreditCardBottomSheetViewModel,
         windowUUID: WindowUUID,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.viewModel = viewModel
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        self.windowUUID = windowUUID
        super.init(nibName: nil, bundle: nil)

        self.viewModel.didUpdateCreditCard = { [weak self] in
            self?.cardTableView.reloadData()
            self?.cardTableView.isScrollEnabled = self?.cardTableView.contentSize.height ?? 0 > self?.view.frame.height ?? 0
        }

        // Only allow selection when we are in selectSavedCard state
        // No selection is allowed for save / update states
        self.cardTableView.allowsSelection = viewModel.state == .selectSavedCard ? true : false
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
        updateConstraints()
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    // MARK: View Setup
    func addSubviews() {
        if viewModel.state != .selectSavedCard {
            buttonsContainerStackView.addArrangedSubview(yesButton)
            let buttonViewModel = PrimaryRoundedButtonViewModel(
                title: .CreditCard.RememberCreditCard.MainButtonTitle,
                a11yIdentifier: AccessibilityIdentifiers.RememberCreditCard.yesButton
            )
            yesButton.configure(viewModel: buttonViewModel)
            yesButton.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }

        contentView.addSubviews(cardTableView, buttonsContainerStackView)
        view.addSubview(contentView)
    }

    func setupView() {
        let headerHeight = cardTableView.estimatedSectionHeaderHeight
        let estimatedFooterHeight = cardTableView.estimatedSectionFooterHeight
        let estimatedCellHeight = cardTableView.estimatedRowHeight

        let UXSpacing = UX.yesButtonHeight + UX.bottomSpacing + UX.buttonsSpacing
        var estimatedContentHeight = headerHeight + estimatedCellHeight + estimatedFooterHeight + UXSpacing

        if UIDevice.current.userInterfaceIdiom == .pad {
            estimatedContentHeight += UX.yesButtonHeight
        }

        contentViewHeightConstraint = contentView.heightAnchor.constraint(
            greaterThanOrEqualToConstant: estimatedContentHeight
        )
        contentViewHeightConstraint.priority = UILayoutPriority(999)

        let contentWidthCheck = UX.contentViewWidth > view.frame.width
        let contentViewWidth = contentWidthCheck ? view.frame.width - UX.containerPadding : UX.contentViewWidth
        contentWidthConstraint = contentView.widthAnchor.constraint(equalToConstant: contentViewWidth)
        contentWidthConstraint.priority = UILayoutPriority(999)

        NSLayoutConstraint.activate(
            [
                contentView.topAnchor.constraint(equalTo: view.topAnchor),
                contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),

                cardTableView.topAnchor.constraint(
                    equalTo: contentView.topAnchor,
                    constant: UX.distanceBetweenHeaderAndTop
                ),
                cardTableView.bottomAnchor.constraint(equalTo: buttonsContainerStackView.topAnchor, constant: 0),
                cardTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.tableMargin),
                cardTableView.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor,
                    constant: -UX.tableMargin
                ),

                buttonsContainerStackView.bottomAnchor.constraint(
                    equalTo: contentView.bottomAnchor,
                    constant: -UX.bottomSpacing
                ),
                buttonsContainerStackView.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor,
                    constant: UX.tableMargin
                ),
                buttonsContainerStackView.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor,
                    constant: -UX.tableMargin
                ),

                yesButton.heightAnchor.constraint(greaterThanOrEqualToConstant: UX.yesButtonHeight),
                contentWidthConstraint,
                contentViewHeightConstraint
            ]
        )
    }

    func updateConstraints() {
        let buttonsHeight = buttonsContainerStackView.frame.height
        let estimatedContentHeight = cardTableView.contentSize.height +
        buttonsHeight + UX.bottomSpacing + UX.distanceBetweenHeaderAndTop
        let aspectRatio = estimatedContentHeight / contentView.bounds.size.height
        contentViewHeightConstraint.constant = contentViewHeightConstraint.constant * aspectRatio

        let contentWidthCheck = UX.contentViewWidth > view.frame.size.width
        let contentViewWidth = contentWidthCheck ? view.frame.size.width - UX.containerPadding : UX.contentViewWidth
        contentWidthConstraint.constant = contentViewWidth
    }

    // MARK: View Transitions
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateConstraints()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let contentWidthCheck = UX.contentViewWidth > size.width
        let contentViewWidth = contentWidthCheck ? size.width - UX.containerPadding : UX.contentViewWidth
        contentWidthConstraint.constant = contentViewWidth
        if let header = cardTableView.headerView(forSection: 0) as? CreditCardBottomSheetHeaderView {
            header.titleLabelTrailingConstraint?.constant = contentWidthCheck ? -UX.closeButtonMarginAndWidth : 0
        }
    }

    // MARK: Button Actions
    @objc
    private func didTapYes() {
        self.viewModel.didTapMainButton { [weak self] error in
            DispatchQueue.main.async { [weak self] in
                self?.dismissVC()
                self?.didTapYesClosure?(error)
            }
        }
    }

    @objc
    private func didTapManageCards() {
        didTapManageCardsClosure?()
    }

    // MARK: BottomSheet Delegate
    func willDismiss() {
        if viewModel.state == .selectSavedCard {
            sendCreditCardAutofillPromptDismissedTelemetry()
        }
    }

    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfCards
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return creditCardCell(indexPath: indexPath)
    }

    private func creditCardCell(indexPath: IndexPath) -> UITableViewCell {
        guard let hostingCell = cardTableView.dequeueReusableCell(
            withIdentifier: HostingTableViewCell<CreditCardItemRow>.cellIdentifier
        ) as? HostingTableViewCell<CreditCardItemRow>,
              let creditCard = viewModel.getConvertedCreditCardValues(
                bottomSheetState: viewModel.state,
                ccNumberDecrypted: viewModel.decryptCreditCardNumber(card: viewModel.creditCard),
                row: indexPath.row
              )
        else { return UITableViewCell() }

        let creditCardRow = CreditCardItemRow(
            item: creditCard,
            isAccessibilityCategory: UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory,
            shouldShowSeparator: false,
            addPadding: numberOfCards > 1,
            didSelectAction: { [weak self] in
                self?.handleCreditCardSelection(row: indexPath.row)
            },
            windowUUID: windowUUID)
        hostingCell.host(creditCardRow, parentController: self)
        hostingCell.backgroundColor = .clear
        hostingCell.contentView.backgroundColor = .clear
        hostingCell.selectionStyle = .none
        hostingCell.isAccessibilityElement = true
        hostingCell.accessibilityAttributedLabel = viewModel.a11yLabel(for: creditCard)
        hostingCell.accessibilityIdentifier = "creditCardCell_\(indexPath.row)"

        return hostingCell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: CreditCardBottomSheetHeaderView.cellIdentifier
        ) as? CreditCardBottomSheetHeaderView else {
            return nil
        }
        headerView.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        headerView.viewModel = viewModel
        return headerView
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch viewModel.state {
        case .save:
            let emptyView = UIView()
            return emptyView
        case .update, .selectSavedCard:
            guard let footerView = tableView.dequeueReusableHeaderFooterView(
                withIdentifier: CreditCardBottomSheetFooterView.cellIdentifier
            ) as? CreditCardBottomSheetFooterView else {
                return nil
            }
            footerView.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
            if !footerView.manageCardsButton.responds(
                to: #selector(CreditCardBottomSheetViewController.didTapManageCards)
            ) {
                footerView.manageCardsButton.addTarget(
                    self,
                    action: #selector(CreditCardBottomSheetViewController.didTapManageCards),
                    for: .touchUpInside
                )
            }

            return footerView
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func handleCreditCardSelection(row: Int) {
        guard let plainTextCreditCard = viewModel.getPlainCreditCardValues(
            bottomSheetState: .selectSavedCard,
            row: row
        ) else {
            return
        }
        didSelectCreditCardToFill?(plainTextCreditCard)
        dismissVC()
    }

    // MARK: Themable
    func applyTheme() {
        let currentTheme = themeManager.getCurrentTheme(for: windowUUID).colors
        view.backgroundColor = currentTheme.layer1
        cardTableView.reloadData()
    }

    // MARK: Telemetry
    fileprivate func sendCreditCardAutofillPromptDismissedTelemetry() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .close,
                                     object: .creditCardAutofillPromptDismissed)
    }
}
