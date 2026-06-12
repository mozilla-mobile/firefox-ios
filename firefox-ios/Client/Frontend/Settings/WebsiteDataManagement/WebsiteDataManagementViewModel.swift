// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

// TODO: FXIOS-14216 - WebsiteDataManagementViewModel shouldn't be @unchecked Sendable
final class WebsiteDataManagementViewModel: @unchecked Sendable {
    enum State {
        case loading
        case displayInitial
        case displayAll
    }

    private(set) var state: State = .loading
    private(set) var siteRecords: [WKWebsiteDataRecord] = []
    private(set) var selectedRecords: Set<WKWebsiteDataRecord> = []
    var onViewModelChanged: () -> Void = {}

    var clearButtonTitle: String {
        switch selectedRecords.count {
        case 0: return .SettingsClearAllWebsiteDataButton
        default: return String(format: .SettingsClearSelectedWebsiteDataButton, "\(selectedRecords.count)")
        }
    }

    @MainActor
    func loadAllWebsiteData() {
        state = .loading

        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: types) { [weak self] records in
            self?.siteRecords = records.sorted { $0.displayName < $1.displayName }
            self?.state = .displayInitial
            self?.onViewModelChanged()
        }

        self.onViewModelChanged()
    }

    func selectItem(_ item: WKWebsiteDataRecord) {
        selectedRecords.insert(item)
        onViewModelChanged()
    }

    func deselectItem(_ item: WKWebsiteDataRecord) {
        selectedRecords.remove(item)
        onViewModelChanged()
    }

    @MainActor
    func createAlertToRemove() -> UIAlertController {
        if selectedRecords.isEmpty {
            return UIAlertController.clearAllWebsiteDataAlert { _ in self.removeAllRecords() }
        } else {
            return UIAlertController.clearSelectedWebsiteDataAlert { _ in self.removeSelectedRecords() }
        }
    }

    func showMoreButtonPressed() {
        state = .displayAll
    }

    @MainActor
    private func removeSelectedRecords() {
        let previousState = state
        state = .loading
        onViewModelChanged()

        let recordsToRemove = Array(selectedRecords)
        Task { @MainActor [weak self] in
            guard let self else { return }
            await CertificateExceptionClearing.clearSelectedWebsiteData(recordsToRemove)
            state = previousState
            siteRecords.removeAll { selectedRecords.contains($0) }
            selectedRecords = []
            onViewModelChanged()
        }
    }

    @MainActor
    private func removeAllRecords() {
        let previousState = state
        state = .loading
        onViewModelChanged()

        Task { @MainActor [weak self] in
            guard let self else { return }
            await CertificateExceptionClearing.clearAllWebsiteData()
            siteRecords = []
            selectedRecords = []
            state = previousState
            onViewModelChanged()
        }
    }
}
