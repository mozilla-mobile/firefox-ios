// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI

struct CreditCardSettingsEmptyView: View {
    struct Colors {
        let titleTextColor: Color
        let subTextColor: Color
        let toggleTextColor: Color
    }

    let colors: Colors
    @State var isToggleOn: Bool = false

    var body: some View {
        ZStack {
            Color(UIColor.clear)
                .edgesIgnoringSafeArea(.all)
            GeometryReader { proxy in
                ScrollView {
                    VStack {
                        CreditCardAutofillToggle(textColor: colors.toggleTextColor, isToggleOn: isToggleOn)
                        Spacer()
                        Image("credit_card_placeholder")
                            .resizable()
                            .frame(width: 200, height: 200)
                            .aspectRatio(contentMode: .fit)
                            .fixedSize()
                            .padding([.top], 10)
                        Text(String.CreditCard.Settings.EmptyListTitle)
                            .preferredBodyFont(size: 22)
                            .foregroundColor(colors.titleTextColor)
                            .multilineTextAlignment(.center)
                            .padding(.leading, 10)
                            .padding(.trailing, 10)
                        Text(String.CreditCard.Settings.EmptyListDescription)
                            .preferredBodyFont(size: 16)
                            .foregroundColor(colors.subTextColor)
                            .multilineTextAlignment(.center)
                            .padding(.leading, 10)
                            .padding(.trailing, 10)
                            .padding([.top], -5)
                        Spacer()
                    }
                    .frame(minHeight: proxy.size.height)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct CreditCardSettingsEmptyView_Previews: PreviewProvider {
    static var previews: some View {
        let colors = CreditCardSettingsEmptyView.Colors(titleTextColor: .gray,
                                                        subTextColor: .gray,
                                                        toggleTextColor: .gray)
        CreditCardSettingsEmptyView(colors: colors, isToggleOn: true)
    }
}
