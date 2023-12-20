// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI

struct ToastView: View {
    var textColor: Color = .white
    var backgroundColor: Color = .blue
    var messageType: CreditCardModifiedStatus
    @State var isShowing = false

    var toast: some View {
        VStack {
            Spacer()
            Text(messageType.message)
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding()
                .background(backgroundColor)
                .foregroundColor(textColor)
        }
    }

    var body: some View {
        withAnimation(.default) {
            VStack {
            }
            .toast(toastView: toast, isShowing: $isShowing)
            .transition(AnyTransition.move(edge: .bottom))
        }
    }
}

struct ToastModifier<T: View>: ViewModifier {
    @Binding var isShowing: Bool
    let toastView: T
    var duration: TimeInterval = 3

    func body(content: Content) -> some View {
        ZStack {
            content
            if isShowing {
                toastView
                .onAppear(perform: hideToast)
            }
        }
    }

    private func hideToast() {
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation {
                isShowing.toggle()
            }
        }
    }
}

extension View {
    func toast<T: View>(toastView: T,
                        isShowing: Binding<Bool>) -> some View {
        modifier(ToastModifier(isShowing: isShowing, toastView: toastView))
    }
}
