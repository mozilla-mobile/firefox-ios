// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI
import Storage

class PageZoomSettingsViewModel: ObservableObject {
    private let zoomManager: ZoomPageManager
    @Published var domainZoomLevels: [DomainZoomLevel]

    init(zoomManager: ZoomPageManager) {
        self.zoomManager = zoomManager
        self.domainZoomLevels = zoomManager.getDomainLevel()
    }

    func resetDomainZoomLevel() {
        domainZoomLevels.removeAll()
        zoomManager.resetDomainZoomLevel()
    }

    func deleteZoomLevel(at indexSet: IndexSet) {
//        for index in offsets {
//            let item = domainZoomLevels[index]
//            zoomManager.deleteZoomLevel(for: item.domain) // Your DB/file logic
//        }
//        domainZoomLevels.remove(atOffsets: offsets)
        guard let index = indexSet.first else { return }

        let deleteItem = domainZoomLevels[index]
        zoomManager.deleteZoomLevel(for: deleteItem.host)
        domainZoomLevels.remove(at: index)
    }
}

struct PageZoomSettingsView: View {
    private let windowUUID: WindowUUID
    @ObservedObject var viewModel: PageZoomSettingsViewModel
    private let zoomManager: ZoomPageManager
    @Environment(\.themeManager)
    var themeManager
    @State private var themeColors: ThemeColourPalette = LightTheme().colors

    private struct UX {
        static var dividerHeight: CGFloat { 0.7 }
        static var buttonPadding: CGFloat { 4 }
    }

    private var viewBackground: Color {
        return themeColors.layer1.color
    }

    var sectionTitleColor: Color {
        return themeColors.textSecondary.color
    }

    var textColor: Color {
        return themeColors.textPrimary.color
    }

    var descriptionTextColor: Color {
        return themeColors.textSecondary.color
    }

    init(windowUUID: WindowUUID) {
        self.windowUUID = windowUUID
        self.zoomManager = ZoomPageManager(windowUUID: windowUUID)
        self.viewModel = PageZoomSettingsViewModel(zoomManager: zoomManager)
    }

    var theme: Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }

    var body: some View {
        VStack {
            List {
                // Default level picker
                Section {
                    ZoomLevelPickerView(theme: theme, zoomManager: zoomManager)
                        .background(themeColors.layer1.color)
                } header: {
                    GenericSectionHeaderView(title: .Settings.Appearance.PageZoom.DefaultSectionHeader.uppercased(),
                                             sectionTitleColor: sectionTitleColor)
                }

                // Specific site zoom levels
                Section {
                    ZoomSiteListView(theme: theme,
                                     domainZoomLevels: $viewModel.domainZoomLevels,
                                     onDelete: viewModel.deleteZoomLevel)
                        .background(themeColors.layer1.color)
                } header: {
                    GenericSectionHeaderView(title: .Settings.Appearance.PageZoom.SpecificSiteSectionHeader.uppercased(),
                                             sectionTitleColor: sectionTitleColor)
                } footer: {
                    Text(String.Settings.Appearance.PageZoom.SpecificSiteFooterTitle)
                        .background(themeColors.layer1.color)
                        .font(.caption)
                        .foregroundColor(descriptionTextColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .listStyle(.plain)
            .listRowBackground(theme.colors.layer2.color)

            VStack {
                Divider().frame(height: UX.dividerHeight)

                Button(action: {
                    viewModel.resetDomainZoomLevel()
                }) {
                    Text(String.Settings.Appearance.PageZoom.ResetButtonTitle)
                        .foregroundColor(theme.colors.textCritical.color)
                }
                .padding([.top, .bottom], UX.buttonPadding)

                Divider().frame(height: UX.dividerHeight)
            }
        }
        .background(themeColors.layer1.color)
        .frame(maxWidth: .infinity)
        .onAppear {
            themeColors = themeManager.getCurrentTheme(for: windowUUID).colors
        }
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
            guard let uuid = notification.windowUUID, uuid == windowUUID else { return }
            themeColors = themeManager.getCurrentTheme(for: windowUUID).colors
        }
    }
}
