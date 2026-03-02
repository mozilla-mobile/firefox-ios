// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// A section displaying toolbar tint color swatches for the Appearance settings screen.
/// Users can tap a preset color or "Custom" to open the system color picker.
struct ToolbarTintSectionView: View {
    let theme: Theme?
    let themeManager: ThemeManager
    let cornerRadius: CGFloat
    @Binding var showColorPicker: Bool

    private struct UX {
        static let swatchSize: CGFloat = 40
        static let checkmarkSize: CGFloat = 18
        static let spacing: CGFloat = 12
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 16
        static let customIconSize: CGFloat = 20
    }

    private var selectedTint: AccentColor {
        themeManager.toolbarTintColor
    }

    private var isCustomSelected: Bool {
        if case .custom = selectedTint { return true }
        return false
    }

    var body: some View {
        GenericSectionView(
            theme: theme,
            title: .Settings.Appearance.ToolbarTint.SectionHeader,
            identifier: AccessibilityIdentifiers.Settings.Appearance.toolbarTintSectionTitle
        ) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: UX.spacing) {
                    ForEach(AccentColor.presets, id: \.persistenceValue) { accent in
                        swatchView(
                            color: Color(accent.swatchColor),
                            isSelected: selectedTint == accent,
                            accessibilityLabel: accent.persistenceValue
                        ) {
                            themeManager.setToolbarTintColor(accent)
                        }
                    }

                    if isCustomSelected {
                        customColorSwatch()
                    }

                    addButton()
                }
            }
            .padding(.horizontal, UX.horizontalPadding)
            .padding(.vertical, UX.verticalPadding)
            .modifier(SectionStyle(theme: theme, cornerRadius: cornerRadius))
        }
    }

    // MARK: - Swatch Views

    @ViewBuilder
    private func swatchView(
        color: Color,
        isSelected: Bool,
        accessibilityLabel: String,
        onTap: @escaping () -> Void
    ) -> some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: UX.swatchSize, height: UX.swatchSize)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: UX.checkmarkSize, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .onTapGesture { onTap() }
    }

    @ViewBuilder
    private func customColorSwatch() -> some View {
        let color: Color = {
            if case .custom(let hex) = selectedTint {
                return Color(UIColor(accentHex: hex) ?? .systemGray)
            }
            return Color.gray
        }()

        swatchView(
            color: color,
            isSelected: true,
            accessibilityLabel: "Custom color"
        ) {
            showColorPicker = true
        }
    }

    @ViewBuilder
    private func addButton() -> some View {
        ZStack {
            Circle()
                .fill(Color(UIColor.systemGray3))
                .frame(width: UX.swatchSize, height: UX.swatchSize)

            Image(systemName: "plus")
                .font(.system(size: UX.customIconSize, weight: .semibold))
                .foregroundColor(.white)
        }
        .accessibilityLabel("Add custom color")
        .accessibilityAddTraits(.isButton)
        .onTapGesture { showColorPicker = true }
    }
}

// MARK: - Toolbar Tint Color Picker Sheet

/// A SwiftUI wrapper around UIColorPickerViewController for toolbar tint.
struct ToolbarTintColorPickerSheet: UIViewControllerRepresentable {
    let themeManager: ThemeManager

    func makeUIViewController(context: Context) -> UIColorPickerViewController {
        let picker = UIColorPickerViewController()
        picker.supportsAlpha = false
        picker.delegate = context.coordinator

        if case .custom(let hex) = themeManager.toolbarTintColor {
            picker.selectedColor = UIColor(accentHex: hex) ?? .systemBlue
        } else {
            picker.selectedColor = themeManager.toolbarTintColor.swatchColor
        }
        return picker
    }

    func updateUIViewController(_ uiViewController: UIColorPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(themeManager: themeManager)
    }

    final class Coordinator: NSObject, UIColorPickerViewControllerDelegate {
        let themeManager: ThemeManager

        init(themeManager: ThemeManager) {
            self.themeManager = themeManager
        }

        func colorPickerViewController(
            _ viewController: UIColorPickerViewController,
            didSelect color: UIColor,
            continuously: Bool
        ) {
            guard !continuously else { return }
            let hex = color.accentHexString()
            themeManager.setToolbarTintColor(.custom(hex: hex))
        }
    }
}
