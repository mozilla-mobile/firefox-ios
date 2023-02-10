// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI

struct CreditCardSettingsEmptyView: View {
    var body: some View {
        ZStack {
            Color(UIColor.clear)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()
                Spacer()
                    .frame(height: 25)
                Image(ImageIdentifiers.creditCardPlaceholder)
                    .resizable()
                    .frame(width: 200, height: 200)
                    .aspectRatio(contentMode: .fit)
                    .fixedSize()
                    .padding([.top], 10)
                Text(String.CreditCard.Settings.EmptyListTitle)
                    .font(.system(size: 22))
                    .padding(.leading, 10)
                    .padding(.trailing, 10)
                Text(String.CreditCard.Settings.EmptyListDescription)
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.leading, 10)
                    .padding(.trailing, 10)
                    .padding([.top], -5)
                Spacer()
            }
        }
    }
}

struct CreditCardSettingsEmptyView_Previews: PreviewProvider {
    static var previews: some View {
        CreditCardSettingsEmptyView()
    }
}
