// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Shared
import SwiftUI

class CreditCardSettingsViewController: UIViewController, ThemeApplicable {
    var themeObserver: NSObjectProtocol?
    var theme: Theme
    var viewModel: CreditCardSettingsViewModel
    var state: CreditCardSettingsState = .empty
    var startingConfig: CreditCardSettingsStartingConfig?

    //MARK: - Views
    var creditCardEmptyView = UIHostingController(rootView: CreditCardSettingsEmptyView())

    //MARK: - UX
    struct UX {

    }

    //MARK: - Initializers

    init(theme: Theme,
         creditCardViewModel: CreditCardSettingsViewModel,
         startingConfig: CreditCardSettingsStartingConfig?) {
        self.theme = theme
        self.startingConfig = startingConfig
        self.viewModel = creditCardViewModel
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

    func viewSetup() {
        guard let emptyCreditCardView = creditCardEmptyView.view else { return }
        emptyCreditCardView.translatesAutoresizingMaskIntoConstraints = false
        addChild(creditCardEmptyView)
        view.addSubview(emptyCreditCardView)

        NSLayoutConstraint.activate([
            emptyCreditCardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyCreditCardView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            emptyCreditCardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyCreditCardView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])

        // Hide all the views initially until we update the state
        hideAllViews()

        // Setup state and update view
        setupSate()
    }

    func setupSate() {
        // check if there are any starting config
        guard let startingConfig = startingConfig else {
            //Check if we have any credit cards to show in the list
            viewModel.listCreditCard { creditCards in
                guard let creditCards = creditCards, !creditCards.isEmpty else {
                    self.updateState(type: .empty)
                    return
                }
                self.updateState(type: .list)
            }
            
            updateState(type: .empty)
            return
        }

        updateState(type: .empty)
    }

    func updateState(type: CreditCardSettingsState) {
        switch type {
        case .empty:
            creditCardEmptyView.view.isHidden = false
        case .add:
            print("setup add view")
        case .edit:
            print("setup edit view")
        case .list:
            print("setup list view")
        }
    }

    func setupAdd() {
        
    }

    func setupEdit() {
        // Show creditCardModifierViewController with edit
    }

    func setupList() {
        
    }

    func hideAllViews() {
        creditCardEmptyView.view.isHidden = true
    }

    func applyTheme(theme: Theme) {
        view.backgroundColor = theme.colors.layer1
    }
}
