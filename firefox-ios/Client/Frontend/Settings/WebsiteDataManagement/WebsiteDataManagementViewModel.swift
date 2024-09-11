// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

class WebsiteDataManagementViewModel {
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

    private func removeSelectedRecords() {
        let previousState = state
        state = .loading
        onViewModelChanged()

        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        WKWebsiteDataStore.default().removeData(ofTypes: types, for: Array(selectedRecords)) { [weak self] in
            self?.state = previousState
            self?.siteRecords.removeAll { self?.selectedRecords.contains($0) ?? false }
            self?.selectedRecords = []
            self?.onViewModelChanged()
        }
    }

    private func removeAllRecords() {
        let previousState = state
        state = .loading
        onViewModelChanged()

        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        WKWebsiteDataStore.default().removeData(ofTypes: types, modifiedSince: .distantPast) { [weak self] in
            self?.siteRecords = []
            self?.selectedRecords = []
            self?.state = previousState
            self?.onViewModelChanged()
        }
    }
}
