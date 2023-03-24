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
        profile.autofill.reopenIfClosed()
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
    
    func testEditSate_setup() {
        // Setup edit state
        viewModel.state = .edit
        XCTAssertEqual(viewModel.state.leftBarBtn, .cancel)
        XCTAssertEqual(viewModel.state.rightBarBtn, .save)
        XCTAssertEqual(viewModel.state.title, .CreditCard.EditCard.EditCreditCardTitle)
    }
    
    func testAddSate_setup() {
        // Setup add state
        viewModel.state = .add
        XCTAssertEqual(viewModel.state.leftBarBtn, .close)
        XCTAssertEqual(viewModel.state.rightBarBtn, .save)
        XCTAssertEqual(viewModel.state.title, .CreditCard.EditCard.AddCreditCardTitle)
    }
    
    func testViewSate_setup() {
        // Setup view state
        viewModel.state = .view
        XCTAssertEqual(viewModel.state.leftBarBtn, .close)
        XCTAssertEqual(viewModel.state.rightBarBtn, .edit)
        XCTAssertEqual(viewModel.state.title, .CreditCard.EditCard.ViewCreditCardTitle)
    }
}
