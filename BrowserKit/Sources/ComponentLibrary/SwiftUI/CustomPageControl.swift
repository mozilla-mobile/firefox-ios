// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

public struct CustomPageControl: View {
    @State private var primaryActionColor: Color = .clear
    @State private var secondaryActionColor: Color = .clear
    @Binding var currentPage: Int
    let windowUUID: WindowUUID
    let themeManager: ThemeManager
    let numberOfPages: Int

    public init(
        currentPage: Binding<Int>,
        numberOfPages: Int,
        windowUUID: WindowUUID,
        themeManager: ThemeManager
    ) {
        self._currentPage = currentPage
        self.numberOfPages = numberOfPages
        self.windowUUID = windowUUID
        self.themeManager = themeManager
    }

    public var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<numberOfPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? primaryActionColor : secondaryActionColor)
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == currentPage ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
        .onAppear {
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) {
            guard let uuid = $0.windowUUID, uuid == windowUUID else { return }
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
    }

    private func applyTheme(theme: Theme) {
        let color = theme.colors
        primaryActionColor = Color(color.actionPrimary)
        secondaryActionColor = Color(color.iconDisabled)
    }
}
