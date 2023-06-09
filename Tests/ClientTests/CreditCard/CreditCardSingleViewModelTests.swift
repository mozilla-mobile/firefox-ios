// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
@testable import Client
import Storage
import Shared
import XCTest

class CreditCardSingleViewModelTests: XCTestCase {
    private var profile: MockProfile!
    private var viewModel: SingleCreditCardViewModel!
    private var files: FileAccessor!
    private var autofill: RustAutofill!
    private var encryptionKey: String!
    private var samplePlainTextCard = UnencryptedCreditCardFields(ccName: "Allen Burges",
                                                                  ccNumber: "4539185806954013",
                                                                  ccNumberLast4: "4013",
                                                                  ccExpMonth: 08,
                                                                  ccExpYear: 2055,
                                                                  ccType: "VISA")
    private var sampleCreditCard = CreditCard(guid: "1",
                                              ccName: "Allen Burges",
                                              ccNumberEnc: "1234567891234567",
                                              ccNumberLast4: "4567",
                                              ccExpMonth: 1234567,
                                              ccExpYear: 2023,
                                              ccType: "VISA",
                                              timeCreated: 1234678,
                                              timeLastUsed: nil,
                                              timeLastModified: 123123,
                                              timesUsed: 123123)

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

        viewModel = SingleCreditCardViewModel(profile: profile,
                                              creditCard: nil,
                                              decryptedCreditCard: samplePlainTextCard,
                                              state: .save)
    }

    override func tearDown() {
        super.tearDown()
        viewModel = nil
        profile = nil
    }

    // MARK: - Test Cases
    func testSavingCard() {
        viewModel.creditCard = sampleCreditCard
        let expectation = expectation(description: "wait for credit card fields to be saved")
        viewModel.saveCreditCard { creditCard, error in
            guard error == nil, let creditCard = creditCard else {
                XCTFail()
                return
            }
            XCTAssertEqual(creditCard.ccName, self.viewModel.creditCard?.ccName)
            // Note: the number for credit card is encrypted so that part
            // will get added later and for now we will check the name only
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func testUpdatingCard() {
        viewModel.state = .save
        viewModel.decryptedCreditCard = samplePlainTextCard
        let expectation = expectation(description: "wait for credit card fields to be saved")
        viewModel.saveCreditCard { creditCard, error in
            guard error == nil, let creditCard = creditCard else {
                XCTFail()
                return
            }
            XCTAssertEqual(creditCard.ccName, self.viewModel.decryptedCreditCard?.ccName)
            // Note: the number for credit card is encrypted so that part
            // will get added later and for now we will check the name only
            self.samplePlainTextCard.ccExpYear = 2045
            self.samplePlainTextCard.ccName = "Test"
            self.viewModel.state = .update

            self.viewModel.creditCard = self.samplePlainTextCard.convertToTempCreditCard()
            self.viewModel.updateCreditCard { didUpdate, error in
                XCTAssertTrue(didUpdate)
                XCTAssertNil(error)
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1.0)
    }

    func testViewSetupForRememberCreditCard() {
        viewModel.state = .save
        XCTAssertTrue(viewModel.state.yesButtonTitle == .CreditCard.RememberCreditCard.MainButtonTitle)
        XCTAssertTrue(viewModel.state.notNowButtonTitle == .CreditCard.RememberCreditCard.SecondaryButtonTitle)
        XCTAssertTrue(viewModel.state.header == String(
            format: String.CreditCard.RememberCreditCard.Header,
            AppName.shortName.rawValue))
        XCTAssertTrue(viewModel.state.title == .CreditCard.RememberCreditCard.MainTitle)
    }

    func testViewSetupForUpdateCreditCard() {
        viewModel.state = .update
        XCTAssertTrue(viewModel.state.yesButtonTitle == .CreditCard.UpdateCreditCard.MainButtonTitle)
        XCTAssertTrue(viewModel.state.notNowButtonTitle == .CreditCard.UpdateCreditCard.SecondaryButtonTitle)
        XCTAssertTrue(viewModel.state.title == .CreditCard.UpdateCreditCard.MainTitle)
    }
}
