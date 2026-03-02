// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// A section displaying accent color swatches for the Appearance settings screen.
/// Users can tap a preset color or "Custom" to open the system color picker.
struct AccentColorSectionView: View {
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

    private var selectedAccent: AccentColor {
        themeManager.accentColor
    }

    var body: some View {
        GenericSectionView(
            theme: theme,
            title: .Settings.Appearance.AccentColor.SectionHeader,
            identifier: AccessibilityIdentifiers.Settings.Appearance.accentColorSectionTitle
        ) {
            HStack(spacing: UX.spacing) {
                ForEach(AccentColor.presets, id: \.persistenceValue) { accent in
                    swatchView(
                        color: Color(accent.swatchColor),
                        isSelected: selectedAccent == accent,
                        accessibilityLabel: accent.persistenceValue
                    ) {
                        themeManager.setAccentColor(accent)
                    }
                }

                // Custom swatch
                customSwatchView()

                Spacer()
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
    private func customSwatchView() -> some View {
        let isCustomSelected: Bool = {
            if case .custom = selectedAccent { return true }
            return false
        }()

        let swatchColor: Color = {
            if case .custom(let hex) = selectedAccent {
                return Color(UIColor(accentHex: hex) ?? .systemGray)
            }
            return Color(UIColor.systemGray4)
        }()

        ZStack {
            Circle()
                .fill(swatchColor)
                .frame(width: UX.swatchSize, height: UX.swatchSize)

            if isCustomSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: UX.checkmarkSize, weight: .bold))
                    .foregroundColor(.white)
            } else {
                Image(systemName: "plus")
                    .font(.system(size: UX.customIconSize, weight: .medium))
                    .foregroundColor(Color(theme?.colors.iconPrimary ?? .label))
            }
        }
        .accessibilityLabel("Custom")
        .accessibilityAddTraits(isCustomSelected ? [.isButton, .isSelected] : .isButton)
        .onTapGesture { showColorPicker = true }
    }
}

// MARK: - Color Picker Sheet

/// A SwiftUI wrapper around UIColorPickerViewController presented as a sheet.
struct ColorPickerSheet: UIViewControllerRepresentable {
    let themeManager: ThemeManager

    func makeUIViewController(context: Context) -> UIColorPickerViewController {
        let picker = UIColorPickerViewController()
        picker.supportsAlpha = false
        picker.delegate = context.coordinator

        // Set initial color from current accent
        if case .custom(let hex) = themeManager.accentColor {
            picker.selectedColor = UIColor(accentHex: hex) ?? .systemBlue
        } else {
            picker.selectedColor = themeManager.accentColor.swatchColor
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
            themeManager.setAccentColor(.custom(hex: hex))
        }
    }
}
