// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI

struct TabGroupEditorView: ThemeableView {
    struct IconOption: Identifiable {
        let id: String
        let localizedName: String

        var icon: TabGroupIcon { .sfSymbol(id) }
    }

    static let iconOptions = [
        IconOption(id: "rectangle.portrait.on.rectangle.portrait.angled.fill",
                   localizedName: String.TabGroups.IconNames.Default),
        IconOption(id: "list.bullet", localizedName: String.TabGroups.IconNames.List),
        IconOption(id: "flame.fill", localizedName: String.TabGroups.IconNames.Fire),
        IconOption(id: "star.fill", localizedName: String.TabGroups.IconNames.Star),
        IconOption(id: "bolt.fill", localizedName: String.TabGroups.IconNames.Bolt),
        IconOption(id: "heart.fill", localizedName: String.TabGroups.IconNames.Heart),
        IconOption(id: "sparkles", localizedName: String.TabGroups.IconNames.Sparkles),
        IconOption(id: "lightbulb.fill", localizedName: String.TabGroups.IconNames.Lightbulb),
        IconOption(id: "cloud.fill", localizedName: String.TabGroups.IconNames.Cloud),
        IconOption(id: "face.smiling.fill", localizedName: String.TabGroups.IconNames.Smiley),
        IconOption(id: "pawprint.fill", localizedName: String.TabGroups.IconNames.Paw),
        IconOption(id: "house.fill", localizedName: String.TabGroups.IconNames.House),
        IconOption(id: "briefcase.fill", localizedName: String.TabGroups.IconNames.Briefcase),
        IconOption(id: "graduationcap.fill", localizedName: String.TabGroups.IconNames.Education),
        IconOption(id: "book.closed.fill", localizedName: String.TabGroups.IconNames.Book),
        IconOption(id: "airplane", localizedName: String.TabGroups.IconNames.Plane),
        IconOption(id: "car.fill", localizedName: String.TabGroups.IconNames.Car),
        IconOption(id: "map.fill", localizedName: String.TabGroups.IconNames.Map),
        IconOption(id: "cart.fill", localizedName: String.TabGroups.IconNames.Cart),
        IconOption(id: "wallet.bifold.fill", localizedName: String.TabGroups.IconNames.Wallet),
        IconOption(id: "popcorn.fill", localizedName: String.TabGroups.IconNames.Popcorn),
        IconOption(id: "sportscourt.fill", localizedName: String.TabGroups.IconNames.Field),
        IconOption(id: "dumbbell.fill", localizedName: String.TabGroups.IconNames.Dumbbell),
        IconOption(id: "gamecontroller.fill", localizedName: String.TabGroups.IconNames.Controller),
        IconOption(id: "headphones", localizedName: String.TabGroups.IconNames.Headphones),
        IconOption(id: "paintpalette.fill", localizedName: String.TabGroups.IconNames.ArtPalette),
        IconOption(id: "photo.fill", localizedName: String.TabGroups.IconNames.Image),
        IconOption(id: "camera.macro", localizedName: String.TabGroups.IconNames.Flower),
        IconOption(id: "hammer.fill", localizedName: String.TabGroups.IconNames.Hammer),
        IconOption(id: "person.2.fill", localizedName: String.TabGroups.IconNames.People),
        IconOption(id: "bed.double.fill", localizedName: String.TabGroups.IconNames.Bed),
        IconOption(id: "gift.fill", localizedName: String.TabGroups.IconNames.Gift),
        IconOption(id: "party.popper.fill", localizedName: String.TabGroups.IconNames.PartyPopper),
        IconOption(id: "waveform.path.ecg", localizedName: String.TabGroups.IconNames.PulseLine),
        IconOption(id: "chart.bar.fill", localizedName: String.TabGroups.IconNames.Chart)
    ]

    static var defaultColor: CodableColor { TabGroupColorPalette.defaultColor }
    static var colorOptions: [TabGroupColorPalette.Option] { TabGroupColorPalette.options }

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
    private var selectedColor: Color { Color(TabGroupColorPalette.color(for: color, theme: theme)) }
    private var isDefaultColor: Bool { TabGroupColorPalette.isDefault(color) }
    private var gridColumns: [GridItem] { Array(repeating: GridItem(.flexible(), spacing: 24), count: 5) }

    private var saveIconColor: Color {
        guard hasValidName else { return Color(colors.iconDisabled) }
        guard isDefaultColor else { return Color(colors.iconOnColor) }
        return Color(colors.iconPrimary)
    }

    func save() {
        guard hasValidName else { return }
        onSave(name.trimmingCharacters(in: .whitespacesAndNewlines), icon, color)
    }

    private var header: some View {
        ZStack {
            Text(isEditing ? String.TabGroups.EditTabGroupTitle : String.TabGroups.NewTabGroupTitle)
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
                .accessibilityLabel(String.CancelString)
                Spacer()
                Button(action: save) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(saveIconColor)
                        .frame(width: 44, height: 44)
                        .background(hasValidName ? selectedColor : Color(colors.layer3), in: Circle())
                }
                .disabled(!hasValidName)
                .accessibilityLabel(String.TabGroups.Accessibility.DoneButton)
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
                .accessibilityLabel(String.TabGroups.Accessibility.GroupNameRequired)
                .accessibilityIdentifier("tabGroupEditor.name")
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(colors.layer2), in: RoundedRectangle(cornerRadius: 26))
    }

    private var colorCard: some View {
        let selectedID = TabGroupColorPalette.optionID(for: color)
        return LazyVGrid(columns: gridColumns, spacing: 24) {
            ForEach(Self.colorOptions) { option in
                Button {
                    color = option.color
                } label: {
                    Circle()
                        .fill(Color(TabGroupColorPalette.color(for: option.color, theme: theme)))
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
                        .overlay { selectionRing(isSelected: selectedID == option.id) }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.localizedName)
                .accessibilityIdentifier("tabGroupEditor.color.\(option.id)")
                .accessibilityAddTraits(selectedID == option.id ? .isSelected : [])
            }
        }
        .padding(16)
        .background(Color(colors.layer2), in: RoundedRectangle(cornerRadius: 26))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String.TabGroups.Accessibility.GroupColor)
    }

    private var iconCard: some View {
        LazyVGrid(columns: gridColumns, spacing: 24) {
            ForEach(Self.iconOptions) { option in
                Button {
                    icon = option.icon
                } label: {
                    Image(systemName: option.icon.systemImageName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color(colors.iconSecondary))
                        .frame(width: 44, height: 44)
                        .background(Color(colors.layerSurfaceLow), in: Circle())
                        .overlay { selectionRing(isSelected: icon == option.icon) }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.localizedName)
                .accessibilityIdentifier("tabGroupEditor.icon.\(option.id)")
                .accessibilityAddTraits(icon == option.icon ? .isSelected : [])
            }
        }
        .padding(16)
        .background(Color(colors.layer2), in: RoundedRectangle(cornerRadius: 26))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String.TabGroups.Accessibility.GroupIcon)
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

    func badgeImage(color: UIColor) -> UIImage {
        let presetID = CodableColor(uiColor: color).flatMap { TabGroupColorPalette.optionID(for: $0) }
        let isColoredPreset = presetID != nil && presetID != "default"
        let asset = UIImageAsset()
        let format = UIGraphicsImageRendererFormat.default()
        let scale = UITraitCollection(displayScale: format.scale)
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(traitsFrom: [UITraitCollection(userInterfaceStyle: style), scale])
            let image = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 20), format: format).image { _ in
                color.resolvedColor(with: traits).setFill()
                UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 20, height: 20)).fill()
                let symbol = UIImage(systemName: systemImageName,
                                     withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold))
                let glyphColor = isColoredPreset ? UIColor.white : Self.badgeGlyphColor(background: color, traits: traits)
                symbol?.withTintColor(glyphColor, renderingMode: .alwaysOriginal)
                    .draw(in: CGRect(x: 4, y: 4, width: 12, height: 12))
            }
            asset.register(image.withRenderingMode(.alwaysOriginal), with: traits)
        }
        return asset.image(with: UITraitCollection(traitsFrom: [.current, scale]))
    }

    private static func badgeGlyphColor(background: UIColor, traits: UITraitCollection) -> UIColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard background.resolvedColor(with: traits).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return .white
        }
        var backdrop: CGFloat = traits.userInterfaceStyle == .dark ? 0 : 1
        UIColor.systemBackground.resolvedColor(with: traits).getWhite(&backdrop, alpha: nil)
        let channels = [red, green, blue].map { component in
            let composited = min(max(component, 0), 1) * alpha + backdrop * (1 - alpha)
            return composited <= 0.04045 ? composited / 12.92 : pow((composited + 0.055) / 1.055, 2.4)
        }
        let luminance = 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]
        let blackContrast = (luminance + 0.05) / 0.05
        let whiteContrast = 1.05 / (luminance + 0.05)
        return blackContrast >= whiteContrast ? .black : .white
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
                       color: TabGroupEditorView.colorOptions.first { $0.id == "blue" }?.color
                        ?? TabGroupEditorView.defaultColor,
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
