// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct PageZoomSettingsView: View {
    private struct UX {
        static let spacing: CGFloat = 24
    }

    private var viewBackground: Color {
        return Color(theme.colors.layer1)
    }

    var sectionTitleColor: Color {
        return Color(theme.colors.textSecondary)
    }

    private let theme: Theme
    let siteZooms: [String] = ["amazon.com", "wikipedia.org"]

    init(theme: Theme) {
        self.theme = theme
    }

    var body: some View {
        VStack {
            List {
                Section {
                    ForEach(ZoomLevel.allCases, id: \.displayName) { item in
                        Text(item.displayName)
                    }
                    .listRowBackground(theme.colors.layer2.color)
                } header: {
                    // TODO: String
                    GenericSectionHeaderView(title: "DEFAULT", sectionTitleColor: sectionTitleColor)
                }

                Section {
                    ForEach(siteZooms, id: \.self) { item in
                        Text(item)
                    }
                    .listRowBackground(theme.colors.layer2.color)
                } header: {
                    // TODO: String
                    GenericSectionHeaderView(title: "SPECIFIC SITE SETTINGS", sectionTitleColor: sectionTitleColor)
                }
            }
            .listStyle(.plain)
        }
//        .padding(.top, UX.spacing)
        .frame(maxWidth: .infinity)
        .background(viewBackground)
        .onAppear {
            applyTheme()
        }
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
            applyTheme()
        }
    }

    func applyTheme() {
        // TODO: Apply theme
    }
}
