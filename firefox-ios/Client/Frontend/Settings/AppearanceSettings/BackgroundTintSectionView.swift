// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// A section displaying background tint color swatches for the Appearance settings screen.
/// Shows preset colors, user-added custom colors in a scrollable row,
/// and a pinned "+" button to add new custom colors via the system color picker.
struct BackgroundTintSectionView: View {
    let theme: Theme?
    let themeManager: ThemeManager
    let cornerRadius: CGFloat
    @Binding var showColorPicker: Bool
    @State private var hexToDelete: String?

    private struct UX {
        static let swatchSize: CGFloat = 40
        static let borderWidth: CGFloat = 3
        static let spacing: CGFloat = 12
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 16
        static let customIconSize: CGFloat = 20
    }

    private var selectedTint: AccentColor {
        themeManager.backgroundTintColor
    }

    var body: some View {
        GenericSectionView(
            theme: theme,
            title: .Settings.Appearance.BackgroundTint.SectionHeader,
            identifier: AccessibilityIdentifiers.Settings.Appearance.backgroundTintSectionTitle
        ) {
            sectionContent
                .padding(.horizontal, UX.horizontalPadding)
                .padding(.vertical, UX.verticalPadding)
                .modifier(SectionStyle(theme: theme, cornerRadius: cornerRadius))
        }
    }

    private var sectionContent: some View {
        HStack(spacing: UX.spacing) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: UX.spacing) {
                    presetSwatches
                    customSwatches
                }
            }
            addButton
        }
        .alert(
            "Delete custom color?",
            isPresented: Binding(
                get: { hexToDelete != nil },
                set: { if !$0 { hexToDelete = nil } }
            )
        ) {
            Button("Delete", role: .destructive) {
                if let hex = hexToDelete {
                    themeManager.removeCustomBackgroundTintColor(hex)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Preset Swatches

    private var presetSwatches: some View {
        ForEach(AccentColor.presets, id: \.persistenceValue) { accent in
            swatchView(
                color: Color(accent.swatchColor),
                isSelected: selectedTint == accent,
                accessibilityLabel: accent.persistenceValue
            ) {
                themeManager.setBackgroundTintColor(accent)
            }
        }
    }

    // MARK: - Custom Swatches

    private var customSwatches: some View {
        ForEach(themeManager.customBackgroundTintColors, id: \.self) { hex in
            let uiColor = UIColor(accentHex: hex) ?? .systemGray
            swatchView(
                color: Color(uiColor),
                isSelected: selectedTint == .custom(hex: hex),
                accessibilityLabel: "Custom \(hex)"
            ) {
                themeManager.setBackgroundTintColor(.custom(hex: hex))
            }
            .onLongPressGesture { hexToDelete = hex }
        }
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button { showColorPicker = true } label: {
            ZStack {
                Circle()
                    .fill(Color(theme?.colors.layer3 ?? .tertiarySystemBackground))
                    .frame(width: UX.swatchSize, height: UX.swatchSize)
                Image(systemName: "plus")
                    .font(.system(size: UX.customIconSize, weight: .medium))
                    .foregroundColor(Color(theme?.colors.iconPrimary ?? .label))
            }
        }
        .accessibilityLabel("Add custom color")
    }

    // MARK: - Swatch View

    @ViewBuilder
    private func swatchView(
        color: Color,
        isSelected: Bool,
        accessibilityLabel: String,
        onTap: @escaping () -> Void
    ) -> some View {
        Circle()
            .fill(color)
            .frame(width: UX.swatchSize, height: UX.swatchSize)
            .overlay(
                Circle()
                    .strokeBorder(Color.white, lineWidth: isSelected ? UX.borderWidth : 0)
            )
            .accessibilityLabel(accessibilityLabel)
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            .onTapGesture { onTap() }
    }
}

// MARK: - Background Tint Color Picker Sheet

/// A SwiftUI wrapper around UIColorPickerViewController for background tint.
struct BackgroundTintColorPickerSheet: UIViewControllerRepresentable {
    let themeManager: ThemeManager

    func makeUIViewController(context: Context) -> UIColorPickerViewController {
        let picker = UIColorPickerViewController()
        picker.supportsAlpha = false
        picker.delegate = context.coordinator

        if case .custom(let hex) = themeManager.backgroundTintColor {
            picker.selectedColor = UIColor(accentHex: hex) ?? .systemBlue
        } else {
            picker.selectedColor = themeManager.backgroundTintColor.swatchColor
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
            themeManager.addCustomBackgroundTintColor(hex)
        }
    }
}
