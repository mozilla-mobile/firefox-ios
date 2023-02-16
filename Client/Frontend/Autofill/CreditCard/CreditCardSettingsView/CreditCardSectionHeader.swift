// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

struct CreditCardSectionHeader: View {
    var textColor: Color

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
    }
}

struct CreditCardSectionHeader_Previews: PreviewProvider {
    static var previews: some View {
        CreditCardSectionHeader(textColor: .black)
    }
}
