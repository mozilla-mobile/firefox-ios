// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI

struct TabGroupEditorView: ThemeableView {
    private struct ColorOption: Identifiable {
        let id: String
        let localizedName: String
        let color: CodableColor
    }

    private static let symbolNames = [
        "rectangle.portrait.on.rectangle.portrait.angled.fill", "graduationcap.fill", "bag.fill", "cart.fill", "airplane",
        "house.fill", "person.fill", "pawprint.fill", "sparkles", "heart.fill",
        "star.fill", "hammer.fill", "map.fill", "list.bullet.circle.fill", "paintbrush.pointed.fill",
        "cloud.fill", "leaf.fill", "gamecontroller.fill", "soccerball", "american.football.fill",
        "shield.fill", "lock.fill", "key.horizontal.fill", "chart.bar.fill", "car.fill",
        "tv.fill", "folder.fill", "archivebox.fill", "books.vertical.fill", "wallet.bifold.fill",
        "lightbulb.fill", "party.popper.fill", "popcorn.fill", "bed.double.fill", "camera.fill"
    ]

    static var defaultColor: CodableColor {
        let color = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? NovaDarkTheme().colors.iconSecondary
                : NovaLightTheme().colors.iconSecondary
        }
        return CodableColor(uiColor: color)
            ?? CodableColor(red: 20 / 255, green: 9 / 255, blue: 43 / 255, alpha: 0.7)
    }

    private static var colorOptions: [ColorOption] {
        [
            ColorOption(id: "default", localizedName: String.TabGroups.ColorDefault, color: defaultColor),
            ColorOption(id: "black",
                        localizedName: String.TabGroups.ColorBlack,
                        color: CodableColor(red: 24 / 255, green: 14 / 255, blue: 48 / 255)),
            ColorOption(id: "red",
                        localizedName: String.TabGroups.ColorRed,
                        color: CodableColor(red: 197 / 255, green: 45 / 255, blue: 79 / 255)),
            ColorOption(id: "orange",
                        localizedName: String.TabGroups.ColorOrange,
                        color: CodableColor(red: 210 / 255, green: 67 / 255, blue: 0)),
            ColorOption(id: "brown",
                        localizedName: String.TabGroups.ColorBrown,
                        color: CodableColor(red: 178 / 255, green: 97 / 255, blue: 0)),
            ColorOption(id: "green",
                        localizedName: String.TabGroups.ColorGreen,
                        color: CodableColor(red: 0, green: 136 / 255, blue: 101 / 255)),
            ColorOption(id: "teal",
                        localizedName: String.TabGroups.ColorTeal,
                        color: CodableColor(red: 10 / 255, green: 128 / 255, blue: 159 / 255)),
            ColorOption(id: "blue",
                        localizedName: String.TabGroups.ColorBlue,
                        color: CodableColor(red: 69 / 255, green: 95 / 255, blue: 231 / 255)),
            ColorOption(id: "purple",
                        localizedName: String.TabGroups.ColorPurple,
                        color: CodableColor(red: 118 / 255, green: 78 / 255, blue: 221 / 255)),
            ColorOption(id: "pink",
                        localizedName: String.TabGroups.ColorPink,
                        color: CodableColor(red: 179 / 255, green: 46 / 255, blue: 159 / 255))
        ]
    }

    let isEditing: Bool
    let onCancel: () -> Void
    let onSave: (String, TabGroupIcon, CodableColor) -> Void
    let windowUUID: WindowUUID
    let themeManager: ThemeManager
    @State var theme: Theme

    var shouldUsePrivateOverride: Bool { true }
    var shouldBeInPrivateTheme: Bool { false }

    @FocusState private var isNameFocused: Bool
    @State private var name: String
    @State private var icon: TabGroupIcon
    @State private var color: CodableColor

    init(windowUUID: WindowUUID,
         themeManager: ThemeManager,
         name: String = "",
         icon: TabGroupIcon = .sfSymbol("rectangle.portrait.on.rectangle.portrait.angled.fill"),
         color: CodableColor = TabGroupEditorView.defaultColor,
         isEditing: Bool = false,
         onCancel: @escaping () -> Void,
         onSave: @escaping (String, TabGroupIcon, CodableColor) -> Void) {
        self.isEditing = isEditing
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.theme = themeManager.resolveTheme(for: windowUUID, privateOverride: false)
        self.onCancel = onCancel
        self.onSave = onSave
        _name = State(initialValue: name)
        _icon = State(initialValue: icon)
        _color = State(initialValue: color)
    }

    var body: some View {
        VStack(spacing: 16) {
            header
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    nameCard
                    colorCard
                    iconCard
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .simultaneousGesture(DragGesture().onChanged { _ in isNameFocused = false })
        }
        .padding(.top, 8)
        .background(Color(colors.layer1).ignoresSafeArea())
        .listenToThemeChanges(in: self, theme: $theme)
        .onAppear { isNameFocused = !isEditing }
    }

    private var colors: ThemeColourPalette { theme.colors }

    private var hasValidName: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var selectedColor: Color { color.swiftUIColor }
    private var isDefaultColor: Bool { color == Self.defaultColor }
    private var gridColumns: [GridItem] { Array(repeating: GridItem(.flexible(), spacing: 24), count: 5) }

    private var saveIconColor: Color {
        guard hasValidName else { return Color(colors.iconDisabled) }
        guard isDefaultColor else { return Color(colors.iconOnColor) }
        return Color(theme.isNova ? colors.iconInverted : colors.textInverted)
    }

    private var header: some View {
        ZStack {
            Text(isEditing ? String.TabGroups.EditTabGroup : String.TabGroups.NewTabGroup)
                .font(.headline)
                .foregroundStyle(Color(colors.textPrimary))
                .padding(.horizontal, 56)
                .accessibilityAddTraits(.isHeader)
            HStack {
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color(colors.iconSecondary))
                        .frame(width: 44, height: 44)
                        .background(Color(colors.layer3), in: Circle())
                }
                .accessibilityLabel(String.TabGroups.Cancel)
                Spacer()
                Button {
                    onSave(name.trimmingCharacters(in: .whitespacesAndNewlines), icon, color)
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(saveIconColor)
                        .frame(width: 44, height: 44)
                        .background(hasValidName ? selectedColor : Color(colors.layer3), in: Circle())
                }
                .disabled(!hasValidName)
                .accessibilityLabel(isEditing ? String.TabGroups.Save : String.TabGroups.Create)
                .accessibilityIdentifier("tabGroupEditor.save")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var nameCard: some View {
        VStack(spacing: 16) {
            Image(systemName: icon.systemImageName)
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(isDefaultColor ? Color(colors.iconSecondary) : Color(colors.iconOnColor))
                .frame(width: 96, height: 96)
                .background(isDefaultColor ? Color(colors.layer1) : selectedColor, in: Circle())
                .accessibilityHidden(true)
            TextField("", text: $name, prompt: Text(String.TabGroups.GroupName).foregroundColor(Color(colors.textDisabled)))
                .font(.title3)
                .foregroundStyle(Color(colors.textPrimary))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .frame(minHeight: 52)
                .background(Color(colors.layerSurfaceLow), in: Capsule())
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .focused($isNameFocused)
                .onSubmit { isNameFocused = false }
                .accessibilityLabel(String.TabGroups.GroupName)
                .accessibilityIdentifier("tabGroupEditor.name")
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(colors.layer2), in: RoundedRectangle(cornerRadius: 26))
    }

    private var colorCard: some View {
        LazyVGrid(columns: gridColumns, spacing: 24) {
            ForEach(Self.colorOptions) { option in
                Button {
                    color = option.color
                } label: {
                    Circle()
                        .fill(option.color.swiftUIColor)
                        .overlay {
                            if option.id == "default" {
                                Color(colors.layer1)
                                    .frame(width: 22, height: 44)
                                    .frame(width: 44, alignment: .trailing)
                                    .rotationEffect(.degrees(45))
                            }
                        }
                        .clipShape(Circle())
                        .frame(width: 44, height: 44)
                        .overlay { selectionRing(isSelected: color == option.color) }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(format: String.TabGroups.ColorAccessibility, option.localizedName))
                .accessibilityAddTraits(color == option.color ? .isSelected : [])
            }
        }
        .padding(16)
        .background(Color(colors.layer2), in: RoundedRectangle(cornerRadius: 26))
    }

    private var iconCard: some View {
        LazyVGrid(columns: gridColumns, spacing: 24) {
            ForEach(Self.symbolNames, id: \.self) { symbolName in
                Button {
                    icon = .sfSymbol(symbolName)
                } label: {
                    Image(systemName: TabGroupIcon.sfSymbol(symbolName).systemImageName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color(colors.iconSecondary))
                        .frame(width: 44, height: 44)
                        .background(Color(colors.layerSurfaceLow), in: Circle())
                        .overlay { selectionRing(isSelected: icon == .sfSymbol(symbolName)) }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(icon == .sfSymbol(symbolName) ? .isSelected : [])
            }
        }
        .padding(16)
        .background(Color(colors.layer2), in: RoundedRectangle(cornerRadius: 26))
    }

    @ViewBuilder
    private func selectionRing(isSelected: Bool) -> some View {
        if isSelected {
            Circle()
                .stroke(selectedColor, lineWidth: 2)
                .frame(width: 56, height: 56)
        }
    }
}

extension TabGroupIcon {
    var systemImageName: String {
        switch self {
        case .sfSymbol(let name):
            return UIImage(systemName: name) == nil ? "square.stack.fill" : name
        }
    }
}

extension CodableColor {
    var swiftUIColor: Color { Color(uiColor: uiColor) }
}

#if DEBUG
@MainActor
private func previewThemeManager(isDark: Bool = false) -> ThemeManager {
    let defaults = UserDefaults(suiteName: "TabGroupEditorPreview-\(UUID().uuidString)") ?? .standard
    let manager = DefaultThemeManager(userDefaults: defaults,
                                      sharedContainerIdentifier: "TabGroupEditorPreview",
                                      isNovaDesignOnClosure: { true })
    manager.setSystemTheme(isOn: false)
    manager.setManualTheme(to: isDark ? .dark : .light)
    return manager
}

#Preview("New group") {
    TabGroupEditorView(windowUUID: UUID(),
                       themeManager: previewThemeManager(),
                       onCancel: {},
                       onSave: { _, _, _ in })
}

#Preview("Edit group") {
    TabGroupEditorView(windowUUID: UUID(),
                       themeManager: previewThemeManager(),
                       name: "Houses",
                       icon: .sfSymbol("house.fill"),
                       color: CodableColor(red: 69 / 255, green: 95 / 255, blue: 231 / 255),
                       isEditing: true,
                       onCancel: {},
                       onSave: { _, _, _ in })
}

#Preview("Default color in dark mode") {
    TabGroupEditorView(windowUUID: UUID(),
                       themeManager: previewThemeManager(isDark: true),
                       name: "Houses",
                       isEditing: true,
                       onCancel: {},
                       onSave: { _, _, _ in })
        .preferredColorScheme(.dark)
}
#endif
