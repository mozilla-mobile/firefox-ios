// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import Common
import Storage
@testable import Client

class CreditCardEditViewModelTests: XCTestCase {
    private var profile: MockProfile!
    private var viewModel: CreditCardEditViewModel!
    private var files: FileAccessor!
    private var autofill: RustAutofill!
    private var encryptionKey: String!

    override func setUp() {
        super.setUp()
        files = MockFiles()

        if let rootDirectory = try? files.getAndEnsureDirectory() {
            let databasePath = URL(fileURLWithPath: rootDirectory, isDirectory: true)
                .appendingPathComponent("testAutofill.db").path
            try? files.remove("testAutofill.db")

            if let key = try? createAutofillKey() {
                encryptionKey = key
            } else {
                XCTFail("Encryption key wasn't created")
            }

            autofill = RustAutofill(databasePath: databasePath)
            _ = autofill.reopenIfClosed()
        } else {
            XCTFail("Could not retrieve root directory")
        }

        profile = MockProfile()
        _ = profile.autofill.reopenIfClosed()
        viewModel = CreditCardEditViewModel(profile: profile)
    }

    override func tearDown() {
        super.tearDown()
        viewModel = nil
        profile = nil
    }

    func testEditViewModel_SavingCard() {
        viewModel.nameOnCard = "Ashton Mealy"
        viewModel.cardNumber = "4268811063712243"
        viewModel.expirationDate = "1837539531"
        let expectation = expectation(description: "wait for credit card fields to be saved")
        viewModel.saveCreditCard { creditCard, error in
            guard error == nil, let creditCard = creditCard else {
                XCTAssertTrue(false)
                return
            }
            XCTAssertEqual(creditCard.ccName, self.viewModel.nameOnCard)
            // Note: the number for credit card is encrypted so that part
            // will get added later and for now we will check the name only
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func testEditState_setup() {
        // Setup edit state
        viewModel.state = .edit
        XCTAssertEqual(viewModel.state.leftBarBtn, .cancel)
        XCTAssertEqual(viewModel.state.rightBarBtn, .save)
        XCTAssertEqual(viewModel.state.title, .CreditCard.EditCard.EditCreditCardTitle)
        XCTAssertEqual(viewModel.state.rightBarBtn.title, .CreditCard.EditCard.SaveNavBarButtonLabel)
    }

    func testAddState_setup() {
        // Setup add state
        viewModel.state = .add
        XCTAssertEqual(viewModel.state.leftBarBtn, .close)
        XCTAssertEqual(viewModel.state.rightBarBtn, .save)
        XCTAssertEqual(viewModel.state.title, .CreditCard.EditCard.AddCreditCardTitle)
        XCTAssertEqual(viewModel.state.rightBarBtn.title, .CreditCard.EditCard.SaveNavBarButtonLabel)
    }

    func testViewState_setup() {
        // Setup view state
        viewModel.state = .view
        XCTAssertEqual(viewModel.state.leftBarBtn, .close)
        XCTAssertEqual(viewModel.state.rightBarBtn, .edit)
        XCTAssertEqual(viewModel.state.title, .CreditCard.EditCard.ViewCreditCardTitle)
        XCTAssertEqual(viewModel.state.rightBarBtn.title, .CreditCard.EditCard.EditNavBarButtonLabel)
    }

    func testRightBarButtonEnabledEdit() {
        viewModel.state = .edit
        viewModel.nameOnCard = "Kenny Champion"
        viewModel.expirationDate = "123"
        viewModel.cardNumber = "4871007782167426"
        XCTAssertTrue(viewModel.isRightBarButtonEnabled)
    }

    func testRightBarButtonEnabledAdd() {
        viewModel.state = .add
        viewModel.nameOnCard = "Jakyla Labarge"
        viewModel.expirationDate = "123"
        viewModel.cardNumber = "4717219604213696"
        XCTAssertTrue(viewModel.isRightBarButtonEnabled)
    }

    func testRightBarButtonDisabled_AddState() {
        rightBarButtonDisabled_Empty_CardName(state: .add)
        rightBarButtonDisabled_Empty_CardName_Expiration(state: .add)
        rightBarButtonDisabled_Empty_CardName_Expiration_Number(state: .add)
    }

    func testRightBarButtonDisabled_EditState() {
        rightBarButtonDisabled_Empty_CardName(state: .edit)
        rightBarButtonDisabled_Empty_CardName_Expiration(state: .edit)
        rightBarButtonDisabled_Empty_CardName_Expiration_Number(state: .edit)
    }

    // MARK: Helpers

    func rightBarButtonDisabled_Empty_CardName(
        state: CreditCardEditState) {
        guard state == .edit || state == .add else { return }
        viewModel.state = state
        viewModel.nameOnCard = ""
        viewModel.expirationDate = "123"
        viewModel.cardNumber = "4717219604213696"
        XCTAssertTrue(!viewModel.isRightBarButtonEnabled)
    }

    func rightBarButtonDisabled_Empty_CardName_Expiration(
        state: CreditCardEditState) {
        guard state == .edit || state == .add else { return }
        viewModel.state = state
        viewModel.nameOnCard = ""
        viewModel.expirationDate = ""
        viewModel.cardNumber = "4717219604213696"
        XCTAssertTrue(!viewModel.isRightBarButtonEnabled)
    }

    func rightBarButtonDisabled_Empty_CardName_Expiration_Number(
        state: CreditCardEditState) {
        guard state == .edit || state == .add else { return }
        viewModel.state = state
        viewModel.nameOnCard = ""
        viewModel.expirationDate = ""
        viewModel.cardNumber = ""
        XCTAssertTrue(!viewModel.isRightBarButtonEnabled)
    }
}
