// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Combine
import MozillaAppServices
import Storage
import XCTest
import Common

@testable import Client

final class AddressListViewModelTests: XCTestCase {
    var viewModel: AddressListViewModel!
    var mockProfile: MockProfile!
    var mockLogger: MockLogger!
    var mockAutofill: MockAutofill!
    var mockThemeManager: MockThemeManager!

    var cancellables: [AnyCancellable] = []
    let dummyAddresses = [
        Address(
            guid: "12345-ABCDE",
            name: "John Doe",
            organization: "Acme Corp",
            streetAddress: "123 Main St",
            addressLevel3: "Suite 100",
            addressLevel2: "San Francisco",
            addressLevel1: "CA",
            postalCode: "94101",
            country: "USA",
            tel: "+1-555-1234",
            email: "john.doe@example.com",
            timeCreated: 1622547800,
            timeLastUsed: 1625149800,
            timeLastModified: 1625149800,
            timesUsed: 5
        ),
        Address(
            guid: "67890-FGHIJ",
            name: "Jane Smith",
            organization: "Widget Inc",
            streetAddress: "456 Elm St",
            addressLevel3: "",
            addressLevel2: "Los Angeles",
            addressLevel1: "CA",
            postalCode: "90001",
            country: "USA",
            tel: "+1-555-5678",
            email: "jane.smith@example.com",
            timeCreated: 1612134600,
            timeLastUsed: 1627750200,
            timeLastModified: 1627750200,
            timesUsed: 10
        ),
        Address(
            guid: "11223-KLMNO",
            name: "Alice Johnson",
            organization: "Tech Solutions",
            streetAddress: "789 Pine St",
            addressLevel3: "Apt 2B",
            addressLevel2: "New York",
            addressLevel1: "NY",
            postalCode: "10001",
            country: "USA",
            tel: "+1-555-9012",
            email: "alice.johnson@example.com",
            timeCreated: 1609459200,
            timeLastUsed: 1622463000,
            timeLastModified: 1622463000,
            timesUsed: 3
        )
    ]

    override func setUp() {
        super.setUp()
        mockProfile = MockProfile()
        mockLogger = MockLogger()
        mockAutofill = MockAutofill()
        mockThemeManager = MockThemeManager()
        viewModel = AddressListViewModel(
            logger: mockLogger,
            windowUUID: WindowUUID(),
            addressProvider: mockAutofill,
            themeManager: mockThemeManager,
            profile: mockProfile
        )
    }

    override func tearDown() {
        viewModel = nil
        mockProfile = nil
        mockLogger = nil
        super.tearDown()
    }

    func testFetchAddressesSuccess() {
        let addresses = dummyAddresses
        mockAutofill.mockListAllAddressesResult = .success(addresses)

        let addressesExpectation = XCTestExpectation(description: "Fetch addresses")
        let showSectionExpectation = XCTestExpectation(description: "Show section")

        viewModel.fetchAddresses()

        viewModel
            .$addresses
        // Drop first to ignore the initial value
            .dropFirst()
            .sink { value in
                XCTAssertEqual(value, addresses)
                addressesExpectation.fulfill()
            }
            .store(in: &cancellables)

        viewModel
            .$showSection
            .dropFirst()
            .sink { value in
                XCTAssertTrue(value)
                showSectionExpectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [addressesExpectation, showSectionExpectation], timeout: 1)
    }

    func testFetchAddressesFailure() {
        let error = NSError(domain: "test", code: 1, userInfo: nil)
        mockAutofill.mockListAllAddressesResult = .failure(error)

        viewModel.fetchAddresses()

        XCTAssertTrue(viewModel.addresses.isEmpty)
        XCTAssertFalse(viewModel.showSection)
    }

    func testInjectJSONDataInitSuccess() throws {
        let address = dummyAddresses[0]
        viewModel.destination = .edit(address)

        let javascript = try viewModel.getInjectJSONDataInit()

        XCTAssertNotNil(javascript)
    }

    func testInjectJSONDataInitFailure() throws {
        viewModel.destination = nil
        do {
            _ = try viewModel.getInjectJSONDataInit()
            XCTFail("Parsing invalid JSON should throw an error")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func testTapAddShowsAddAddressScreenThenTapCancelDismissScreen() {
        let showSectionAddExpectation = XCTestExpectation(description: "Show add section")
        let dismissSectionAddExpectation = XCTestExpectation(description: "Dismiss add section")
        viewModel.currentRegionCode = { "RO" }
        viewModel.addAddressButtonTap()

        let cancellable = viewModel
            .$destination
            .dropFirst()
            .sink { value in
                XCTAssertEqual(value, .add(Address(
                    guid: "",
                    name: "",
                    organization: "",
                    streetAddress: "",
                    addressLevel3: "",
                    addressLevel2: "",
                    addressLevel1: "",
                    postalCode: "",
                    country: "RO",
                    tel: "",
                    email: "",
                    timeCreated: 0,
                    timeLastUsed: nil,
                    timeLastModified: 0,
                    timesUsed: 0
                )))
                showSectionAddExpectation.fulfill()
            }
        cancellable.cancel()

        viewModel.cancelAddButtonTap()

        viewModel
            .$destination
            .dropFirst()
            .sink { value in
                XCTAssertNil(value)
                dismissSectionAddExpectation.fulfill()
            }
            .store(in: &cancellables)
    }

    func testTapSaveAddressScreenDismissScreenAndCallesAddressFetching() {
        let address = dummyAddresses[0]
        mockAutofill.mockSaveAddressResult = .success(address)
        viewModel.saveAction = { completion in
            completion(UpdatableAddressFields(
                name: "John Doe",
                organization: "Acme Corp",
                streetAddress: "123 Main St",
                addressLevel3: "Suite 100",
                addressLevel2: "San Francisco",
                addressLevel1: "CA",
                postalCode: "94101",
                country: "USA",
                tel: "+1-555-1234",
                email: "john.doe@example.com"
            ))
        }
        let dismissSectionAddExpectation = XCTestExpectation(description: "Dimiss add section")
        let newAddressesSectionExpectation = XCTestExpectation(description: "New address loaded")

        viewModel.addAddressButtonTap()
        viewModel.saveAddressButtonTap()

        viewModel
            .$destination
            .dropFirst()
            .sink { value in
                XCTAssertNil(value)
                dismissSectionAddExpectation.fulfill()
            }
            .store(in: &cancellables)

        viewModel
            .$addresses
            .dropFirst()
            .sink { _ in
                XCTAssertEqual(self.mockAutofill.listAllAddressesCalled, true)
                newAddressesSectionExpectation.fulfill()
            }
            .store(in: &cancellables)
    }

    func testTappingOnAddressAndTapCancelDissmissesEditScreen() {
        let address = dummyAddresses[0]

        viewModel.addressTapped(address)
        XCTAssertEqual(viewModel.destination, .edit(address))

        viewModel.editButtonTap()
        XCTAssertTrue(viewModel.isEditMode)

        viewModel.cancelEditButtonTap()
        XCTAssertFalse(viewModel.isEditMode)

        viewModel.closeEditButtonTap()
        XCTAssertNil(viewModel.destination)
    }

    func testRemoveButtonShowOnEditModeTappingRemovesAddress() {
        let address = dummyAddresses[0]

        viewModel.addressTapped(address)
        XCTAssertEqual(viewModel.destination, .edit(address))

        viewModel.editButtonTap()
        XCTAssertTrue(viewModel.isEditMode)

        viewModel.removeConfimationButtonTap()
        XCTAssertTrue(mockAutofill.deleteAddressesCalled)
    }
}

final class MockAutofill: AddressProvider {
    var mockListAllAddressesResult: Result<[Address], Error>?
    var mockSaveAddressResult: Result<Address, Error>?
    var mockEditAddressResult: Result<Void, Error>?
    var listAllAddressesCalled = false
    var deleteAddressesCalled = false

    func deleteAddress(
        id: String,
        completion: @escaping (Result<Void, any Error>) -> Void
    ) {
        deleteAddressesCalled = true
    }

    func addAddress(
        address: UpdatableAddressFields,
        completion: @escaping (Result<Address, Error>) -> Void
    ) {
        if let result = mockSaveAddressResult {
            completion(result)
        }
    }

    func updateAddress(
        id: String,
        address: MozillaAppServices.UpdatableAddressFields,
        completion: @escaping (Result<Void, any Error>) -> Void
    ) {
        if let result = mockEditAddressResult {
            completion(result)
        }
    }

    func listAllAddresses(completion: @escaping ([Address]?, Error?) -> Void) {
        listAllAddressesCalled = true
        if let result = mockListAllAddressesResult {
            switch result {
            case .success(let addresses):
                completion(addresses, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
}
