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

    var textColor: Color {
        return Color(theme.colors.textPrimary)
    }

    private let theme: Theme
    let siteZooms: [String] = ["amazon.com",
                               "wikipedia.org"]

    init(theme: Theme) {
        self.theme = theme
    }

    var body: some View {
        VStack {
            List {
                Section {
                    ZoomLevelPickerView(theme: theme)
                } header: {
                    GenericSectionHeaderView(title: .DefaultZoomLevelSectionTitle.uppercased(),
                                             sectionTitleColor: sectionTitleColor)
                }

                Section {
                    ForEach(siteZooms, id: \.self) { item in
                        HStack {
                            Text(item)
                                .font(.body)
                                .foregroundColor(textColor)

                            Spacer()

                            Text("50%")
                                .padding([.trailing], 10)
                                .font(.body)
                                .foregroundColor(textColor)
                        }
                    }
                    .onDelete(perform: delete)
                    .listRowBackground(theme.colors.layer2.color)
                } header: {
                    GenericSectionHeaderView(title: .SpecificSiteZoomSectionTitle.uppercased(),
                                             sectionTitleColor: sectionTitleColor)
                }
                Section {
                    Button(action: {}) {
                        Text("Red thin text")
                            .padding([.leading, .trailing], 10)
                            .font(.title)
                            .foregroundColor(.red)
                            .background(.orange)
                    }
                    .padding([.top], 10)
                }
            }
            .listStyle(.plain)
        }
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

    func delete(at index: IndexSet) {
    }
}
