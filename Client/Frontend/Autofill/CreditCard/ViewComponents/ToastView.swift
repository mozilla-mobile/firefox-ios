// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI

struct ToastModifier: ViewModifier {
    @Binding var isShowing: Bool
    let duration: TimeInterval

    func body(content: Content) -> some View {
        ZStack {
            content
            if isShowing {
                toast
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        withAnimation {
                            isShowing = false
                        }
                    }
                }
            }
        }
    }

    private var toast: some View {
        return ToastView()
    }
}

extension View {
    func toast(isShowing: Binding<Bool>, duration: TimeInterval = 3) -> some View {
        modifier(ToastModifier(isShowing: isShowing, duration: duration))
    }
}

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
                .background(backgroundColor)
                .foregroundColor(textColor)
        }
    }
}
