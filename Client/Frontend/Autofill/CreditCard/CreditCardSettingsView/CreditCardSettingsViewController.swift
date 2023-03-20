// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared
import Storage
import SwiftUI

public final class TransparentHostingController<Content: View>: UIHostingController<Content> {
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.isOpaque = false
        view.backgroundColor = .purple
    }
}

class CreditCardSettingsViewController: UIViewController, Themeable {
    var viewModel: CreditCardSettingsViewModel
    var startingConfig: CreditCardSettingsStartingConfig?
    var themeObserver: NSObjectProtocol?
    var themeManager: ThemeManager
    var notificationCenter: NotificationProtocol

    private let appAuthenticator: AppAuthenticationProtocol
    private let logger: Logger

    // MARK: Views
    var creditCardEmptyView: UIHostingController<CreditCardSettingsEmptyView>

    var creditCardEditView: CreditCardEditView?
    var creditCardAddEditView: TransparentHostingController<CreditCardEditView>?

    var creditCardTableViewController: CreditCardTableViewController

    private lazy var addCreditCardButton: UIBarButtonItem = {
        return UIBarButtonItem(image: UIImage.templateImageNamed(ImageIdentifiers.navAdd),
                               style: .plain,
                               target: self,
                               action: #selector(addCreditCard))
    }()

    // MARK: Initializers
    init(creditCardViewModel: CreditCardSettingsViewModel,
         startingConfig: CreditCardSettingsStartingConfig?,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationCenter = NotificationCenter.default,
         appAuthenticator: AppAuthenticationProtocol = AppAuthenticator(),
         logger: Logger = DefaultLogger.shared
    ) {
        self.startingConfig = startingConfig
        self.viewModel = creditCardViewModel
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.appAuthenticator = appAuthenticator
        self.logger = logger
        self.creditCardTableViewController = CreditCardTableViewController(viewModel: viewModel.creditCardTableViewModel)

        let theme = themeManager.currentTheme
        let colors = CreditCardSettingsEmptyView.Colors(titleTextColor: theme.colors.textPrimary.color,
                                                        subTextColor: theme.colors.textPrimary.color,
                                                        toggleTextColor: theme.colors.textPrimary.color)
        let emptyView = CreditCardSettingsEmptyView(colors: colors, toggleModel: viewModel.toggleModel)
        self.creditCardEmptyView = UIHostingController(rootView: emptyView)
        self.creditCardEmptyView.view.backgroundColor = .clear

//        self.creditCardAddEditView = SensitiveHostingController(rootView: creditCardEditView)

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

    func viewSetup() {
        guard let emptyCreditCardView = creditCardEmptyView.view,
              let creditCardTableView = creditCardTableViewController.view else { return }
        creditCardTableView.translatesAutoresizingMaskIntoConstraints = false
        emptyCreditCardView.translatesAutoresizingMaskIntoConstraints = false

        addChild(creditCardEmptyView)
        addChild(creditCardTableViewController)
        view.addSubview(emptyCreditCardView)
        view.addSubview(creditCardTableView)

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
        setupState()
    }

    func setupState() {
        // check if there are any starting config
        guard startingConfig == nil else {
            updateState(type: .empty)
            return
        }

        // Check if we have any credit cards to show in the list
        viewModel.listCreditCard { creditCards in
            guard let creditCards = creditCards, !creditCards.isEmpty else {
                DispatchQueue.main.async { [weak self] in
                    self?.updateState(type: .empty)
                }
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.viewModel.updateCreditCardsList(creditCards: creditCards)
                self?.updateState(type: .list)
            }
        }

        updateState(type: .empty)
    }

    func updateState(type: CreditCardSettingsState) {
        switch type {
        case .empty:
            creditCardTableViewController.view.isHidden = true
            creditCardEmptyView.view.isHidden = false
            navigationItem.rightBarButtonItem = addCreditCardButton
        case .add:
            updateStateForEditView(editState: .add)
        case .edit:
            updateStateForEditView(editState: .edit)
        case .view:
            updateStateForEditView(editState: .view)
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

    func applyTheme() {
        let theme = themeManager.currentTheme
        view.backgroundColor = theme.colors.layer1
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    // MARK: - Private helpers

    func dismissCreditCardEditView() {
        self.creditCardEmptyView.dismiss(animated: true)
    }

    private func updateStateForEditView(editState: CreditCardEditState) {
        // Update credit card edit view state before showing
        viewModel.addEditViewModel.state = editState
        creditCardEditView = CreditCardEditView(
            viewModel: viewModel.addEditViewModel,
            dismiss: { [weak self] in
                self?.creditCardAddEditView?.dismiss(animated: true)
        })

        guard let creditCardEditView = creditCardEditView else { return }
        creditCardAddEditView = TransparentHostingController(rootView: creditCardEditView)
        guard let creditCardAddEditView = creditCardAddEditView else { return }
        creditCardAddEditView.view.backgroundColor = .clear
//        creditCardAddEditView.modalPresentationStyle = .fullScreen
        present(creditCardAddEditView, animated: true, completion: nil)

//        creditCardEditView.dismiss = {
//            self.dismissCreditCardEditView()
//        }
//        creditCardAddEditView.view.isOpaque = false
//        creditCardAddEditView.view.backgroundColor = .clear
//        self.viewModel.addEditViewModel.state = editState
//        self.creditCardAddEditView?.modalPresentationStyle = .fullScreen
//        self.creditCardEmptyView.navigationController?.setNavigationBarHidden(true, animated: false)
//        let view = TestView(dismiss: { self.navigationController.presentedViewController?.dismiss(animated: true) })

        
//        self.present(self.creditCardAddEditView, animated: true, completion: nil)
//        guard appAuthenticator.canAuthenticateDeviceOwner() else { return }
//
//        appAuthenticator.authenticateWithDeviceOwnerAuthentication { result in
//            switch result {
//            case .success:
//                // Update credit card edit view state before showing
//                self.viewModel.addEditViewModel.state = editState
//                self.creditCardAddEditView.modalPresentationStyle = .fullScreen
//                self.present(self.creditCardAddEditView, animated: true, completion: nil)
//            case .failure:
//                self.logger.log("Failed to authenticate", level: .debug, category: .creditcard)
//            }
//        }
    }

    @objc private func addCreditCard() {
        updateState(type: .add)
    }
}
