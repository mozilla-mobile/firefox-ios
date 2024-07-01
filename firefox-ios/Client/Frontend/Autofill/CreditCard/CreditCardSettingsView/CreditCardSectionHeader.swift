// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI
import Shared

struct CreditCardSectionHeader: View {
    // Theming
    let windowUUID: WindowUUID
    @Environment(\.themeManager)
    var themeManager
    @State var textColor: Color = .clear

    var body: some View {
        VStack(alignment: .leading) {
            Text(String.CreditCard.EditCard.SavedCardListTitle)
                .font(.caption)
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity,
                       alignment: .leading)
        }
        .padding(EdgeInsets(top: 24,
                            leading: 16,
                            bottom: 8,
                            trailing: 16))
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
        textColor = Color(color.textSecondary)
    }
}

struct CreditCardSectionHeader_Previews: PreviewProvider {
    static var previews: some View {
        CreditCardSectionHeader(windowUUID: .XCTestDefaultUUID)
    }
}
