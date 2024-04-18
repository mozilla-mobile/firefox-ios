// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Shared
import Common
import ComponentLibrary

struct AddressAutoFillBottomSheetView: View {
    // MARK: - Properties

    let windowUUID: WindowUUID
    @Environment(\.themeManager)
    var themeManager

    /// The observed object for managing the address list.
    @ObservedObject var addressListViewModel: AddressListViewModel

    // MARK: - Body

    var body: some View {
        VStack {
            AutofillHeaderView(windowUUID: windowUUID, title: .Addresses.BottomSheet.UseASavedAddress)
            Spacer()
            AddressScrollView(windowUUID: windowUUID, viewModel: addressListViewModel)
            Spacer()
        }
        .padding()
        .background(Color(themeManager.currentTheme(for: windowUUID).colors.layer1))
    }
}
