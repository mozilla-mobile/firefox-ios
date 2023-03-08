// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI

struct ToastView: View {
    enum MessageType {
        case savedCard
        case updatedCard
        case removedCard
    }

    @State private var shouldShowToast = false
    var messageType: MessageType = .savedCard
    var textColor: Color = .white
    var backgroundColor: Color = .blue

    private var message: String {
        switch messageType {
        case .savedCard: return String.CreditCard.SnackBar.SavedCardLabel
        case .updatedCard: return String.CreditCard.SnackBar.UpdatedCardLabel
        case .removedCard: return String.CreditCard.SnackBar.RemovedCardLabel
        }
    }

    var body: some View {
        VStack {
            Spacer()
            Text(message)
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding()
                .foregroundColor(textColor)
                .background(backgroundColor)
        }
    }
}
