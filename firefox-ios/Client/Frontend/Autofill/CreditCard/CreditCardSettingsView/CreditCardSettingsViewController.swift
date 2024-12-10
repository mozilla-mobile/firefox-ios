// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared
import SwiftUI

import struct MozillaAppServices.CreditCard

class CreditCardSettingsViewController: SensitiveViewController, UIAdaptivePresentationControllerDelegate, Themeable {
    var viewModel: CreditCardSettingsViewModel
    var themeObserver: NSObjectProtocol?
    var themeManager: ThemeManager
    var notificationCenter: NotificationProtocol

    private let logger: Logger

    // MARK: Views
    var creditCardEmptyView: UIHostingController<CreditCardSettingsEmptyView>

    var creditCardEditView: CreditCardInputView?
    var creditCardAddEditView: UIHostingController<CreditCardInputView>?

    var creditCardTableViewController: CreditCardTableViewController

    private lazy var addCreditCardButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.plus),
                                     style: .plain,
                                     target: self,
                                     action: #selector(addCreditCard))
        button.accessibilityLabel = .CreditCard.Settings.AddCardAccessibilityLabel
        return button
    }()

    var currentWindowUUID: UUID? {
        return windowUUID
    }

    private var windowUUID: WindowUUID {
        return viewModel.windowUUID
    }

    // MARK: Initializers
    init(creditCardViewModel: CreditCardSettingsViewModel,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationCenter = NotificationCenter.default,
         logger: Logger = DefaultLogger.shared
    ) {
        self.viewModel = creditCardViewModel
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.logger = logger
        self.creditCardTableViewController =
        CreditCardTableViewController(viewModel: viewModel.tableViewModel,
                                      windowUUID: creditCardViewModel.windowUUID)

        let emptyView = CreditCardSettingsEmptyView(windowUUID: viewModel.windowUUID,
                                                    toggleModel: viewModel.toggleModel)
        self.creditCardEmptyView = UIHostingController(rootView: emptyView)
        self.creditCardEmptyView.view.backgroundColor = .clear

        super.init(nibName: nil, bundle: nil)
        self.creditCardTableViewController.didSelectCardAtIndex = { [weak self] creditCard in
            self?.viewCreditCard(card: creditCard)
            self?.sendCreditCardsManagementCardTappedTelemetry()
        }
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

    func viewSetup() {
        guard let emptyCreditCardView = creditCardEmptyView.view,
              let creditCardTableView = creditCardTableViewController.view else { return }
        creditCardTableView.translatesAutoresizingMaskIntoConstraints = false
        emptyCreditCardView.translatesAutoresizingMaskIntoConstraints = false

        addChild(creditCardEmptyView)
        addChild(creditCardTableViewController)
        view.addSubview(emptyCreditCardView)
        view.addSubview(creditCardTableView)
        self.title = .SettingsAutofillCreditCard

        NSLayoutConstraint.activate([
            emptyCreditCardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyCreditCardView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            emptyCreditCardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyCreditCardView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),

            creditCardTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            creditCardTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            creditCardTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            creditCardTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])

        // Hide all the views initially until we update the state
        hideAllViews()

        // Setup state and update view
        updateCreditCardList()
    }

    private func updateCreditCardList() {
        // Check if we have any credit cards to show in the list
        viewModel.getCreditCardList { creditCards in
            DispatchQueue.main.async { [weak self] in
                let newState = creditCards?.isEmpty ?? true ? CreditCardSettingsState.empty : CreditCardSettingsState.list
                self?.updateState(type: newState)
            }
        }
    }

    private func updateState(type: CreditCardSettingsState,
                             creditCard: CreditCard? = nil) {
        switch type {
        case .empty:
            creditCardTableViewController.view.isHidden = true
            creditCardEmptyView.view.isHidden = false
            navigationItem.rightBarButtonItem = addCreditCardButton
        case .add:
            updateStateForEditView(editState: .add)
        case .view:
            updateStateForEditView(editState: .view, creditCard: creditCard)
        case .list:
            creditCardTableViewController.reloadData()
            creditCardEmptyView.view.isHidden = true
            creditCardTableViewController.view.isHidden = false
            navigationItem.rightBarButtonItem = addCreditCardButton
        }
    }

    private func hideAllViews() {
        creditCardEmptyView.view.isHidden = true
        creditCardTableViewController.view.isHidden = true
    }

    private func currentTheme() -> Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }

    func applyTheme() {
        let theme = currentTheme()
        view.backgroundColor = theme.colors.layer1
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    // MARK: - Private helpers

    private func updateStateForEditView(editState: CreditCardEditState,
                                        creditCard: CreditCard? = nil) {
        // Update credit card edit view state before showing
        if editState == .view {
            viewModel.cardInputViewModel.creditCard = creditCard
        }
        viewModel.cardInputViewModel.updateState(state: editState)
        creditCardEditView = CreditCardInputView(viewModel: viewModel.cardInputViewModel, windowUUID: windowUUID)
        viewModel.cardInputViewModel.dismiss = { [weak self] status, successVal in
            DispatchQueue.main.async {
                self?.showToast(status: status)

                if successVal {
                    self?.updateCreditCardList()
                    self?.sendTelemetry(forStatus: status)
                }

                self?.creditCardAddEditView?.dismiss(animated: true)
                self?.viewModel.cardInputViewModel.clearValues()
            }
        }

        guard let creditCardEditView = creditCardEditView else { return }
        creditCardAddEditView = UIHostingController(rootView: creditCardEditView)
        guard let creditCardAddEditView = creditCardAddEditView else { return}
        creditCardAddEditView.view.backgroundColor = .clear
        creditCardAddEditView.modalPresentationStyle = .formSheet
        creditCardAddEditView.presentationController?.delegate = self
        present(creditCardAddEditView, animated: true, completion: nil)
    }

    private func showToast(status: CreditCardModifiedStatus) {
        guard status != .none else { return }
        SimpleToast().showAlertWithText(status.message,
                                        bottomContainer: view,
                                        theme: self.themeManager.getCurrentTheme(for: self.windowUUID))
    }

    @objc
    private func addCreditCard() {
        updateState(type: .add)
        sendCreditCardsManagementAddTappedTelemetry()
    }

    private func viewCreditCard(card: CreditCard) {
        updateState(type: .view, creditCard: card)
    }

    // MARK: Telemetry
    fileprivate func sendTelemetry(forStatus status: CreditCardModifiedStatus) {
        switch status {
        case .savedCard:
            self.sendCreditCardsSavedTelemetry()
        case .updatedCard:
            self.sendCreditCardsModifiedTelemetry()
        case .removedCard:
            self.sendCreditCardsDeletedTelemetry()
        case .none:
            break
        }
    }

    private func sendCreditCardsManagementAddTappedTelemetry() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .creditCardManagementAddTapped)
    }

    private func sendCreditCardsManagementCardTappedTelemetry() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .creditCardManagementCardTapped)
    }

    private func sendCreditCardsSavedTelemetry() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .add,
                                     object: .creditCardSaved)
    }

    private func sendCreditCardsDeletedTelemetry() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .delete,
                                     object: .creditCardDeleted)
    }

    private func sendCreditCardsModifiedTelemetry() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .change,
                                     object: .creditCardModified)
    }

    // MARK: - UIAdaptivePresentationControllerDelegate
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        if presentationController.presentedViewController is UIHostingController<CreditCardInputView> {
            viewModel.cardInputViewModel.clearValues()
        }
    }
}
