// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import Storage
import MozillaAppServices
@testable import Client

class CreditCardBottomSheetViewControllerTests: XCTestCase {
    let windowUUID: WindowUUID = .XCTestDefaultUUID
    private var autofill: MockCreditCardProvider!
    private var samplePlainTextCard = UnencryptedCreditCardFields(ccName: "Allen Burges",
                                                                  ccNumber: "4111111111111111",
                                                                  ccNumberLast4: "1111",
                                                                  ccExpMonth: 3,
                                                                  ccExpYear: 2043,
                                                                  ccType: "VISA")

    private var samplePlainTextUpdateCard = UnencryptedCreditCardFields(ccName: "Allen Burgers",
                                                                        ccNumber: "4111111111111111",
                                                                        ccNumberLast4: "1111",
                                                                        ccExpMonth: 09,
                                                                        ccExpYear: 2056,
                                                                        ccType: "VISA")
    private var sampleCreditCard = CreditCard(guid: "1",
                                              ccName: "Allen Burges",
                                              ccNumberEnc: "4111111111111111",
                                              ccNumberLast4: "1111",
                                              ccExpMonth: 3,
                                              ccExpYear: 2043,
                                              ccType: "VISA",
                                              timeCreated: 1234678,
                                              timeLastUsed: nil,
                                              timeLastModified: 123123,
                                              timesUsed: 123123)
    override func setUp() async throws {
        try await super.setUp()
        autofill = MockCreditCardProvider()
        await DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        autofill = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    @MainActor
    func testCreditCardBottomSheetViewController_simpleCreation_hasNoLeaks() {
        let creditCardBottomSheetViewModel = CreditCardBottomSheetViewModel(
            creditCardProvider: autofill,
            creditCard: sampleCreditCard,
            decryptedCreditCard: samplePlainTextCard,
            state: CreditCardBottomSheetState.save
        )

        let creditCardBottomSheetViewController = CreditCardBottomSheetViewController(
            viewModel: creditCardBottomSheetViewModel,
            windowUUID: windowUUID
        )
        trackForMemoryLeaks(creditCardBottomSheetViewController)
    }

    @MainActor
    func testEstimatedContentHeight_withSelectSavedCard_usesLoadedCardCount() {
        let oneCardViewModel = CreditCardBottomSheetViewModel(
            creditCardProvider: autofill,
            creditCard: nil,
            decryptedCreditCard: nil,
            preloadedCreditCards: [sampleCreditCard],
            state: .selectSavedCard
        )
        let oneCardViewController = CreditCardBottomSheetViewController(
            viewModel: oneCardViewModel,
            windowUUID: windowUUID
        )

        let secondCreditCard = CreditCard(guid: "2",
                                          ccName: "Jane Smith",
                                          ccNumberEnc: "5555555555554444",
                                          ccNumberLast4: "4444",
                                          ccExpMonth: 12,
                                          ccExpYear: 2040,
                                          ccType: "MasterCard",
                                          timeCreated: 1234678,
                                          timeLastUsed: nil,
                                          timeLastModified: 123123,
                                          timesUsed: 123123)
        let threeCardViewModel = CreditCardBottomSheetViewModel(
            creditCardProvider: autofill,
            creditCard: nil,
            decryptedCreditCard: nil,
            preloadedCreditCards: [sampleCreditCard, secondCreditCard, sampleCreditCard],
            state: .selectSavedCard
        )
        let threeCardViewController = CreditCardBottomSheetViewController(
            viewModel: threeCardViewModel,
            windowUUID: windowUUID
        )

        let heightDifference = threeCardViewController.estimatedContentHeight() -
            oneCardViewController.estimatedContentHeight()

        XCTAssertEqual(heightDifference, CreditCardBottomSheetViewController.UX.estimatedRowHeight * 2)
    }
}
