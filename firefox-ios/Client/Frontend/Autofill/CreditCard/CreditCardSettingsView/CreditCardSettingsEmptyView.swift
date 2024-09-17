// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import SwiftUI
import Shared

struct CreditCardSettingsEmptyView: View {
    // Theming
    let windowUUID: WindowUUID
    @Environment(\.themeManager)
    var themeManager
    @State var titleTextColor: Color = .clear
    @State var subTextColor: Color = .clear
    @State var toggleTextColor: Color = .clear
    @State var imageColor: Color = .clear

    @ObservedObject var toggleModel: ToggleModel

    var body: some View {
        ZStack {
            UIColor.clear.color
                .edgesIgnoringSafeArea(.all)
            GeometryReader { proxy in
                ScrollView {
                    scrollViewContent
                        .frame(minHeight: proxy.size.height)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
            guard let uuid = notification.windowUUID, uuid == windowUUID else { return }
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
    }

    private var scrollViewContent: some View {
        return VStack {
            creditCardAutofillToggle
            Spacer()
            creditCardImage
            emptyListTitle
            getEmptyListDescription()
            Spacer()
            Spacer()
        }
    }

    private var creditCardAutofillToggle: some View {
        return CreditCardAutofillToggle(
            windowUUID: windowUUID,
            textColor: toggleTextColor,
            model: toggleModel)
        .background(Color.white)
        .padding(.top, 25)
    }

    private var creditCardImage: some View {
        return Image(StandardImageIdentifiers.Large.creditCard)
            .resizable()
            .renderingMode(.template)
            .foregroundColor(imageColor)
            .frame(width: 200, height: 200)
            .aspectRatio(contentMode: .fit)
            .fixedSize()
            .padding([.top], 10)
            .accessibility(hidden: true)
    }

    private var emptyListTitle: some View {
        return Text(String(format: .CreditCard.Settings.EmptyListTitle,
                           AppName.shortName.rawValue))
        .preferredBodyFont(size: 22)
        .foregroundColor(titleTextColor)
        .multilineTextAlignment(.center)
        .padding(.leading, 10)
        .padding(.trailing, 10)
    }

    private func getEmptyListDescription() -> some View {
        return Text(String.CreditCard.Settings.EmptyListDescription)
            .preferredBodyFont(size: 16)
            .foregroundColor(subTextColor)
            .multilineTextAlignment(.center)
            .padding(.leading, 10)
            .padding(.trailing, 10)
            .padding([.top], -5)
    }

    func applyTheme(theme: Theme) {
        let color = theme.colors
        titleTextColor = Color(color.textPrimary)
        subTextColor = Color(color.textSecondary)
        toggleTextColor = Color(color.textPrimary)
        imageColor = Color(color.iconSecondary)
    }
}

struct CreditCardSettingsEmptyView_Previews: PreviewProvider {
    static var previews: some View {
        let toggleModel = ToggleModel(isEnabled: true)
        CreditCardSettingsEmptyView(windowUUID: .XCTestDefaultUUID,
                                    toggleModel: toggleModel)
    }
}
