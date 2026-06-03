// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import UIKit
import WebKit
import Common
import ToolbarKit

// Developer-only design tool for exploring Liquid Glass tinting on real elements, in ISOLATION — each element
// is its own instance, so tinting one never touches the rest of the app. Built for design (Nova) to answer
// "what does a glass tint look like on a toolbar button, over real content, in light/dark?".
// Opened from a hidden Debug setting (Settings → tap version 5× → Debug), gated to developer / beta channels.

/// Hidden Debug setting (developer / beta only) that opens the Nova design-tools catalog as a sheet.
class NovaDesignToolsSetting: HiddenSetting {
    override var title: NSAttributedString? {
        guard let theme else { return nil }
        return NSAttributedString(
            string: "Nova design tools (Liquid Glass)",
            attributes: [.foregroundColor: theme.colors.textPrimary]
        )
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let catalog = UIHostingController(rootView: NovaCatalogView())
        catalog.modalPresentationStyle = .formSheet
        navigationController?.present(catalog, animated: true)
    }
}

/// Parses `#RRGGBB` / `#RRGGBBAA` and renders hex strings. Pure, callable from any context.
enum NovaColor {
    nonisolated static func parse(_ hex: String) -> UIColor? {
        var string = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if string.hasPrefix("#") { string.removeFirst() }
        guard let value = UInt64(string, radix: 16) else { return nil }
        let red, green, blue, alpha: CGFloat
        switch string.count {
        case 6:
            red = CGFloat((value & 0xFF0000) >> 16) / 255
            green = CGFloat((value & 0x00FF00) >> 8) / 255
            blue = CGFloat(value & 0x0000FF) / 255
            alpha = 1
        case 8:
            red = CGFloat((value & 0xFF000000) >> 24) / 255
            green = CGFloat((value & 0x00FF0000) >> 16) / 255
            blue = CGFloat((value & 0x0000FF00) >> 8) / 255
            alpha = CGFloat(value & 0x000000FF) / 255
        default:
            return nil
        }
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    nonisolated static func hexString(_ color: UIColor) -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard color.getRed(&r, green: &g, blue: &b, alpha: &a) else { return "—" }
        let ri = Int(round(r * 255)), gi = Int(round(g * 255)), bi = Int(round(b * 255))
        return String(format: "#%02X%02X%02X · %d%%", ri, gi, bi, Int(round(a * 100)))
    }
}

// MARK: - Elements

enum NovaElement: String, CaseIterable, Identifiable {
    case browserToolbar = "Browser toolbar"
    case glassBar = "Glass bar"
    case glassButton = "Glass button"
    case glassCard = "Glass card"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .browserToolbar: return "Real address bar + nav buttons (bottom chrome)"
        case .glassBar: return "A bare glass surface — purest tint test"
        case .glassButton: return "A single circular glass button"
        case .glassCard: return "A glass panel with content"
        }
    }

    var symbol: String {
        switch self {
        case .browserToolbar: return "menubar.dock.rectangle"
        case .glassBar: return "capsule"
        case .glassButton: return "circle.circle"
        case .glassCard: return "rectangle.portrait"
        }
    }

    /// The Nova token whose value each element starts its tint from. The toolbar starts from `layer1`
    /// (its real glass-tint driver) so it looks like the shipping chrome; the abstract glass surfaces start
    /// from `actionPrimary` so the tint is clearly visible.
    var defaultTintToken: String {
        switch self {
        case .browserToolbar: return "layer1"
        default: return "actionPrimary"
        }
    }

    /// The toolbar previews best on dark (matching the usual chrome); the rest default to light.
    var defaultAppearance: ThemeType {
        self == .browserToolbar ? .dark : .light
    }
}

enum NovaBackdrop: String, CaseIterable, Identifiable {
    case webpage = "Webpage"
    case photo = "Photo"
    case gradient = "Nova gradient"
    case solid = "Solid"

    var id: String { rawValue }
}

struct ElementConfig {
    let appearance: ThemeType
    let backdrop: NovaBackdrop
    let tint: UIColor
    let isInteractive: Bool
    let solidColor: UIColor
    /// Forces the icon / text (foreground) color on the element; nil keeps the Nova default for the appearance.
    let contentColor: UIColor?
    /// Stops for the selected Nova gradient backdrop (resolved for the current appearance).
    let gradientColors: [UIColor]
    /// Glass style: clear is much more transparent (media), regular is the frosted default.
    let clearStyle: Bool
}

/// Nova token map for an appearance, with the optional content-color override folded into the icon/text tokens.
@MainActor
func novaTokenOverrides(for config: ElementConfig) -> [String: UIColor] {
    var overrides = NovaPalette.tokens(for: config.appearance)
    if let content = config.contentColor {
        overrides["iconPrimary"] = content
        overrides["iconSecondary"] = content
        overrides["textPrimary"] = content
        overrides["textSecondary"] = content
    }
    return overrides
}

@MainActor
func novaTheme(overrides: [String: UIColor], appearance: ThemeType) -> Theme {
    let base: Theme = (appearance == .dark) ? DarkTheme() : LightTheme()
    return NovaTheme(base: base, overrides: overrides)
}

// MARK: - Catalog

struct NovaCatalogView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink(destination: NovaTokensReferenceView()) {
                        Label("Nova color tokens", systemImage: "swatchpalette")
                    }
                } header: {
                    Text(verbatim: "Reference")
                }

                Section {
                    ForEach(NovaElement.allCases) { element in
                        NavigationLink(destination: NovaElementStageView(element: element)) {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(verbatim: element.rawValue)
                                    Text(verbatim: element.subtitle)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } icon: {
                                Image(systemName: element.symbol)
                            }
                        }
                    }
                } footer: {
                    Text(verbatim: "Each element is isolated — tinting one never affects the others or the live app. Glass is real on iOS 26+; older iOS shows a flat fallback.")
                }
            }
            .navigationTitle("Nova elements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Nova token reference

struct NovaTokenSpec: Identifiable {
    let name: String
    let usage: String
    let light: String
    let dark: String
    let priv: String
    var id: String { name }
}

struct NovaTokenSection: Identifiable {
    let title: String
    let tokens: [NovaTokenSpec]
    var id: String { title }
}

struct NovaSwatchSpec: Identifiable {
    let name: String
    let hex: String
    var id: String { name }
}

/// The named Nova color tokens (light / dark / private), transcribed from the Nova spec. Read-only reference.
enum NovaTokenCatalog {
    static let sections: [NovaTokenSection] = [
        NovaTokenSection(title: "Layer", tokens: [
            NovaTokenSpec(name: "layer1", usage: "Page background", light: "#F7F6FB", dark: "#171519", priv: "#180E30"),
            NovaTokenSpec(name: "layer2", usage: "Active tab", light: "#FFFFFF", dark: "#3F3E42", priv: "#3E315F"),
            NovaTokenSpec(name: "layer3", usage: "Badge inactive", light: "#EFEDF2", dark: "#3F3E42", priv: "#3E315F"),
            NovaTokenSpec(name: "layer4", usage: "Segmented control", light: "#E3E2E7", dark: "#252428", priv: "#281D44"),
            NovaTokenSpec(name: "layerSurfaceLow", usage: "Toolbar background", light: "#EFEDF2", dark: "#171519", priv: "#180E30"),
            NovaTokenSpec(name: "layerSurfaceMedium", usage: "Cards, list items", light: "#FFFFFF", dark: "#252428", priv: "#281D44"),
            NovaTokenSpec(name: "layerSurfaceMediumAlpha", usage: "Surface @ 40%", light: "#FFFFFF", dark: "#252428", priv: "#281D44"),
            NovaTokenSpec(name: "layerAccentSubtle", usage: "Info banners, panels", light: "#E2DCF2", dark: "#3E315F", priv: "#3E2976"),
            NovaTokenSpec(name: "layerInverse", usage: "Toast", light: "#252428", dark: "#B7B6BA", priv: "#B7B6BA"),
            NovaTokenSpec(name: "layerWarning", usage: "Warning container", light: "#FAE2A7", dark: "#5F3100", priv: "#5F3100"),
            NovaTokenSpec(name: "layerSuccess", usage: "Success container", light: "#B8EED9", dark: "#004933", priv: "#004933"),
            NovaTokenSpec(name: "layerCritical", usage: "Critical container", light: "#FFEBE6", dark: "#69172D", priv: "#69172D"),
            NovaTokenSpec(name: "layerInformation", usage: "Information container", light: "#BAE5FF", dark: "#23327B", priv: "#23327B"),
            NovaTokenSpec(name: "layerSepia", usage: "Sepia background", light: "#FFF9E2", dark: "#FFF9E2", priv: "#FFF9E2"),
            NovaTokenSpec(name: "layerAutofillText", usage: "Autofill text in address bar", light: "#B0A3D2", dark: "#B0A3D2", priv: "#B0A3D2"),
            NovaTokenSpec(name: "layerSelectedText", usage: "Selected text in address bar", light: "#A6A4A9", dark: "#817F84", priv: "#817F84")
        ]),
        NovaTokenSection(title: "Action", tokens: [
            NovaTokenSpec(name: "actionPrimary", usage: "Buttons, toasts, switches", light: "#764EDD", dark: "#B393FF", priv: "#B393FF"),
            NovaTokenSpec(name: "actionPrimaryHover", usage: "Pressed", light: "#5939A8", dark: "#956EFF", priv: "#956EFF"),
            NovaTokenSpec(name: "actionPrimaryDisabled", usage: "Disabled @ 40%", light: "#764EDD", dark: "#B393FF", priv: "#B393FF"),
            NovaTokenSpec(name: "actionSecondary", usage: "Secondary button", light: "#E3E2E7", dark: "#515054", priv: "#515054"),
            NovaTokenSpec(name: "actionSecondaryHover", usage: "Pressed", light: "#D6D5DA", dark: "#3F3E42", priv: "#3F3E42"),
            NovaTokenSpec(name: "actionSecondaryDisabled", usage: "Disabled", light: "#E3E2E7", dark: "#515054", priv: "#515054"),
            NovaTokenSpec(name: "actionWarning", usage: "Warning controls", light: "#B26100", dark: "#F0A000", priv: "#F0A000"),
            NovaTokenSpec(name: "actionSuccess", usage: "Success controls", light: "#008865", dark: "#2DC79E", priv: "#2DC79E"),
            NovaTokenSpec(name: "actionCritical", usage: "Critical controls", light: "#C52D4F", dark: "#FF8090", priv: "#FF8090"),
            NovaTokenSpec(name: "actionInformation", usage: "Information controls", light: "#455FE7", dark: "#70ABFF", priv: "#70ABFF"),
            NovaTokenSpec(name: "actionFormKnob", usage: "Switch knob", light: "#FFFFFF", dark: "#FFFFFF", priv: "#FFFFFF"),
            NovaTokenSpec(name: "actionFormSurfaceOff", usage: "Switch background", light: "#E3E2E7", dark: "#515054", priv: "#515054"),
            NovaTokenSpec(name: "actionTabActive", usage: "iPad active tab", light: "#FFFFFF", dark: "#252428", priv: "#281D44"),
            NovaTokenSpec(name: "actionTabInactive", usage: "iPad inactive tab", light: "#EFEDF2", dark: "#171519", priv: "#121114"),
            NovaTokenSpec(name: "actionCloseButton", usage: "Close button", light: "#FFFFFF", dark: "#252428", priv: "#281D44")
        ]),
        NovaTokenSection(title: "Text", tokens: [
            NovaTokenSpec(name: "textPrimary", usage: "Primary text", light: "#180E30", dark: "#F2F0F8", priv: "#F2F0F8"),
            NovaTokenSpec(name: "textSecondary", usage: "Secondary text @ 70%", light: "#180E30", dark: "#F2F0F8", priv: "#F2F0F8"),
            NovaTokenSpec(name: "textDisabled", usage: "Disabled / placeholder @ 40%", light: "#180E30", dark: "#F2F0F8", priv: "#F2F0F8"),
            NovaTokenSpec(name: "textAccent", usage: "Links", light: "#764EDD", dark: "#B393FF", priv: "#B393FF"),
            NovaTokenSpec(name: "textCritical", usage: "Critical text", light: "#C52D4F", dark: "#FF8090", priv: "#FF8090"),
            NovaTokenSpec(name: "textInverted", usage: "Inverted text", light: "#F2F0F8", dark: "#180E30", priv: "#180E30"),
            NovaTokenSpec(name: "textInvertedDisabled", usage: "Inverted disabled", light: "#F2F0F8", dark: "#180E30", priv: "#180E30"),
            NovaTokenSpec(name: "textOnDark", usage: "On dark backgrounds", light: "#F2F0F8", dark: "#F2F0F8", priv: "#F2F0F8"),
            NovaTokenSpec(name: "textOnLight", usage: "On light backgrounds", light: "#180E30", dark: "#180E30", priv: "#180E30"),
            NovaTokenSpec(name: "textOnColorPrimary", usage: "On color", light: "#F2F0F8", dark: "#F2F0F8", priv: "#F2F0F8"),
            NovaTokenSpec(name: "textToast", usage: "Toast link", light: "#B393FF", dark: "#3E2976", priv: "#3E2976")
        ]),
        NovaTokenSection(title: "Icon", tokens: [
            NovaTokenSpec(name: "iconPrimary", usage: "Primary icon", light: "#180E30", dark: "#F2F0F8", priv: "#F2F0F8"),
            NovaTokenSpec(name: "iconSecondary", usage: "Secondary icon @ 70%", light: "#180E30", dark: "#F2F0F8", priv: "#F2F0F8"),
            NovaTokenSpec(name: "iconDisabled", usage: "Disabled icon @ 40%", light: "#180E30", dark: "#F2F0F8", priv: "#F2F0F8"),
            NovaTokenSpec(name: "iconAccent", usage: "Accent icon", light: "#764EDD", dark: "#B393FF", priv: "#B393FF"),
            NovaTokenSpec(name: "iconCritical", usage: "Critical icon", light: "#C52D4F", dark: "#FF8090", priv: "#FF8090"),
            NovaTokenSpec(name: "iconInverted", usage: "Inverted icon", light: "#F2F0F8", dark: "#180E30", priv: "#180E30"),
            NovaTokenSpec(name: "iconOnColor", usage: "Icon on color / dark", light: "#F2F0F8", dark: "#F2F0F8", priv: "#F2F0F8"),
            NovaTokenSpec(name: "iconOnColorDisabled", usage: "On color disabled @ 40%", light: "#F2F0F8", dark: "#F2F0F8", priv: "#F2F0F8"),
            NovaTokenSpec(name: "iconPrivate", usage: "Private mode icon", light: "#764EDD", dark: "#764EDD", priv: "#764EDD"),
            NovaTokenSpec(name: "iconPrivateOutline", usage: "Private icon outline", light: "#764EDD", dark: "#281D44", priv: "#281D44")
        ]),
        NovaTokenSection(title: "Border", tokens: [
            NovaTokenSpec(name: "borderPrimary", usage: "Primary border", light: "#E3E2E7", dark: "#3F3E42", priv: "#3E315F"),
            NovaTokenSpec(name: "borderStrong", usage: "Stronger border", light: "#D6D5DA", dark: "#515054", priv: "#584A7D"),
            NovaTokenSpec(name: "borderOnColor", usage: "On color / dark", light: "#E3E2E7", dark: "#E3E2E7", priv: "#E3E2E7"),
            NovaTokenSpec(name: "borderInverted", usage: "Inverted border", light: "#3F3E42", dark: "#E3E2E7", priv: "#E3E2E7"),
            NovaTokenSpec(name: "borderRadioButtonDefault", usage: "Radio button outline", light: "#A6A4A9", dark: "#817F84", priv: "#817F84")
        ]),
        NovaTokenSection(title: "Shadow", tokens: [
            NovaTokenSpec(name: "shadowSubtle", usage: "Subtle @ 10%", light: "#3F3E42", dark: "#171519", priv: "#171519"),
            NovaTokenSpec(name: "shadowDefault", usage: "Default @ 12%", light: "#3F3E42", dark: "#171519", priv: "#171519"),
            NovaTokenSpec(name: "shadowStrong", usage: "Strong @ 16%", light: "#3F3E42", dark: "#171519", priv: "#171519")
        ]),
        NovaTokenSection(title: "Gradients", tokens: [
            NovaTokenSpec(name: "gradientStop1", usage: "Old CFR background", light: "#5939A8", dark: "#5939A8", priv: "#5939A8"),
            NovaTokenSpec(name: "gradientStop2", usage: "Old CFR background", light: "#764EDD", dark: "#764EDD", priv: "#764EDD"),
            NovaTokenSpec(name: "gradientAccentStop1", usage: "Progress bar", light: "#FF8F5D", dark: "#B393FF", priv: "#B393FF"),
            NovaTokenSpec(name: "gradientAccentStop2", usage: "Progress bar", light: "#B393FF", dark: "#764EDD", priv: "#764EDD"),
            NovaTokenSpec(name: "gradientAccentSubtleStop1", usage: "Accent subtle", light: "#E5D6FF", dark: "#180E30", priv: "#180E30"),
            NovaTokenSpec(name: "gradientAccentSubtleStop2", usage: "Accent subtle", light: "#FFD4B7", dark: "#711D08", priv: "#180E30"),
            NovaTokenSpec(name: "gradientAiSubtleStop1", usage: "AI subtle (deprecated)", light: "#F7F6FB", dark: "#817F84", priv: "#817F84"),
            NovaTokenSpec(name: "gradientAiSubtleStop2", usage: "AI subtle (deprecated)", light: "#CDB7FF", dark: "#956EFF", priv: "#956EFF"),
            NovaTokenSpec(name: "gradientAiSubtleStop3", usage: "AI subtle (deprecated)", light: "#FFD4B7", dark: "#FF8F5D", priv: "#FF8F5D"),
            NovaTokenSpec(name: "gradientAiStrongStop1", usage: "AI strong", light: "#764EDD", dark: "#764EDD", priv: "#764EDD"),
            NovaTokenSpec(name: "gradientAiStrongStop2", usage: "AI strong", light: "#D851BC", dark: "#D851BC", priv: "#D851BC"),
            NovaTokenSpec(name: "gradientAiStrongStop3", usage: "AI strong", light: "#FF8F5D", dark: "#FF8F5D", priv: "#FF8F5D"),
            NovaTokenSpec(name: "gradientTabBorderStop1", usage: "Tab tray tab border", light: "#B393FF", dark: "#B393FF", priv: "#B393FF"),
            NovaTokenSpec(name: "gradientTabBorderStop2", usage: "Tab tray tab border", light: "#764EDD", dark: "#764EDD", priv: "#764EDD"),
            NovaTokenSpec(name: "gradientPrivacyStop1", usage: "Privacy elements", light: "#B561EB", dark: "#B561EB", priv: "#B561EB"),
            NovaTokenSpec(name: "gradientPrivacyStop2", usage: "Privacy elements", light: "#180E30", dark: "#E1AFFF", priv: "#E1AFFF"),
            NovaTokenSpec(name: "gradientPrivacyMaskStop1", usage: "Private mode icon mask", light: "#FFFFFF", dark: "#FFFFFF", priv: "#FFFFFF"),
            NovaTokenSpec(name: "gradientPrivacyMaskStop2", usage: "Private mode icon mask", light: "#CDB7FF", dark: "#CDB7FF", priv: "#CDB7FF")
        ])
    ]

    /// Favicon icon-accent ramps — single value across light / dark / private.
    static let iconAccents: [NovaSwatchSpec] = [
        NovaSwatchSpec(name: "iconAccentGreen1", hex: "#B8EED9"), NovaSwatchSpec(name: "iconAccentGreen2", hex: "#7FDDBD"),
        NovaSwatchSpec(name: "iconAccentGreen3", hex: "#2DC79E"), NovaSwatchSpec(name: "iconAccentGreen4", hex: "#00AB81"),
        NovaSwatchSpec(name: "iconAccentGreen5", hex: "#008865"), NovaSwatchSpec(name: "iconAccentGreen6", hex: "#06674B"),
        NovaSwatchSpec(name: "iconAccentGreen7", hex: "#004933"),
        NovaSwatchSpec(name: "iconAccentCyan1", hex: "#BAE9F3"), NovaSwatchSpec(name: "iconAccentCyan2", hex: "#85D6E9"),
        NovaSwatchSpec(name: "iconAccentCyan3", hex: "#41BDDA"), NovaSwatchSpec(name: "iconAccentCyan4", hex: "#00A1C7"),
        NovaSwatchSpec(name: "iconAccentCyan5", hex: "#0A809F"), NovaSwatchSpec(name: "iconAccentCyan6", hex: "#066077"),
        NovaSwatchSpec(name: "iconAccentCyan7", hex: "#034554"),
        NovaSwatchSpec(name: "iconAccentBlue1", hex: "#BAE5FF"), NovaSwatchSpec(name: "iconAccentBlue2", hex: "#95CBFE"),
        NovaSwatchSpec(name: "iconAccentBlue3", hex: "#70ABFF"), NovaSwatchSpec(name: "iconAccentBlue4", hex: "#5583FF"),
        NovaSwatchSpec(name: "iconAccentBlue5", hex: "#455FE7"), NovaSwatchSpec(name: "iconAccentBlue6", hex: "#3246B0"),
        NovaSwatchSpec(name: "iconAccentBlue7", hex: "#23327B"),
        NovaSwatchSpec(name: "iconAccentYellow1", hex: "#FAE2A7"), NovaSwatchSpec(name: "iconAccentYellow2", hex: "#F6C465"),
        NovaSwatchSpec(name: "iconAccentYellow3", hex: "#F0A000"), NovaSwatchSpec(name: "iconAccentYellow4", hex: "#D7800E"),
        NovaSwatchSpec(name: "iconAccentYellow5", hex: "#B26100"), NovaSwatchSpec(name: "iconAccentYellow6", hex: "#854800"),
        NovaSwatchSpec(name: "iconAccentYellow7", hex: "#5F3100"),
        NovaSwatchSpec(name: "iconAccentOrange1", hex: "#FFD4B7"), NovaSwatchSpec(name: "iconAccentOrange2", hex: "#FEB48C"),
        NovaSwatchSpec(name: "iconAccentOrange3", hex: "#FF8F5D"), NovaSwatchSpec(name: "iconAccentOrange4", hex: "#F5672B"),
        NovaSwatchSpec(name: "iconAccentOrange5", hex: "#D24300"), NovaSwatchSpec(name: "iconAccentOrange6", hex: "#A02D02"),
        NovaSwatchSpec(name: "iconAccentOrange7", hex: "#711D08"),
        NovaSwatchSpec(name: "iconAccentRed1", hex: "#FFD0D7"), NovaSwatchSpec(name: "iconAccentRed2", hex: "#FFA9B5"),
        NovaSwatchSpec(name: "iconAccentRed3", hex: "#FF8090"), NovaSwatchSpec(name: "iconAccentRed4", hex: "#EB526B"),
        NovaSwatchSpec(name: "iconAccentRed5", hex: "#C52D4F"), NovaSwatchSpec(name: "iconAccentRed6", hex: "#961E3D"),
        NovaSwatchSpec(name: "iconAccentRed7", hex: "#69172D")
    ]
}

struct NovaTokensReferenceView: View {
    var body: some View {
        List {
            ForEach(NovaTokenCatalog.sections) { section in
                Section {
                    ForEach(section.tokens) { token in
                        NovaTokenRow(token: token)
                    }
                } header: {
                    Text(verbatim: section.title)
                }
            }

            Section {
                ForEach(NovaTokenCatalog.iconAccents) { swatch in
                    NovaSwatchRow(swatch: swatch)
                }
            } header: {
                Text(verbatim: "Icon accents")
            } footer: {
                Text(verbatim: "Favicon accent ramps — a single value across light / dark / private.")
            }
        }
        .navigationTitle("Nova color tokens")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NovaSwatchRow: View {
    let swatch: NovaSwatchSpec

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(uiColor: NovaColor.parse(swatch.hex) ?? .clear))
                .frame(width: 24, height: 24)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.3)))
            Text(verbatim: swatch.name)
                .font(.system(.footnote, design: .monospaced))
            Spacer()
            Text(verbatim: swatch.hex)
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.secondary)
        }
    }
}

struct NovaTokenRow: View {
    let token: NovaTokenSpec

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: token.name)
                .font(.system(.subheadline, design: .monospaced))
            Text(verbatim: token.usage)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 16) {
                swatch("Light", token.light)
                swatch("Dark", token.dark)
                swatch("Private", token.priv)
            }
        }
        .padding(.vertical, 4)
    }

    private func swatch(_ label: String, _ hex: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(uiColor: NovaColor.parse(hex) ?? .clear))
                .frame(width: 22, height: 22)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.3)))
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(verbatim: hex)
                    .font(.system(.caption2, design: .monospaced))
            }
        }
    }
}

// MARK: - Element stage

struct NovaElementStageView: View {
    let element: NovaElement

    static let customTintKey = "Custom…"
    /// Nova tokens offered as glass tints (the surfaces / accents that read well as a tint), plus Custom.
    static let tintTokenOptions = [
        "layer1", "layer2", "layer3", "layer4", "layerSurfaceLow", "layerSurfaceMedium",
        "layerAccentPrivateNonOpaque", "layerInformation", "layerSuccess", "layerWarning", "layerCritical",
        "actionPrimary", "actionSecondary", "actionInformation", "actionSuccess", "actionWarning", "actionCritical"
    ]

    @State private var appearance: ThemeType = .light
    @State private var backdrop: NovaBackdrop = .webpage
    @State private var solidColor = Color(uiColor: .systemGray3)
    @State private var gradientName = NovaGradients.all.first?.name ?? ""
    @State private var tintToken: String
    @State private var customColor = Color(red: 0.0, green: 0.45, blue: 0.95)
    @State private var strength: Double = 0.5
    @State private var interactive = true
    @State private var clearGlass = false
    @State private var contentColorEnabled = false
    @State private var contentColor = Color.white
    @State private var didCopy = false

    init(element: NovaElement) {
        self.element = element
        _appearance = State(initialValue: element.defaultAppearance)
        _tintToken = State(initialValue: element.defaultTintToken)
    }

    private func tokenColor(_ key: String) -> UIColor {
        NovaPalette.tokens(for: appearance)[key] ?? .systemPurple
    }

    private var baseTint: UIColor {
        tintToken == Self.customTintKey ? UIColor(customColor) : tokenColor(tintToken)
    }

    private var resolvedTint: UIColor {
        baseTint.withAlphaComponent(CGFloat(strength))
    }

    private var gradientColors: [UIColor] {
        (NovaGradients.all.first { $0.name == gradientName } ?? NovaGradients.all[0]).colors(for: appearance)
    }

    private var config: ElementConfig {
        ElementConfig(appearance: appearance, backdrop: backdrop, tint: resolvedTint,
                      isInteractive: interactive, solidColor: UIColor(solidColor),
                      contentColor: contentColorEnabled ? UIColor(contentColor) : nil,
                      gradientColors: gradientColors, clearStyle: clearGlass)
    }

    private func gradientSwatch(_ spec: NovaGradientSpec) -> some View {
        let isSelected = backdrop == .gradient && gradientName == spec.name
        let colors = spec.colors(for: appearance).map { Color(uiColor: $0) }
        return Button {
            gradientName = spec.name
            backdrop = .gradient
        } label: {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 60, height: 38)
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.3),
                                lineWidth: isSelected ? 3 : 1))
                Text(verbatim: spec.name.replacingOccurrences(of: "gradient", with: ""))
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .foregroundColor(.secondary)
                    .frame(width: 60)
            }
        }
        .buttonStyle(.plain)
    }

    private func configSummary() -> String {
        var lines = [
            "Nova glass config",
            "element: \(element.rawValue)",
            "appearance: \(appearance == .dark ? "dark" : "light")",
            "backdrop: \(backdrop.rawValue)" + (backdrop == .gradient ? " — \(gradientName)" : ""),
            "tint: \(tintToken == Self.customTintKey ? "custom" : tintToken)",
            "resolved: \(NovaColor.hexString(resolvedTint))",
            "style: \(clearGlass ? "clear" : "regular")",
            "interactive: \(interactive ? "yes" : "no")"
        ]
        if contentColorEnabled {
            lines.append("content: \(NovaColor.hexString(UIColor(contentColor)))")
        }
        return lines.joined(separator: "\n")
    }

    private func novaColorRow(_ title: String, _ selection: Binding<Color>) -> some View {
        NavigationLink {
            NovaColorChooserView(selection: selection, appearance: appearance, title: title)
        } label: {
            HStack {
                Text(verbatim: title)
                Spacer()
                Circle()
                    .fill(selection.wrappedValue)
                    .frame(width: 26, height: 26)
                    .overlay(Circle().stroke(Color.secondary.opacity(0.3), lineWidth: 1))
            }
        }
    }

    var body: some View {
        Form {
            previewSection
            contextSection
            glassTintSection
            contentColorSection
        }
        .navigationTitle(element.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder private var previewSection: some View {
        Section {
            ElementStageRepresentable(element: element, config: config)
                .frame(height: 340)
                .listRowInsets(EdgeInsets())
        } footer: {
            Text(verbatim: "Drag isn't needed — tweak below and watch this element only. Switch backdrops to see the tint over different content.")
        }
    }

    @ViewBuilder private var contextSection: some View {
        Section {
            Picker("Appearance", selection: $appearance) {
                Text(verbatim: "Light").tag(ThemeType.light)
                Text(verbatim: "Dark").tag(ThemeType.dark)
            }
            .pickerStyle(.segmented)
            Picker("Backdrop", selection: $backdrop) {
                ForEach(NovaBackdrop.allCases) { Text($0.rawValue).tag($0) }
            }
            if backdrop == .solid {
                novaColorRow("Solid color", $solidColor)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(verbatim: "Nova gradients")
                    .font(.caption)
                    .foregroundColor(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(NovaGradients.all) { spec in
                            gradientSwatch(spec)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        } header: {
            Text(verbatim: "Context")
        } footer: {
            Text(verbatim: "Tap a gradient to use it as the backdrop behind the glass (a glass tint itself is a single color, not a gradient).")
        }
    }

    @ViewBuilder private var glassTintSection: some View {
        Section {
            tintLinkRow
            HStack {
                Text(verbatim: "Resolved")
                Spacer()
                Text(verbatim: NovaColor.hexString(resolvedTint))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)
            }
            VStack(alignment: .leading) {
                Text(verbatim: "Tint strength: \(String(format: "%.2f", strength))")
                Slider(value: $strength, in: 0...1)
            }
            Picker("Style", selection: $clearGlass) {
                Text(verbatim: "Regular").tag(false)
                Text(verbatim: "Clear").tag(true)
            }
            .pickerStyle(.segmented)
            Toggle("Interactive", isOn: $interactive)
            resetButton
            copyButton
        } header: {
            Text(verbatim: "Glass tint")
        } footer: {
            Text(verbatim: "Pick a Nova token as the tint (appearance-aware), or Custom for any color. Strength is the alpha of the wash — the real toolbar uses layer1 at ~50%.")
        }
    }

    @ViewBuilder private var tintLinkRow: some View {
        NavigationLink {
            NovaTintPickerView(tintToken: $tintToken, customColor: $customColor, appearance: appearance)
        } label: {
            HStack {
                Text(verbatim: "Tint")
                Spacer()
                Text(verbatim: tintToken == Self.customTintKey ? "Custom" : tintToken)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundColor(.secondary)
                Circle()
                    .fill(Color(uiColor: baseTint))
                    .frame(width: 26, height: 26)
                    .overlay(Circle().stroke(Color.secondary.opacity(0.3), lineWidth: 1))
            }
        }
    }

    private var resetButton: some View {
        Button("Reset to Nova default") {
            tintToken = element.defaultTintToken
            strength = 0.5
            clearGlass = false
            contentColorEnabled = false
        }
    }

    private var copyButton: some View {
        Button(didCopy ? "Copied ✓" : "Copy config") {
            UIPasteboard.general.string = configSummary()
            didCopy = true
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                didCopy = false
            }
        }
    }

    @ViewBuilder private var contentColorSection: some View {
        Section {
            Toggle("Override content color", isOn: $contentColorEnabled)
            if contentColorEnabled {
                novaColorRow("Content color", $contentColor)
            }
        } header: {
            Text(verbatim: "Content (icon / text)")
        } footer: {
            Text(verbatim: "Forces the icon / label color on this element so you can check glyph contrast against the glass tint. Off = the Nova default for the appearance.")
        }
    }
}

/// The tint chooser opened from the color circle: Nova tokens first, then a custom color picker.
struct NovaTintPickerView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case nova = "Nova"
        case custom = "Custom"
        var id: String { rawValue }
    }

    @Binding var tintToken: String
    @Binding var customColor: Color
    let appearance: ThemeType

    @State private var mode: Mode
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 76), spacing: 12)]

    init(tintToken: Binding<String>, customColor: Binding<Color>, appearance: ThemeType) {
        self._tintToken = tintToken
        self._customColor = customColor
        self.appearance = appearance
        _mode = State(initialValue: tintToken.wrappedValue == NovaElementStageView.customTintKey ? .custom : .nova)
    }

    var body: some View {
        Form {
            Picker("Mode", selection: $mode) {
                ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            if mode == .nova {
                novaSection
            } else {
                customSection
            }
        }
        .navigationTitle("Glass tint")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder private var novaSection: some View {
        Section {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(NovaElementStageView.tintTokenOptions, id: \.self) { key in
                    tokenButton(key)
                }
            }
            .padding(.vertical, 8)
        } footer: {
            Text(verbatim: "Nova tokens shown for the \(appearance == .dark ? "dark" : "light") appearance.")
        }
    }

    private func tokenButton(_ key: String) -> some View {
        Button {
            tintToken = key
            dismiss()
        } label: {
            VStack(spacing: 4) {
                Circle()
                    .fill(Color(uiColor: NovaPalette.tokens(for: appearance)[key] ?? .clear))
                    .frame(width: 46, height: 46)
                    .overlay(Circle().stroke(tintToken == key ? Color.accentColor : Color.secondary.opacity(0.3),
                                             lineWidth: tintToken == key ? 3 : 1))
                Text(verbatim: key)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var customSection: some View {
        Section {
            ColorPicker("Custom color", selection: Binding(
                get: { customColor },
                set: { customColor = $0; tintToken = NovaElementStageView.customTintKey }
            ), supportsOpacity: false)
        }
    }
}

/// A generic color chooser with Nova tokens as the first tab and a custom picker as the second — used by every
/// color control in the tool (content color, solid backdrop, etc.).
struct NovaColorChooserView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case nova = "Nova"
        case custom = "Custom"
        var id: String { rawValue }
    }

    @Binding var selection: Color
    let appearance: ThemeType
    let title: String

    @State private var mode: Mode = .nova
    @Environment(\.dismiss) private var dismiss
    private let columns = [GridItem(.adaptive(minimum: 76), spacing: 12)]

    var body: some View {
        Form {
            Picker("Mode", selection: $mode) {
                ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            if mode == .nova {
                novaSection
            } else {
                customSection
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder private var novaSection: some View {
        Section {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(NovaElementStageView.tintTokenOptions, id: \.self) { key in
                    tokenButton(key)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func tokenButton(_ key: String) -> some View {
        Button {
            if let color = NovaPalette.tokens(for: appearance)[key] {
                selection = Color(uiColor: color)
            }
            dismiss()
        } label: {
            VStack(spacing: 4) {
                Circle()
                    .fill(Color(uiColor: NovaPalette.tokens(for: appearance)[key] ?? .clear))
                    .frame(width: 46, height: 46)
                    .overlay(Circle().stroke(Color.secondary.opacity(0.3), lineWidth: 1))
                Text(verbatim: key)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var customSection: some View {
        Section {
            ColorPicker("Custom color", selection: $selection, supportsOpacity: false)
        }
    }
}

struct NovaGradientSpec: Identifiable {
    let name: String
    let light: [String]
    let dark: [String]
    var id: String { name }
    func colors(for type: ThemeType) -> [UIColor] {
        (type == .dark ? dark : light).compactMap { NovaColor.parse($0) }
    }
}

/// Nova gradient stops (from the spec) offered as backdrops, since a glass tint is a single color, not a gradient.
enum NovaGradients {
    static let all: [NovaGradientSpec] = [
        NovaGradientSpec(name: "gradientAiStrong", light: ["#764EDD", "#D851BC", "#FF8F5D"], dark: ["#764EDD", "#D851BC", "#FF8F5D"]),
        NovaGradientSpec(name: "gradientAccent", light: ["#FF8F5D", "#B393FF"], dark: ["#B393FF", "#764EDD"]),
        NovaGradientSpec(name: "gradientAccentSubtle", light: ["#E5D6FF", "#FFD4B7"], dark: ["#180E30", "#711D08"]),
        NovaGradientSpec(name: "gradientAiSubtle", light: ["#F7F6FB", "#CDB7FF", "#FFD4B7"], dark: ["#817F84", "#956EFF", "#FF8F5D"]),
        NovaGradientSpec(name: "gradientTabBorder", light: ["#B393FF", "#764EDD"], dark: ["#B393FF", "#764EDD"]),
        NovaGradientSpec(name: "gradientPrivacy", light: ["#B561EB", "#180E30"], dark: ["#B561EB", "#E1AFFF"]),
        NovaGradientSpec(name: "gradientPrivacyMask", light: ["#FFFFFF", "#CDB7FF"], dark: ["#FFFFFF", "#CDB7FF"]),
        NovaGradientSpec(name: "gradient", light: ["#5939A8", "#764EDD"], dark: ["#5939A8", "#764EDD"])
    ]
}

struct ElementStageRepresentable: UIViewRepresentable {
    let element: NovaElement
    let config: ElementConfig

    func makeUIView(context: Context) -> ElementStageUIView { ElementStageUIView() }
    func updateUIView(_ uiView: ElementStageUIView, context: Context) { uiView.render(element: element, config: config) }
}

/// Renders one isolated element over a configurable backdrop. Rebuilds its content on each `render` so config
/// changes (tint, interactive, appearance, backdrop) always take effect cleanly.
final class ElementStageUIView: UIView, BrowserNavigationToolbarDelegate {
    private let backdrop = NovaBackdropView()
    private var hostedElement: UIView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backdrop)
        NSLayoutConstraint.activate([
            backdrop.topAnchor.constraint(equalTo: topAnchor),
            backdrop.bottomAnchor.constraint(equalTo: bottomAnchor),
            backdrop.leadingAnchor.constraint(equalTo: leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    func render(element kind: NovaElement, config: ElementConfig) {
        backdrop.apply(config.backdrop, solidColor: config.solidColor, gradientColors: config.gradientColors)
        hostedElement?.removeFromSuperview()
        let overrides = novaTokenOverrides(for: config)
        let theme = novaTheme(overrides: overrides, appearance: config.appearance)
        let view = build(kind, config: config, theme: theme, overrides: overrides)
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        hostedElement = view

        if kind == .browserToolbar {
            // Docked edge-to-edge at the bottom, like the real chrome.
            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(equalTo: leadingAnchor),
                view.trailingAnchor.constraint(equalTo: trailingAnchor),
                view.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                view.centerXAnchor.constraint(equalTo: centerXAnchor),
                view.centerYAnchor.constraint(equalTo: centerYAnchor),
                view.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),
                view.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16)
            ])
        }
    }

    private func build(_ element: NovaElement, config: ElementConfig, theme: Theme, overrides: [String: UIColor]) -> UIView {
        switch element {
        case .browserToolbar: return buildBrowserToolbar(config: config, theme: theme)
        case .glassBar: return buildGlassBar(config: config)
        case .glassButton: return buildGlassButton(config: config, theme: theme)
        case .glassCard: return buildGlassCard(config: config, theme: theme)
        }
    }

    /// The real bottom chrome: the address bar stacked on the navigation toolbar, inside a glass container.
    /// The tint is the glass *wash* (not an opaque repaint); the bars are themed with the real Nova colors and
    /// kept translucent so the glass shows through — matching the shipping toolbar.
    private func buildBrowserToolbar(config: ElementConfig, theme: Theme) -> UIView {
        let effectView = UIVisualEffectView(effect: glassEffect(config))
        effectView.clipsToBounds = true

        let address = BrowserAddressToolbar()
        let location = LocationViewConfiguration(
            searchEngineImageViewA11yId: "nova.searchEngine",
            searchEngineImageViewA11yLabel: "Search engine",
            lockIconButtonA11yId: "nova.lock",
            lockIconButtonA11yLabel: "Site security",
            urlTextFieldPlaceholder: "Search or enter address",
            urlTextFieldA11yId: "nova.url",
            searchEngineImage: nil,
            lockIconImageName: StandardImageIdentifiers.Small.shieldCheckmarkFill,
            lockIconNeedsTheming: true,
            safeListedURLImageName: nil,
            url: URL(string: "https://www.mozilla.org/firefox/"),
            droppableUrl: nil,
            searchTerm: nil,
            isEditing: false,
            didStartTyping: false,
            shouldShowKeyboard: false,
            shouldSelectSearchTerm: false
        )
        let addressConfig = AddressToolbarConfiguration(
            locationViewConfiguration: location,
            navigationActions: [],
            leadingPageActions: [toolbarElement(StandardImageIdentifiers.Medium.share, "Share", hasCustomColor: true)],
            trailingPageActions: [
                toolbarElement(StandardImageIdentifiers.Medium.readerView, "Reader view", hasCustomColor: true),
                toolbarElement(StandardImageIdentifiers.Medium.arrowClockwise, "Reload", hasCustomColor: true)
            ],
            browserActions: [],
            borderConfiguration: AddressToolbarBorderConfiguration(a11yIdentifier: "nova.addressBorder", borderPosition: nil),
            uxConfiguration: .default(backgroundAlpha: 0.0, shouldBlur: true),
            shouldAnimate: false
        )
        address.configureNonInteractive(config: addressConfig, leadingSpace: 12, trailingSpace: 12)
        address.applyTheme(theme: theme)
        address.translatesAutoresizingMaskIntoConstraints = false

        let nav = BrowserNavigationToolbar()
        nav.translatesAutoresizingMaskIntoConstraints = false
        nav.configure(
            config: NavigationToolbarConfiguration(actions: toolbarElements, shouldDisplayBorder: false, isTranslucencyEnabled: true),
            toolbarDelegate: self
        )
        nav.applyTheme(theme: theme)

        let stack = UIStackView(arrangedSubviews: [address, nav])
        stack.axis = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        effectView.contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            address.heightAnchor.constraint(equalToConstant: 48),
            nav.heightAnchor.constraint(equalToConstant: 48),
            stack.topAnchor.constraint(equalTo: effectView.contentView.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: effectView.contentView.bottomAnchor, constant: -8),
            stack.leadingAnchor.constraint(equalTo: effectView.contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: effectView.contentView.trailingAnchor)
        ])
        return effectView
    }

    private func glassEffect(_ config: ElementConfig) -> UIVisualEffect? {
        guard #available(iOS 26, *) else { return UIBlurEffect(style: .systemThinMaterial) }
        let glass = UIGlassEffect(style: config.clearStyle ? .clear : .regular)
        glass.tintColor = config.tint
        glass.isInteractive = config.isInteractive
        return glass
    }

    private func buildGlassBar(config: ElementConfig) -> UIView {
        let effectView = UIVisualEffectView(effect: glassEffect(config))
        effectView.clipsToBounds = true
        effectView.layer.cornerRadius = 32
        effectView.layer.cornerCurve = .continuous
        NSLayoutConstraint.activate([
            effectView.heightAnchor.constraint(equalToConstant: 64),
            effectView.widthAnchor.constraint(equalToConstant: 320)
        ])
        return effectView
    }

    private func buildGlassButton(config: ElementConfig, theme: Theme) -> UIView {
        let effectView = UIVisualEffectView(effect: glassEffect(config))
        effectView.clipsToBounds = true
        effectView.layer.cornerRadius = 32
        let icon = UIImageView(image: UIImage(systemName: "plus"))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.tintColor = theme.colors.iconPrimary
        icon.contentMode = .center
        effectView.contentView.addSubview(icon)
        NSLayoutConstraint.activate([
            effectView.heightAnchor.constraint(equalToConstant: 64),
            effectView.widthAnchor.constraint(equalToConstant: 64),
            icon.centerXAnchor.constraint(equalTo: effectView.contentView.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: effectView.contentView.centerYAnchor)
        ])
        return effectView
    }

    private func buildGlassCard(config: ElementConfig, theme: Theme) -> UIView {
        let effectView = UIVisualEffectView(effect: glassEffect(config))
        effectView.clipsToBounds = true
        effectView.layer.cornerRadius = 20
        effectView.layer.cornerCurve = .continuous

        let title = UILabel()
        title.text = "Quick answer"
        title.font = .preferredFont(forTextStyle: .headline)
        title.textColor = theme.colors.textPrimary
        let body = UILabel()
        body.text = "Glass panel rendered over the backdrop — tint reads against the content behind it."
        body.numberOfLines = 0
        body.font = .preferredFont(forTextStyle: .subheadline)
        body.textColor = theme.colors.textSecondary

        let stack = UIStackView(arrangedSubviews: [title, body])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        effectView.contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            effectView.widthAnchor.constraint(equalToConstant: 300),
            stack.topAnchor.constraint(equalTo: effectView.contentView.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: effectView.contentView.bottomAnchor, constant: -16),
            stack.leadingAnchor.constraint(equalTo: effectView.contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: effectView.contentView.trailingAnchor, constant: -16)
        ])
        return effectView
    }

    /// The real iPhone bottom navigation set: back, forward, new tab, menu, tabs.
    private var toolbarElements: [ToolbarElement] {
        return [
            toolbarElement(StandardImageIdentifiers.Large.chevronLeft, "Back"),
            toolbarElement(StandardImageIdentifiers.Large.chevronRight, "Forward"),
            toolbarElement(StandardImageIdentifiers.Large.plus, "New tab"),
            toolbarElement(StandardImageIdentifiers.Large.moreHorizontalRound, "Menu"),
            toolbarElement(StandardImageIdentifiers.Large.tab, "Tabs")
        ]
    }

    private func toolbarElement(_ icon: String, _ label: String, hasCustomColor: Bool = false) -> ToolbarElement {
        ToolbarElement(
            iconName: icon,
            isEnabled: true,
            hasCustomColor: hasCustomColor,
            a11yLabel: label,
            a11yHint: nil,
            a11yId: "nova.toolbar.\(label.lowercased())",
            hasLongPressAction: false,
            onSelected: { _ in }
        )
    }

    func configureContextualHint(for button: UIButton, with contextualHintType: String) {}
}

/// Backdrop the glass sits over: a live web page (mozilla.org), a real placeholder photo, or a custom solid.
final class NovaBackdropView: UIView {
    private lazy var webView: WKWebView = {
        let view = WKWebView(frame: bounds)
        view.isUserInteractionEnabled = true
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.isOpaque = true
        // Leave room at the bottom so page content can scroll out from behind the docked toolbar.
        view.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 120, right: 0)
        return view
    }()

    private lazy var imageView: UIImageView = {
        let view = UIImageView(frame: bounds)
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.backgroundColor = .secondarySystemBackground
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return view
    }()

    private let gradientLayer = CAGradientLayer()
    private var didLoadWeb = false
    private var didLoadImage = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.isHidden = true
        layer.addSublayer(gradientLayer)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        layer.addSublayer(gradientLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    func apply(_ backdrop: NovaBackdrop, solidColor: UIColor, gradientColors: [UIColor]) {
        switch backdrop {
        case .webpage:
            ensureWeb()
            webView.isHidden = false
            imageView.isHidden = true
            gradientLayer.isHidden = true
            backgroundColor = .systemBackground
        case .photo:
            ensureImage()
            imageView.isHidden = false
            webView.isHidden = true
            gradientLayer.isHidden = true
            backgroundColor = .secondarySystemBackground
        case .gradient:
            webView.isHidden = true
            imageView.isHidden = true
            gradientLayer.isHidden = false
            gradientLayer.colors = gradientColors.map { $0.cgColor }
            backgroundColor = .black
        case .solid:
            webView.isHidden = true
            imageView.isHidden = true
            gradientLayer.isHidden = true
            backgroundColor = solidColor
        }
    }

    private func ensureWeb() {
        if webView.superview == nil {
            webView.frame = bounds
            addSubview(webView)
        }
        guard !didLoadWeb, let url = URL(string: "https://www.mozilla.org") else { return }
        didLoadWeb = true
        webView.load(URLRequest(url: url))
    }

    private func ensureImage() {
        if imageView.superview == nil {
            imageView.frame = bounds
            addSubview(imageView)
        }
        guard !didLoadImage, let url = URL(string: "https://picsum.photos/800/1200") else { return }
        didLoadImage = true
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async { self?.imageView.image = image }
        }.resume()
    }
}

// MARK: - Nova theme (per-element, isolated — applied only to the instance being previewed)

/// A `Theme` whose colors come from a runtime token map overlaid on a base theme.
struct NovaTheme: Theme {
    let type: ThemeType
    let colors: ThemeColourPalette

    init(base: Theme, overrides: [String: UIColor]) {
        self.type = base.type
        self.colors = NovaColourPalette(base: base.colors, overrides: overrides)
    }
}

/// Resolves each semantic token to a runtime override (keyed by the token's property name) and falls back to
/// the Acorn `base` palette when no override is provided. `Gradient` tokens always pass through to `base`.
struct NovaColourPalette: ThemeColourPalette {
    let base: ThemeColourPalette
    let overrides: [String: UIColor]

    private func color(_ key: String, _ fallback: UIColor) -> UIColor {
        return overrides[key] ?? fallback
    }

    // MARK: - Layers
    var layer1: UIColor { color("layer1", base.layer1) }
    var layer2: UIColor { color("layer2", base.layer2) }
    var layer3: UIColor { color("layer3", base.layer3) }
    var layer4: UIColor { color("layer4", base.layer4) }
    var layer5: UIColor { color("layer5", base.layer5) }
    var layer5Hover: UIColor { color("layer5Hover", base.layer5Hover) }
    var layerScrim: UIColor { color("layerScrim", base.layerScrim) }
    var layerGradient: Common.Gradient { base.layerGradient }
    var layerGradientOverlay: Common.Gradient { base.layerGradientOverlay }
    var layerAccentNonOpaque: UIColor { color("layerAccentNonOpaque", base.layerAccentNonOpaque) }
    var layerAccentPrivate: UIColor { color("layerAccentPrivate", base.layerAccentPrivate) }
    var layerAccentPrivateNonOpaque: UIColor { color("layerAccentPrivateNonOpaque", base.layerAccentPrivateNonOpaque) }
    var layerSepia: UIColor { color("layerSepia", base.layerSepia) }
    var layerHomepage: Common.Gradient { base.layerHomepage }
    var layerInformation: UIColor { color("layerInformation", base.layerInformation) }
    var layerSuccess: UIColor { color("layerSuccess", base.layerSuccess) }
    var layerWarning: UIColor { color("layerWarning", base.layerWarning) }
    var layerCritical: UIColor { color("layerCritical", base.layerCritical) }
    var layerCriticalSubdued: UIColor { color("layerCriticalSubdued", base.layerCriticalSubdued) }
    var layerSelectedText: UIColor { color("layerSelectedText", base.layerSelectedText) }
    var layerAutofillText: UIColor { color("layerAutofillText", base.layerAutofillText) }
    var layerEmphasis: UIColor { color("layerEmphasis", base.layerEmphasis) }
    var layerGradientURL: Common.Gradient { base.layerGradientURL }
    var layerSurfaceLow: UIColor { color("layerSurfaceLow", base.layerSurfaceLow) }
    var layerSurfaceMedium: UIColor { color("layerSurfaceMedium", base.layerSurfaceMedium) }
    var layerSurfaceMediumAlpha: UIColor { color("layerSurfaceMediumAlpha", base.layerSurfaceMediumAlpha) }
    var layerSurfaceMediumAlt: UIColor { color("layerSurfaceMediumAlt", base.layerSurfaceMediumAlt) }
    var layerGradientSummary: Common.Gradient { base.layerGradientSummary }

    // MARK: - Actions
    var actionPrimary: UIColor { color("actionPrimary", base.actionPrimary) }
    var actionPrimaryHover: UIColor { color("actionPrimaryHover", base.actionPrimaryHover) }
    var actionPrimaryDisabled: UIColor { color("actionPrimaryDisabled", base.actionPrimaryDisabled) }
    var actionSecondary: UIColor { color("actionSecondary", base.actionSecondary) }
    var actionSecondaryDisabled: UIColor { color("actionSecondaryDisabled", base.actionSecondaryDisabled) }
    var actionSecondaryHover: UIColor { color("actionSecondaryHover", base.actionSecondaryHover) }
    var formSurfaceOff: UIColor { color("formSurfaceOff", base.formSurfaceOff) }
    var formKnob: UIColor { color("formKnob", base.formKnob) }
    var indicatorActive: UIColor { color("indicatorActive", base.indicatorActive) }
    var indicatorInactive: UIColor { color("indicatorInactive", base.indicatorInactive) }
    var actionSuccess: UIColor { color("actionSuccess", base.actionSuccess) }
    var actionWarning: UIColor { color("actionWarning", base.actionWarning) }
    var actionCritical: UIColor { color("actionCritical", base.actionCritical) }
    var actionInformation: UIColor { color("actionInformation", base.actionInformation) }
    var actionTabActive: UIColor { color("actionTabActive", base.actionTabActive) }
    var actionTabInactive: UIColor { color("actionTabInactive", base.actionTabInactive) }
    var actionCloseButton: UIColor { color("actionCloseButton", base.actionCloseButton) }

    // MARK: - Text
    var textPrimary: UIColor { color("textPrimary", base.textPrimary) }
    var textSecondary: UIColor { color("textSecondary", base.textSecondary) }
    var textDisabled: UIColor { color("textDisabled", base.textDisabled) }
    var textCritical: UIColor { color("textCritical", base.textCritical) }
    var textAccent: UIColor { color("textAccent", base.textAccent) }
    var textOnDark: UIColor { color("textOnDark", base.textOnDark) }
    var textOnLight: UIColor { color("textOnLight", base.textOnLight) }
    var textInverted: UIColor { color("textInverted", base.textInverted) }
    var textInvertedDisabled: UIColor { color("textInvertedDisabled", base.textInvertedDisabled) }

    // MARK: - Icons
    var iconPrimary: UIColor { color("iconPrimary", base.iconPrimary) }
    var iconSecondary: UIColor { color("iconSecondary", base.iconSecondary) }
    var iconDisabled: UIColor { color("iconDisabled", base.iconDisabled) }
    var iconAccent: UIColor { color("iconAccent", base.iconAccent) }
    var iconOnColor: UIColor { color("iconOnColor", base.iconOnColor) }
    var iconCritical: UIColor { color("iconCritical", base.iconCritical) }
    var iconSpinner: UIColor { color("iconSpinner", base.iconSpinner) }
    var iconAccentViolet: UIColor { color("iconAccentViolet", base.iconAccentViolet) }
    var iconAccentBlue: UIColor { color("iconAccentBlue", base.iconAccentBlue) }
    var iconAccentPink: UIColor { color("iconAccentPink", base.iconAccentPink) }
    var iconAccentGreen: UIColor { color("iconAccentGreen", base.iconAccentGreen) }
    var iconAccentYellow: UIColor { color("iconAccentYellow", base.iconAccentYellow) }
    var iconRatingNeutral: UIColor { color("iconRatingNeutral", base.iconRatingNeutral) }

    // MARK: - Border
    var borderPrimary: UIColor { color("borderPrimary", base.borderPrimary) }
    var borderSecondary: UIColor { color("borderSecondary", base.borderSecondary) }
    var borderAccent: UIColor { color("borderAccent", base.borderAccent) }
    var borderAccentNonOpaque: UIColor { color("borderAccentNonOpaque", base.borderAccentNonOpaque) }
    var borderAccentPrivate: UIColor { color("borderAccentPrivate", base.borderAccentPrivate) }
    var borderInverted: UIColor { color("borderInverted", base.borderInverted) }
    var borderToolbarDivider: UIColor { color("borderToolbarDivider", base.borderToolbarDivider) }

    // MARK: - Shadow
    var shadowSubtle: UIColor { color("shadowSubtle", base.shadowSubtle) }
    var shadowDefault: UIColor { color("shadowDefault", base.shadowDefault) }
    var shadowStrong: UIColor { color("shadowStrong", base.shadowStrong) }
    var shadowBorder: UIColor { color("shadowBorder", base.shadowBorder) }

    // MARK: - Gradient stops
    var gradientOnboardingStop1: UIColor { color("gradientOnboardingStop1", base.gradientOnboardingStop1) }
    var gradientOnboardingStop2: UIColor { color("gradientOnboardingStop2", base.gradientOnboardingStop2) }
    var gradientOnboardingStop3: UIColor { color("gradientOnboardingStop3", base.gradientOnboardingStop3) }
    var gradientOnboardingStop4: UIColor { color("gradientOnboardingStop4", base.gradientOnboardingStop4) }
    var gradientAIStrongStop1: UIColor { color("gradientAIStrongStop1", base.gradientAIStrongStop1) }
    var gradientAIStrongStop2: UIColor { color("gradientAIStrongStop2", base.gradientAIStrongStop2) }
    var gradientAIStrongStop3: UIColor { color("gradientAIStrongStop3", base.gradientAIStrongStop3) }
}

// MARK: - Built-in Nova tokens

/// Nova token values imported from Figma, keyed by the app's semantic `ThemeColourPalette` names.
/// Light values are authoritative (from the Nova variables file); dark comes from the Nova spec table.
enum NovaPalette {
    static func tokens(for type: ThemeType) -> [String: UIColor] {
        let hexMap: [String: String]
        switch type {
        case .light: hexMap = light
        case .dark, .nightMode, .privateMode: hexMap = dark
        }
        return hexMap.compactMapValues { NovaColor.parse($0) }
    }

    static let light: [String: String] = [
        "layer1": "#f7f6fb", "layer2": "#ffffff", "layer3": "#efedf2", "layer4": "#e3e2e7",
        "layerSurfaceLow": "#efedf2", "layerSurfaceMedium": "#ffffff", "layerSurfaceMediumAlpha": "#ffffffcc",
        "layerAccentPrivateNonOpaque": "#e2dcf2", "layerWarning": "#fae2a7", "layerSuccess": "#b8eed9",
        "layerCritical": "#ffd0d7", "layerInformation": "#bae5ff", "layerSepia": "#fff9e2",
        "layerAutofillText": "#b0a3d2", "layerSelectedText": "#a6a4a9",
        "actionPrimary": "#764edd", "actionPrimaryHover": "#5939a8", "actionPrimaryDisabled": "#764edd66",
        "actionSecondary": "#e3e2e7", "actionSecondaryHover": "#d6d5da", "actionSecondaryDisabled": "#e3e2e766",
        "actionWarning": "#b26100", "actionSuccess": "#008865", "actionCritical": "#c52d4f",
        "actionInformation": "#455fe7", "formKnob": "#ffffff", "formSurfaceOff": "#e3e2e7",
        "actionTabActive": "#ffffff", "actionTabInactive": "#efedf2", "actionCloseButton": "#ffffff",
        "textPrimary": "#180e30", "textSecondary": "#14092bb2", "textDisabled": "#14092b66",
        "textAccent": "#764edd", "textCritical": "#c52d4f", "textInverted": "#f2f0f8",
        "textInvertedDisabled": "#f2f0f8", "textOnDark": "#f2f0f8", "textOnLight": "#180e30",
        "iconPrimary": "#180e30", "iconSecondary": "#14092bb2", "iconDisabled": "#14092b66",
        "iconAccent": "#764edd", "iconCritical": "#c52d4f", "iconOnColor": "#f2f0f8",
        "borderPrimary": "#e3e2e7", "borderSecondary": "#d6d5da", "borderInverted": "#3f3e42",
        "shadowSubtle": "#3f3e421a", "shadowDefault": "#3f3e421f", "shadowStrong": "#3f3e4229",
        "gradientAIStrongStop1": "#764edd", "gradientAIStrongStop2": "#d851bc", "gradientAIStrongStop3": "#ff8f5d"
    ]

    static let dark: [String: String] = [
        "layer1": "#171519", "layer2": "#3f3e42", "layer3": "#3f3e42", "layer4": "#252428",
        "layerSurfaceLow": "#171519", "layerSurfaceMedium": "#252428", "layerSurfaceMediumAlpha": "#252428cc",
        "layerAccentPrivateNonOpaque": "#3e315f", "layerWarning": "#5f3100", "layerSuccess": "#004933",
        "layerCritical": "#69172d", "layerInformation": "#23327b", "layerSepia": "#fff9e2",
        "layerAutofillText": "#b0a3d28c", "layerSelectedText": "#817f84cc",
        "actionPrimary": "#b393ff", "actionPrimaryHover": "#956eff", "actionPrimaryDisabled": "#b393ff66",
        "actionSecondary": "#515054", "actionSecondaryHover": "#3f3e42", "actionSecondaryDisabled": "#51505480",
        "actionWarning": "#f0a000", "actionSuccess": "#2dc79e", "actionCritical": "#ff8090",
        "actionInformation": "#70abff", "formKnob": "#ffffff", "formSurfaceOff": "#515054",
        "actionTabActive": "#252428", "actionTabInactive": "#171519", "actionCloseButton": "#252428",
        "textPrimary": "#f2f0f8", "textSecondary": "#f2f0f8b3", "textDisabled": "#f2f0f866",
        "textAccent": "#b393ff", "textCritical": "#ff8090", "textInverted": "#180e30",
        "textInvertedDisabled": "#180e3066", "textOnDark": "#f2f0f8", "textOnLight": "#180e30",
        "iconPrimary": "#f2f0f8", "iconSecondary": "#f2f0f8b3", "iconDisabled": "#f2f0f866",
        "iconAccent": "#b393ff", "iconCritical": "#ff8090", "iconOnColor": "#f2f0f8",
        "borderPrimary": "#3f3e42", "borderSecondary": "#515054", "borderInverted": "#e3e2e7",
        "shadowSubtle": "#1715191a", "shadowDefault": "#1715191f", "shadowStrong": "#17151929",
        "gradientAIStrongStop1": "#764edd", "gradientAIStrongStop2": "#d851bc", "gradientAIStrongStop3": "#ff8f5d"
    ]
}
