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

        var message: String {
            switch self {
            case .savedCard: return String.CreditCard.SnackBar.SavedCardLabel
            case .updatedCard: return String.CreditCard.SnackBar.UpdatedCardLabel
            case .removedCard: return String.CreditCard.SnackBar.RemovedCardLabel
            }
        }
    }

    var messageType: MessageType
    var textColor: Color = .white
    var backgroundColor: Color = .blue
    @Binding var isShowing: Bool

    var body: some View {
        VStack {
            Spacer()
            Text(messageType.message)
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding()
                .background(backgroundColor)
                .foregroundColor(textColor)
        }
        .animation(.easeInOut)
        .transition(AnyTransition.move(edge: .bottom))
        .onAppear(perform: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    isShowing = false
                }
            }
        })
    }
}

struct ToastModifier<T: View>: ViewModifier {
    @Binding var isShowing: Bool
    let toastView: T
    let duration: TimeInterval

    func body(content: Content) -> some View {
        ZStack {
            content
            if isShowing {
                toastView
            }
        }
    }
}

extension View {
    func toast<T: View>(toastView: T,
                        isShowing: Binding<Bool>,
                        duration: TimeInterval = 3) -> some View {
        modifier(ToastModifier(isShowing: isShowing, toastView: toastView, duration: 3))
    }
}
