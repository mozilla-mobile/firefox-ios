// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Shared
import Common
import ComponentLibrary

struct AddressAutoFillBottomSheetView: View {
    let windowUUID: WindowUUID
    @Environment(\.themeManager)
    var themeManager

    @ObservedObject var addressListViewModel: AddressListViewModel
    @State private var backgroundColor: Color = .clear

    // MARK: - Body

    var body: some View {
        VStack {
            AutofillHeaderView(
                windowUUID: windowUUID,
                title: .Addresses.BottomSheet.UseASavedAddress
            )
            AddressScrollView(
                windowUUID: windowUUID,
                viewModel: addressListViewModel
            )
            AutofillFooterView(
                windowUUID: windowUUID,
                title: .Addresses.BottomSheet.ManageAddressesButton,
                primaryAction: { addressListViewModel.manageAddressesInfoAction?() }
            )
        }
        .padding()
        .background(backgroundColor)
        .onAppear {
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
            guard let uuid = notification.windowUUID, uuid == windowUUID else { return }
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
    }

    func applyTheme(theme: Theme) {
        let color = theme.colors
        backgroundColor = Color(color.layer1)
    }
}
