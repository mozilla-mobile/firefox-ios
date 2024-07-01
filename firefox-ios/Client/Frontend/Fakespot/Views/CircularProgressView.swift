// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct CircularProgressView: View, ThemeApplicable {
    let windowUUID: WindowUUID
    @Environment(\.themeManager)
    var themeManager
    @ObservedObject var viewModel: FakespotMessageCardViewModel
    @State private var backgroundColor: Color = .gray
    @State private var foregroundColor: Color = .blue

    private var progress: Double {
        viewModel.analysisProgress / 100.0
    }

    var body: some View {
        progressCircularView
            .onAppear {
                applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
            }
            .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
                guard let uuid = notification.windowUUID, uuid == windowUUID else { return }
                applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
            }
    }

    @ViewBuilder private var progressCircularView: some View {
        ZStack {
            Circle()
                .stroke(
                    backgroundColor,
                    lineWidth: 6
                )
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    foregroundColor,
                    style: StrokeStyle(
                        lineWidth: 6
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
        }
    }

    // MARK: Theming System
    func applyTheme(theme: Theme) {
        let colors = theme.colors
        backgroundColor = Color(colors.borderPrimary)
        foregroundColor = Color(colors.borderAccent)
    }
}
