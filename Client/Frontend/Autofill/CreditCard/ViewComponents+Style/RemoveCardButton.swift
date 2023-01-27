// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI

struct RemoveCardButton: View {
    @ObservedObject var viewModel: CreditCardListViewModel
    
    var body: some View {
        VStack {
            Divider()
                .frame(height: 0.7)
                .padding(.leading, 16)
                .hidden()
            HStack {
                Toggle(isOn: $viewModel.toggleState) {
                    Text("Save and autofill cards")
                }.font(.system(size: 17))
                 .padding(.leading, 16)
                 .padding(.trailing, 16)
//                 .tint(viewModel.toggleState ? .blue : .gray)
            }
            Divider()
                .frame(height: 0.7)
                .padding(.leading, 16)
        }
        .frame(width: UIScreen.main.bounds.size.width, height: 42)
//        .background(.white)
    }
}

struct RemoveCardButton_Previews: PreviewProvider {
    static var previews: some View {
        
        RemoveCardButton(viewModel: CreditCardListViewModel())
    }
}
