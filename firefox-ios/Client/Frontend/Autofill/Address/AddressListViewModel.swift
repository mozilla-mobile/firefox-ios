// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import Shared
import Storage
import struct MozillaAppServices.UpdatableAddressFields
import struct MozillaAppServices.Address

final class AddressListViewModel: ObservableObject, FeatureFlaggable {
    enum Destination: Swift.Identifiable, Equatable {
        case add(Address)
        case edit(Address)

        var id: String {
            switch self {
            case .add(let value):
                return value.guid
            case .edit(let value):
                return value.guid
            }
        }
    }

    // MARK: - Properties

    @Published var addresses: [Address] = []
    @Published var showSection = false
    @Published var destination: Destination?
    @Published var isEditMode = false

    let windowUUID: WindowUUID

    private let logger: Logger

    var isEditingFeatureEnabled: Bool { featureFlags.isFeatureEnabled(.addressAutofillEdit, checking: .buildOnly) }

    var addressSelectionCallback: ((UnencryptedAddressFields) -> Void)?
    var saveAction: ((@escaping (UpdatableAddressFields) -> Void) -> Void)?
    var toggleEditModeAction: ((Bool) -> Void)?
    var presentToast: ((AddressModifiedStatus) -> Void)?
    var manageAddressesInfoAction: (() -> Void)?

    let addressProvider: AddressProvider
    let themeManager: ThemeManager
    let profile: Profile

    var currentRegionCode: () -> String = { Locale.current.regionCode ?? "" }
    var isDarkTheme: Bool {
        themeManager.getCurrentTheme(for: windowUUID).type == .dark
    }
    var hasSyncableAccount: Bool {
        profile.hasSyncableAccount()
    }

    let editAddressWebViewManager: WebViewPreloadManaging

    var cancelButtonLabel: String {
        isEditMode ?
            .Addresses.Settings.Edit.AutofillCancelButton :
            .Addresses.Settings.Edit.CloseNavBarButtonLabel
    }

    var primaryButtonLabel: String {
        isEditMode ?
            .Addresses.Settings.Edit.AutofillSaveButton :
            .Addresses.Settings.Edit.EditNavBarButtonLabel
    }

    var editNavigationbarTitle: String {
        isEditMode ?
            .Addresses.Settings.Edit.AutofillEditAddressTitle :
            .Addresses.Settings.Edit.AutofillViewAddressTitle
    }

    // MARK: - Initializer

    /// Initializes the AddressListViewModel.
    init(
        logger: Logger = DefaultLogger.shared,
        windowUUID: WindowUUID,
        addressProvider: AddressProvider,
        editAddressWebViewManager: WebViewPreloadManaging = EditAddressWebViewManager(),
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        profile: Profile = AppContainer.shared.resolve()
    ) {
        self.logger = logger
        self.windowUUID = windowUUID
        self.addressProvider = addressProvider
        self.editAddressWebViewManager = editAddressWebViewManager
        self.themeManager = themeManager
        self.profile = profile
    }

    // MARK: - Fetch Addresses

    /// Fetches addresses from the associated profile's autofill.
    func fetchAddresses() {
        // Assuming profile is a class-level variable
        addressProvider.listAllAddresses { [weak self] storedAddresses, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let addresses = storedAddresses {
                    self.addresses = addresses
                    self.showSection = !addresses.isEmpty
                } else if let error = error {
                    self.logger.log(
                        "Error fetching addresses",
                        level: .warning,
                        category: .autofill,
                        description: "Error fetching addresses: \(error.localizedDescription)"
                    )
                }
            }
        }
    }

    /// Converts an Address object to UnencryptedAddressFields.
    /// - Parameter address: The address to be converted.
    /// - Returns: The UnencryptedAddressFields representation of the address.
    func fromAddress(_ address: Address) -> UnencryptedAddressFields {
        return UnencryptedAddressFields(addressLevel1: address.addressLevel1,
                                        organization: address.organization,
                                        country: address.country,
                                        addressLevel2: address.addressLevel2,
                                        addressLevel3: address.addressLevel3,
                                        email: address.email,
                                        streetAddress: address.streetAddress,
                                        name: address.name,
                                        postalCode: address.postalCode,
                                        tel: address.tel)
    }

    // MARK: - Handle Address Selection

    /// Handles the selection of an address.
    /// - Parameter address: The selected address.
    func handleAddressSelection(_ address: Address) {
        addressSelectionCallback?(fromAddress(address))
    }

    func addressTapped(_ address: Address) {
        destination = .edit(address)
    }

    func cancelAddButtonTap() {
        destination = nil
    }

    func editButtonTap() {
        toggleEditMode()
    }

    func saveEditButtonTap() {
        saveAction? { [weak self] updatedAddress in
            guard let self else { return }
            guard case .edit(let currentAddress) = self.destination else { return }
            self.updateLocal(id: currentAddress.guid, updatedAddress: updatedAddress)
        }
        toggleEditMode()
    }

    private func updateLocal(id: String, updatedAddress: UpdatableAddressFields) {
        self.addressProvider.updateAddress(id: id, address: updatedAddress) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.presentToast?(.updated)
                case .failure:
                    self.presentToast?(
                        .error(
                            .update(action: { [weak self] in
                                self?.destination = .edit(
                                    Address(
                                        guid: id,
                                        name: updatedAddress.name,
                                        organization: updatedAddress.organization,
                                        streetAddress: updatedAddress.streetAddress,
                                        addressLevel3: updatedAddress.addressLevel3,
                                        addressLevel2: updatedAddress.addressLevel2,
                                        addressLevel1: updatedAddress.addressLevel1,
                                        postalCode: updatedAddress.postalCode,
                                        country: updatedAddress.country,
                                        tel: updatedAddress.tel,
                                        email: updatedAddress.email,
                                        timeCreated: 0,
                                        timeLastUsed: nil,
                                        timeLastModified: 0,
                                        timesUsed: 0
                                    )
                                )
                            })
                        )
                    )
                }
                self.destination = nil
                self.fetchAddresses()
            }
        }
    }

    func closeEditButtonTap() {
        destination = nil
    }

    func cancelEditButtonTap() {
        toggleEditMode()
    }

    func saveAddressButtonTap() {
        saveAction? { [weak self] address in
            guard let self else { return }
            self.saveLocal(address: address)
        }
    }

    private func saveLocal(address: UpdatableAddressFields) {
        self.addressProvider.addAddress(address: address) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.presentToast?(.saved)
                case .failure:
                    self.presentToast?(
                        .error(
                            .save(action: { [weak self] in
                                self?.destination = .add(
                                    Address(
                                        guid: "",
                                        name: address.name,
                                        organization: address.organization,
                                        streetAddress: address.streetAddress,
                                        addressLevel3: address.addressLevel3,
                                        addressLevel2: address.addressLevel2,
                                        addressLevel1: address.addressLevel1,
                                        postalCode: address.postalCode,
                                        country: address.country,
                                        tel: address.tel,
                                        email: address.email,
                                        timeCreated: 0,
                                        timeLastUsed: nil,
                                        timeLastModified: 0,
                                        timesUsed: 0
                                    )
                                )
                            })
                        )
                    )
                }
                self.destination = nil
                self.fetchAddresses()
            }
        }
    }

    func addAddressButtonTap() {
        destination = .add(Address(
            guid: "",
            name: "",
            organization: "",
            streetAddress: "",
            addressLevel3: "",
            addressLevel2: "",
            addressLevel1: "",
            postalCode: "",
            country: currentRegionCode(),
            tel: "",
            email: "",
            timeCreated: 0,
            timeLastUsed: nil,
            timeLastModified: 0,
            timesUsed: 0
        ))
    }

    func removeConfimationButtonTap() {
        if case .edit(let address) = destination {
            removeLocal(address: address)
        }
    }

    private func removeLocal(address: Address) {
        addressProvider.deleteAddress(id: address.id) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.presentToast?(.removed)
                case .failure:
                    self.presentToast?(
                        .error(
                            .remove(action: { [weak self] in
                                self?.destination = .edit(address)
                            })
                        )
                    )
                }
                self.toggleEditMode()
                self.destination = nil
                self.fetchAddresses()
            }
        }
    }

    private func toggleEditMode() {
        isEditMode.toggle()
        toggleEditModeAction?(isEditMode)
    }

    // MARK: - Inject JSON Data

    struct JSONDataError: Error {}

    func getInjectJSONDataInit() throws -> String {
        guard let destination = self.destination else {
            throw JSONDataError()
        }

        do {
            let address: Address =
            switch destination {
            case .add(let address):
                address
            case .edit(let address):
                address
            }

            let addressString = try jsonString(from: address)
            let l10sString = try jsonString(from: EditAddressLocalization.editAddressLocalizationIDs)
            let javascript = "init(\(addressString), \(l10sString), \(isDarkTheme));"
            return javascript
        } catch {
            logger.log(
                "Failed to encode data",
                level: .warning,
                category: .autofill,
                description: "Failed to encode data with error: \(error.localizedDescription)"
            )
            throw error
        }
    }

    private func jsonString<T: Encodable>(from object: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.userInfo[.formatStyleKey] = FormatStyle.kebabCase
        let data = try encoder.encode(object)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw EncodingError.invalidValue(
                object,
                EncodingError.Context(codingPath: [], debugDescription: "Unable to convert data to String")
            )
        }
        return jsonString.replacingOccurrences(of: "\\", with: "\\\\")
    }
}
